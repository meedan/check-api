class Assignment < ActiveRecord::Base
  belongs_to :annotation
  belongs_to :user

  before_update { raise ActiveRecord::ReadOnlyRecord }
  after_create :send_email_notification_on_create
  after_destroy :send_email_notification_on_destroy

  validate :assigned_to_user_from_the_same_team, if: proc { |a| a.user.present? }

  has_paper_trail on: [:create, :destroy], if: proc { |_a| User.current.present? }

  def version_metadata(_changes)
    meta = { user_name: self.user&.name }
    annotation = self.annotation.load || self.annotation
    meta[:type] = annotation.annotation_type
    meta[:type] = 'media' if meta[:type] =~ /status/
    meta[:title] = annotation.to_s
    meta.to_json
  end

  def get_team
    annotation = self.annotation
    annotation.nil? ? [] : annotation.get_team
  end

  protected

  def send_email_notification(action)
    author_id = User.current ? User.current.id : nil
    author = User.where(id: author_id).last
    annotation = self.annotation
    user = self.user
    return if author_id.nil? || author.nil? || annotation.nil? || user.nil?
    type = annotation.annotation_type
    AssignmentMailer.delay.notify("#{action}_#{type}", author, user.email, annotation.id)
  end

  private

  def assigned_to_user_from_the_same_team
    annotation = self.annotation
    if annotation.present? && annotation.annotated.present? && annotation.annotated.respond_to?(:project)
      team = annotation.annotated.project.team
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
end
