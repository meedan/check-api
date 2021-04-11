require 'active_support/concern'

module ProjectMediaPrivate
  extend ActiveSupport::Concern

  private

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
    pender_key = self.team.get_pender_key if self.team
    begin Account.create_for_source(author_url, source, false, false, pender_key) rescue nil end
  end

  def set_media_account(account, _source)
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

  def apply_rules_and_actions_on_create
    self.team.apply_rules_and_actions(self, nil)
  end

  def apply_rules_and_actions_on_update
    rule_ids = self.team.get_rules_that_match_condition { |condition, _value| condition == 'item_is_read' && self.read }
    self.team.apply_rules_and_actions(self, rule_ids)
  end

  def set_team_id
    if self.team_id.blank? && !self.project_id.blank?
      project = Project.find_by_id self.project_id
      self.team_id = project.team_id unless project.nil?
    end
    self.team_id = Team.current.id if self.team_id.blank? && !Team.current.blank?
  end

  def source_belong_to_team
    errors.add(:base, "Source should belong to media team.") if self.team_id != self.source.team_id
  end

  def add_remove_team_tasks
    self.add_destination_team_tasks(self.project_id, false)
  end

  def project_is_not_archived
    parent_is_not_archived(self.project, I18n.t(:error_project_archived)) unless self.project.nil?
  end
end
