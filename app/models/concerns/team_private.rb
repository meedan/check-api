require 'active_support/concern'

module TeamPrivate
  extend ActiveSupport::Concern

  private

  def add_user_to_team
    return if self.is_being_copied
    user = User.current
    unless user.nil?
      tu = TeamUser.new
      tu.user = user
      tu.team = self
      tu.role = 'owner'
      tu.save!

      user.current_team_id = self.id
      user.save!
    end
  end

  def normalize_slug
    return if self.slug.blank?
    self.slug = self.slug.downcase
  end

  def archive_or_restore_projects_if_needed
    Team.delay.archive_or_restore_projects_if_needed(self.archived, self.id) if self.archived_changed?
  end

  def reset_current_team
    User.where(current_team_id: self.id).each{ |user| user.update_columns(current_team_id: nil) }
  end
end
