require 'active_support/concern'

module ProjectMediaPrivate
  extend ActiveSupport::Concern

  CUSTOM_CHANNEL_SCHEMA = {
    type: 'object',
    required: ['main'],
    properties: {
      main: { type: 'number', title: 'Main' },
      others: { type: 'array', title: 'Others' },
    }
  }

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
    a.destroy if a.medias.count == 0
  end

  def archive_or_restore_related_medias_if_needed
    ProjectMedia.delay.archive_or_restore_related_medias(self.archived, self.id, self.team) if self.saved_change_to_archived?
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

  def set_team_id
    self.team_id = Team.current.id if self.team_id.blank? && !Team.current.blank?
  end

  def source_belong_to_team
    errors.add(:base, "Source should belong to media team.") if self.team_id != self.source.team_id
  end

  def set_channel
    self.channel ||= { main: CheckChannels::ChannelCodes::API } unless ApiKey.current.nil?
  end

  def custom_channel_format
    errors.add(:channel, JSON::Validator.fully_validate(CUSTOM_CHANNEL_SCHEMA, self.channel)) if !JSON::Validator.validate(CUSTOM_CHANNEL_SCHEMA, self.channel)
  end

  def archived_in_allowed_values
    allowed_values = CheckArchivedFlags::FlagCodes.archived_codes.values
    errors.add(:archived, I18n.t(:"errors.messages.invalid_project_media_archived_value")) unless allowed_values.include?(self.archived)
  end

  def channel_in_allowed_values
    main = self.channel.with_indifferent_access[:main].to_i
    error = !CheckChannels::ChannelCodes::ALL.include?(main)
    others = self.channel.with_indifferent_access[:others] || []
    unless error || others.empty?
      others = others.map(&:to_i)
      error = !(others - CheckChannels::ChannelCodes::ALL).empty?
    end
    errors.add(:channel, I18n.t(:"errors.messages.invalid_project_media_channel_value")) if error
  end

  def channel_not_changed
    value = self.channel.with_indifferent_access[:main].to_i
    value_was = self.channel_was.with_indifferent_access[:main].to_i
    errors.add(:channel, I18n.t(:"errors.messages.invalid_project_media_channel_update")) if value != value_was
  end

  def apply_delete_for_ever
    return if RequestStore.store[:skip_delete_for_ever]
    interval = CheckConfig.get('empty_trash_interval', 30).to_i
    options = { type: 'trash', updated_at: self.updated_at.to_i }
    ProjectMediaTrashWorker.perform_in(interval.days, self.id, YAML.dump(options))
  end

  def rate_limit_not_exceeded
    if ApiKey.current && ApiKey.current.respond_to?(:rate_limits)
      limit = ApiKey.current.rate_limits.to_h.with_indifferent_access[:created_items_per_minute] || CheckConfig.get('api_key_rate_limit_created_items_per_minute', 60)
      raise Check::TooManyRequestsError if limit && ProjectMedia.where(team_id: self.team_id, created_at: Time.now.ago(1.minute)..Time.now).count >= limit.to_i
    end
  end
end
