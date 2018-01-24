require 'active_support/concern'

# This concern expects that the model that includes it has a `assigned_to_id` 
# integer field in its table in the database

module Assignment
  extend ActiveSupport::Concern

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

  module ClassMethods
    def assigned_to_user(user)
      uid = user.is_a?(User) ? user.id : user
      self.where(assigned_to_id: uid)
    end

    def project_media_assigned_to_user(user)
      uid = user.is_a?(User) ? user.id : user
      ProjectMedia.joins("INNER JOIN annotations a ON a.annotated_type = 'ProjectMedia' AND a.annotated_id = project_medias.id").where('a.assigned_to_id' => uid, 'a.annotation_type' => 'status').distinct
    end
  end

  included do
    belongs_to :assigned_to, class_name: 'User'
    validate :assigned_to_user_from_the_same_team
  end
end
