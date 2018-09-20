require 'active_support/concern'

module ProjectMediaPrivate
  extend ActiveSupport::Concern

  private

  def move_media_sources
    if self.project_id_changed?
      ps = get_project_source(self.project_id_was)
      unless ps.nil?
        target_ps = ProjectSource.where(project_id: self.project_id, source_id: ps.source_id).last
        if target_ps.nil?
          ps.project_id = self.project_id
          ps.skip_check_ability = true
          ps.disable_es_callbacks = Rails.env.to_s == 'test'
          ps.save!
        else
          ps.destroy
        end
      end
    end
  end

  def get_project_source(pid)
    sources = []
    sources = self.media.account.sources.map(&:id) unless self.media.account.nil?
    sources.concat ClaimSource.where(media_id: self.media_id).map(&:source_id)
    ProjectSource.where(project_id: pid, source_id: sources).first
  end

  def project_is_not_archived
    parent_is_not_archived(self.project, I18n.t(:error_project_archived, default: "Can't create media under trashed project"))
  end

  def update_media_account
    a = self.media.account
    embed = self.media.embed
    unless a.nil? || a.embed['author_url'] == embed['author_url']
      s = a.sources.where(team_id: Team.current.id).last
      s = nil if !s.nil? && s.name.start_with?('Untitled')
      new_a = self.send(:account_from_author_url, embed['author_url'], s)
      set_media_account(new_a, s) unless new_a.nil?
    end
  end

  def account_from_author_url(author_url, source)
    begin Account.create_for_source(author_url, source) rescue nil end
  end

  def set_media_account(account, source)
    m = self.media
    a = self.media.account
    m.account = account
    m.skip_check_ability = true
    m.save!
    a.skip_check_ability = true
    a.destroy if a.medias.count == 0
    # Add a project source if new source was created
    self.create_project_source if source.nil?
    # update es
    self.update_elasticsearch_doc(['account'], {account: self.set_es_account_data}, self.id)
  end

  def archive_or_restore_related_medias_if_needed
    ProjectMedia.delay.archive_or_restore_related_medias(self.archived, self.id) if self.archived_changed?
  end

  def destroy_related_medias
    user_id = User.current.nil? ? nil : User.current.id
    ProjectMedia.delay.destroy_related_medias(YAML.dump(self), user_id)
  end

  def notify_team_bots_create
    self.send :notify_team_bots, 'create'
  end

  def notify_team_bots_update
    self.send :notify_team_bots, 'update'
  end

  def notify_team_bots(event)
    TeamBot.notify_bots_in_background("#{event}_project_media", self.project.team_id, self)
  end
end
