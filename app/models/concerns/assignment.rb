require 'active_support/concern'

# This concern expects that the model that includes it has a `assigned_to_id` 
# integer field in its table in the database

module Assignment
  extend ActiveSupport::Concern

  def version_metadata(changes)
    return if changes.blank?
    changes = JSON.parse(changes)
    from = changes['assigned_to_id'] ? User.where(id: changes['assigned_to_id'][0]).last : nil
    to = User.where(id: self.assigned_to_id).last
    from = from.name unless from.nil?
    to = to.name unless to.nil?
    { assigned_from_name: from, assigned_to_name: to }.to_json if from != to
  end

  def previous_assignee
    @previous_assignee
  end

  def previous_assignee=(assignee)
    @previous_assignee = assignee
  end

  private

  def assigned_to_user_from_the_same_team
    if !self.assigned_to_id.blank? && self.annotated.present? && self.annotated.respond_to?(:project)
      team = self.annotated.project.team
      unless team.nil?
        member = TeamUser.where(team_id: team.id, user_id: self.assigned_to_id, status: 'member').last
        errors.add(:base, I18n.t(:error_user_is_not_a_team_member, default: "Sorry, you can only assign to members of this team")) if member.nil?
      end
    end
  end

  def set_nil_if_zero
    self.assigned_to_id = nil if self.assigned_to_id == 0
  end

  def store_previous_assignee
    self.previous_assignee = self.assigned_to_id_was
  end

  def send_email_notification
    if self.assigned_to_id != self.previous_assignee
      author_id = User.current ? User.current.id : nil
      author = User.find(author_id)
      type = self.annotation_type
      AssignmentMailer.delay.notify("assign_#{type}", author, self.assigned_to.email, self.id) if self.assigned_to_id.to_i > 0
      AssignmentMailer.delay.notify("unassign_#{type}", author, User.find(self.previous_assignee).email, self.id) if self.previous_assignee.to_i > 0
    end
  end

  module ClassMethods
    def assigned_to_user(user)
      uid = user.is_a?(User) ? user.id : user
      self.where(assigned_to_id: uid)
    end

    def project_media_assigned_to_user(user)
      uid = user.is_a?(User) ? user.id : user
      ProjectMedia.joins("INNER JOIN annotations a ON a.annotated_type = 'ProjectMedia' AND a.annotated_id = project_medias.id").where('a.assigned_to_id' => uid).distinct
    end
  end

  included do
    belongs_to :assigned_to, class_name: 'User'
    
    before_validation :set_nil_if_zero, :store_previous_assignee
    after_save :send_email_notification
    
    validate :assigned_to_user_from_the_same_team
  end
end
