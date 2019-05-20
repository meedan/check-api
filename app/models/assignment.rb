class Assignment < ActiveRecord::Base
  attr_accessor :propagate_in_foreground

  belongs_to :assigned, polymorphic: true
  belongs_to :user

  before_validation :set_annotation_assigned_type, :set_assigner
  before_update { raise ActiveRecord::ReadOnlyRecord }
  after_create :send_email_notification_on_create, :increase_assignments_count, :propagate_assignments
  after_destroy :send_email_notification_on_destroy, :decrease_assignments_count, :propagate_unassignments
  after_commit :update_user_assignments_progress

  validate :assigned_to_user_from_the_same_team, if: proc { |a| a.user.present? }

  has_paper_trail on: [:create, :destroy], if: proc { |a| User.current.present? && a.assigned_type == 'Annotation' }

  def version_metadata(_changes)
    meta = { user_name: self.user&.name }
    annotation = self.assigned.load || self.assigned
    meta[:type] = annotation.annotation_type
    meta[:type] = 'media' if meta[:type] =~ /status/
    meta[:title] = annotation.to_s
    meta.to_json
  end

  def get_team
    assigned = self.assigned_type.constantize.where(id: self.assigned_id).last
    return [] if assigned.nil?
    return [assigned.team&.id] if assigned.is_a?(Project)
    assigned.get_team if assigned.is_annotation?
  end

  def get_team_and_project
    team = Team.where(id: self.get_team.first).last
    project = nil
    project = self.assigned if self.assigned_type == 'Project'
    project = self.assigned.annotated.project if self.assigned_type == 'Annotation'
    OpenStruct.new({ project: project, team: team })
  end

  protected

  def send_email_notification(action)
    return if User.current.nil?
    author = User.current
    assigned = self.assigned
    user = self.user
    return if [author, assigned, user].select{ |x| x.nil? }.any?
    type = assigned.is_a?(Annotation) ? assigned.annotation_type : self.assigned_type.downcase
    AssignmentMailer.delay_for(1.second).notify("#{action}_#{type}", author, user.email, assigned)
  end

  def change_assignments_count(value)
    assigned = self.assigned
    assigned.update_column(:assignments_count, assigned.assignments_count + value) if assigned.respond_to?(:assignments_count)
  end

  def propagate_assignments_or_unassignments(event)
    assignment = YAML::dump(self)
    self.propagate_in_foreground ? Assignment.propagate_assignments(assignment, nil, event) : Assignment.delay_for(1.second).propagate_assignments(assignment, User.current&.id, event)
  end

  def self.propagate_assignments(assignment, requestor_id, event)
    assignment = YAML::load(assignment)
    return if assignment.assigned.nil?
    to_create = []
    to_delete = []
    objs = assignment.assigned.propagate_assignment_to(assignment.user)
    task_ids = objs.select{ |t| t.is_a?(Task) }.map(&:id)
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
    Assignment.import(to_create)
    DynamicAnnotation::Field.joins(:annotation).where(field_name: 'task_status_status').where('annotations.annotated_id' => task_ids).update_all(value: 'unresolved')
    Assignment.delete(to_delete)
    assignment.send(:update_user_assignments_progress)
    Assignment.notify_propagate_assignments(requestor_id, assignment, event)
  end

  def self.notify_propagate_assignments(requestor_id, assignment, event)
    if Assignment.should_send_assignment_email(requestor_id, assignment)
      data = assignment.get_team_and_project
      AssignmentMailer.delay_for(1.second).ready(requestor_id, data.team, data.project, event, assignment.user)
    end
  end

  def self.should_send_assignment_email(requestor_id, assignment)
    requestor_id && assignment.assigned_type == 'Project'
  end

  def self.bulk_assign(obj, user_ids)
    obj = YAML::load(obj)
    klass = obj.is_annotation? ? 'Annotation' : obj.class.name
    user_ids.each do |user_id|
      if Assignment.where(user_id: user_id, assigned_type: klass, assigned_id: obj.id).last.nil?
        a = Assignment.new
        a.user_id = user_id
        a.assigned_id = obj.id
        a.assigned_type = klass
        a.propagate_in_foreground = true
        a.save!
      end
    end
  end

  private

  def assigned_to_user_from_the_same_team
    if self.assigned.present?
      team = self.get_team.empty? ? nil : Team.where(id: self.get_team[0]).last
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

  def update_user_assignments_progress
    user_id = self.user_id
    team_id = self.get_team.first
    TeamUser.delay_for(1.second).set_assignments_progress(user_id, team_id)
    assigned = self.assigned_type.constantize.where(id: self.assigned_id).last
    User.delay_for(1.second).set_assignments_progress(user_id, assigned.annotated_id.to_i) if assigned.is_a?(Annotation)
    ProjectMedia.where(project_id: self.assigned_id).each{ |pm| User.delay_for(1.second).set_assignments_progress(user_id, pm.id) } if assigned.is_a?(Project)
  end

  def set_assigner
    self.assigner_id = User.current.id if self.assigner_id.nil? && !User.current.nil?
  end
end
