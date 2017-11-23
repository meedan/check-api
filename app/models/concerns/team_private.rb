require 'active_support/concern'

module TeamPrivate
  extend ActiveSupport::Concern

  private

  def add_user_to_team
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
    self.slug = self.slug.downcase unless self.slug.blank?
  end

  def archive_or_restore_projects_if_needed
    Team.delay.archive_or_restore_projects_if_needed(self.archived, self.id) if self.archived_changed?
  end

  def clear_embeds_caches_if_needed
    changed = false
    if self.changes && self.changes['settings']
      prevval = self.changes['settings'][0] || {}
      newval = self.changes['settings'][1] || {}
      changed = (prevval['hide_names_in_embeds'] != newval['hide_names_in_embeds']) ? true : false
    end
    Team.delay.clear_embeds_caches_if_needed(self.id) if changed 
  end
end
