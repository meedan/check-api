require 'active_support/concern'

module ProjectMediaPrivate
  extend ActiveSupport::Concern

  def get_project_source(pid)
    sources = []
    sources = self.media.account.sources.map(&:id) unless self.media.account.nil?
    sources.concat ClaimSource.where(media_id: self.media_id).map(&:source_id)
    ProjectSource.where(project_id: pid, source_id: sources).first
  end

  private

  def move_media_sources
    if self.project_id_changed?
      ps = get_project_source(self.project_id_was)
      unless ps.nil?
        target_ps = ProjectSource.where(project_id: self.project_id, source_id: ps.source_id).last
        ps.skip_check_ability = true
        if target_ps.nil?
          ps.project_id = self.project_id
          ps.disable_es_callbacks = Rails.env.to_s == 'test'
          ps.save!
        else
          ps.destroy
        end
      end
    end
  end

  def project_is_not_archived
    parent_is_not_archived(self.project, I18n.t(:error_project_archived))
  end

  def update_media_account
    a = self.media.account
    metadata = self.media.metadata
    unless a.nil? || a.metadata['author_url'] == metadata['author_url']
      s = a.sources.where(team_id: Team.current.id).last
      s = nil if !s.nil? && s.name.start_with?('Untitled')
      new_a = self.send(:account_from_author_url, metadata['author_url'], s)
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
    a.account_sources.each { |as| as.skip_check_ability = true }
    # Remove old account from ES
    a.destroy_es_items('accounts', 'destroy_doc_nested', self)
    a.destroy if a.medias.count == 0
    # Add a project source if new source was created
    self.create_project_source if source.nil?
    # update es
    self.add_update_nested_obj({ op: 'create', nested_key: 'accounts', keys: %w(id title description username), data: self.set_es_account_data.first , obj: self})
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
    BotUser.enqueue_event("#{event}_project_media", self.team_id, self)
  end

  def apply_rules_and_actions
    self.team&.apply_rules_and_actions(self, nil)
  end

  def set_team_id
    self.team_id = self.project.team_id if self.team_id.blank? && !self.project_id.blank?
    self.team_id = Team.current.id if self.team_id.blank? && !Team.current.blank?
  end

  def create_project_media_project
    ProjectMediaProject.create!(project_media_id: self.id, project_id: self.project_id, disable_es_callbacks: self.disable_es_callbacks) unless self.project_id.blank?
  end

  def update_project_media_project
    if self.previous_changes.keys.include?('project_id') || self.changes.keys.include?('project_id') || (!self.previous_project_id.nil? && !self.project_id.nil? && self.previous_project_id != self.project_id)
      ProjectMediaProject.where(project_media_id: self.id).delete_all
      ProjectMediaProject.create!(project_media_id: self.id, project_id: self.project_id)
      # Update team task
      TeamTaskWorker.perform_in(1.second, 'add_or_move', self.project_id, YAML::dump(User.current), YAML::dump({ model: self }))
    end
  end
end
