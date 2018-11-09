class Assignment < ActiveRecord::Base
  belongs_to :assigned, polymorphic: true
  belongs_to :user

  before_validation :set_annotation_assigned_type
  before_update { raise ActiveRecord::ReadOnlyRecord }
  after_create :send_email_notification_on_create, :increase_assignments_count
  after_destroy :send_email_notification_on_destroy, :decrease_assignments_count

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
    assigned = self.assigned
    return [assigned.team&.id] if assigned.is_a?(Project)
    assigned.get_team if assigned.is_a?(Annotation)
  end

  protected

  def send_email_notification(action)
    author_id = User.current ? User.current.id : nil
    author = User.where(id: author_id).last
    assigned = self.assigned
    user = self.user
    return if [author_id, author, assigned, user].select{ |x| x.nil? }.any?
    type = assigned.is_a?(Annotation) ? assigned.annotation_type : self.assigned_type.downcase
    AssignmentMailer.delay.notify("#{action}_#{type}", author, user.email, assigned)
  end

  def change_assignments_count(value)
    assigned = self.assigned
    assigned.update_column(:assignments_count, assigned.assignments_count + value) if assigned.respond_to?(:assignments_count)
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
end
