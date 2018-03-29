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
    self.slug =  self.is_being_copied ? self.generate_copy_slug : self.slug.downcase
  end

  def archive_or_restore_projects_if_needed
    Team.delay.archive_or_restore_projects_if_needed(self.archived, self.id) if self.archived_changed?
  end

  def clear_embeds_caches_if_needed
    changed = false
    if self.changes['settings']
      prevval = self.changes['settings'][0] || {}
      newval = self.changes['settings'][1] || {}
      changed = true if prevval['hide_names_in_embeds'] != newval['hide_names_in_embeds']
    end
    Team.delay.clear_embeds_caches_if_needed(self.id) if changed 
  end

  def change_custom_media_statuses
    media_statuses = self.get_media_verification_statuses
    return if media_statuses.blank?
    list = Status.validate_custom_statuses(self.id, media_statuses)
    unless list.blank?
      urls = list.collect{|l| l[:url]}
      statuses = list.collect{|l| l[:status]}.uniq
      errors.add(:base, I18n.t(:cant_change_custom_statuses, statuses: statuses, urls: urls))
    end
  end

  def reset_current_team
    User.where(current_team_id: self.id).each{ |user| user.update_columns(current_team_id: nil) }
  end
end
