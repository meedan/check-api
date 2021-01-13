class Assignment < ActiveRecord::Base
  include CheckElasticSearch

  attr_accessor :propagate_in_foreground

  belongs_to :assigned, polymorphic: true
  belongs_to :user
  belongs_to :assigner, :class_name => 'User'

  before_validation :set_annotation_assigned_type, :set_assigner
  before_update { raise ActiveRecord::ReadOnlyRecord }
  after_create :send_email_notification_on_create, :increase_assignments_count, :propagate_assignments, :apply_rules_and_actions
  after_destroy :send_email_notification_on_destroy, :decrease_assignments_count, :propagate_unassignments
  after_commit :update_elasticsearch_assignment

  validate :assigned_to_user_from_the_same_team, if: proc { |a| a.user.present? }

  has_paper_trail on: [:create, :destroy], if: proc { |a| User.current.present? && a.assigned_type == 'Annotation' }, class_name: 'Version'

  def version_metadata(_changes)
    meta = { user_name: self.user&.name }
    annotation = self.assigned.load || self.assigned
    meta[:type] = annotation.annotation_type
    meta[:type] = 'media' if meta[:type] =~ /status/
    meta[:title] = annotation.to_s
    meta.to_json
  end

  def team
    assigned = self.assigned_type.constantize.where(id: self.assigned_id).last
    assigned.nil? ? nil : assigned.team
  end

  protected

  def send_email_notification(action)
    return if User.current.nil?
    author = User.current
    assigned = self.assigned
    user = self.user
    return if [author, assigned, user].select{ |x| x.nil? }.any?
    type = assigned.is_a?(Annotation) ? assigned.annotation_type : self.assigned_type.downcase
    AssignmentMailer.delay_for(1.second).notify("#{action}_#{type}", author, user.email, assigned, self.message)
  end

  def change_assignments_count(value)
    assigned = self.assigned
    assigned.update_column(:assignments_count, assigned.assignments_count + value) if assigned.respond_to?(:assignments_count)
  end

  def propagate_assignments_or_unassignments(event)
    assignment = YAML::dump(self)
    self.propagate_in_foreground ? Assignment.propagate_assignments(assignment, nil, event) : Assignment.delay_for(1.second).propagate_assignments(assignment, User.current&.id, event)
  end

  def self.propagate_assignments(assignment, _requestor_id, event)
    assignment = YAML::load(assignment)
    return if assignment.assigned.nil?
    to_create = []
    to_delete = []
    objs = assignment.assigned.propagate_assignment_to(assignment.user)
    objs.each do |obj|
      klass = obj.parent_class_name
      existing = Assignment.where(user_id: assignment.user_id, assigned_type: klass, assigned_id: obj.id).last
      if existing.nil? && event == :assign
        a = Assignment.new
        a.user_id = assignment.user_id
        a.assigned_id = obj.id
        a.assigned_type = klass
        a.propagate_in_foreground = true
        to_create << a
      elsif existing.present? && event == :unassign
        to_delete << existing.id
      end
    end
    Assignment.import(to_create, on_duplicate_key_ignore: true)
    Assignment.delete(to_delete)
  end

  private

  def assigned_to_user_from_the_same_team
    if self.assigned.present?
      team = self.team
      unless team.nil?
        member = TeamUser.where(team_id: team.id, user_id: self.user_id, status: 'member').last
        errors.add(:base, I18n.t(:error_user_is_not_a_team_member, default: 'Sorry, you can only assign to members of this team')) if member.nil?
      end
    end
  end

  def send_email_notification_on_create
    self.send_email_notification(:assign)
  end

  def send_email_notification_on_destroy
    self.send_email_notification(:unassign)
  end

  def set_annotation_assigned_type
    self.assigned_type = 'Annotation' if self.is_annotation?
  end

  def increase_assignments_count
    self.change_assignments_count(1)
  end

  def decrease_assignments_count
    self.change_assignments_count(-1)
  end

  def propagate_assignments
    self.propagate_assignments_or_unassignments(:assign)
  end

  def propagate_unassignments
    self.propagate_assignments_or_unassignments(:unassign)
  end

  def set_assigner
    self.assigner = User.current if self.assigner.nil? && !User.current.nil?
  end

  def apply_rules_and_actions
    return unless self.assigned_type == 'Annotation'
    target = self.assigned&.annotated
    if target.is_a?(ProjectMedia)
      rule_ids = target.team.get_rules_that_match_condition { |condition, _value| condition == 'item_is_assigned_to_user' }
      target.team.apply_rules_and_actions(target, rule_ids)
    end
  end

  def update_elasticsearch_assignment
    if ['Annotation', 'Dynamic'].include?(self.assigned_type) && self.assigned.annotation_type == 'verification_status'
      pm = self.assigned.annotated
      uids = Assignment.where(assigned_type: self.assigned_type, assigned_id: self.assigned_id).map(&:user_id)
      options = { keys: ['assigned_user_ids'], data: { 'assigned_user_ids' => uids }, obj: pm }
      ElasticSearchWorker.perform_in(1.second, YAML::dump(pm), YAML::dump(options), 'update_doc')
    end
  end
end
