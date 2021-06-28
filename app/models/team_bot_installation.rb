class TeamBotInstallation < TeamUser
  include Versioned

  before_validation :apply_default_settings, on: :create
  before_validation :set_role, on: :create

  validate :can_be_installed_if_approved, on: :create
  validate :settings_follow_schema, on: :update

  check_settings

  def json_settings=(json)
    self.settings = JSON.parse(json)
  end

  def json_settings
    self.settings.to_json
  end

  def alegre_settings
    settings = {}
    boolean_keys = %w(master_similarity_enabled text_similarity_enabled image_similarity_enabled)
    boolean_keys.each{ |k| settings[k] = self.send("get_#{k}") || false }
    threshold_keys = %w(
      text_length_matching_threshold
      text_elasticsearch_matching_threshold
      text_elasticsearch_suggestion_threshold
      text_vector_matching_threshold
      text_vector_suggestion_threshold
      image_hash_matching_threshold
      image_hash_suggestion_threshold
    )
    threshold_keys.each do |k|
      settings[k] = self.send("get_#{k}") || CheckConfig.get(k)
    end
    # other keys
    settings['text_similarity_model'] = self.get_text_similarity_model
    settings
  end

  def bot_user
    BotUser.where(id: self.user_id).last
  end

  def apply_default_settings
    bot = self.bot_user
    if !bot.blank? && !bot.get_settings.blank?
      settings = {}
      bot.get_settings.each do |setting|
        s = setting.with_indifferent_access
        type = s[:type]
        default = s[:default]
        default = default.to_i if type == 'number'
        default = (default == 'true') if type == 'boolean'
        default ||= [] if type == 'array'
        settings[s[:name]] = default
      end
      current_settings = self.settings || {}
      self.settings = settings.merge(current_settings)
    end
  end

  private

  def can_be_installed_if_approved
    if self.bot_user.present? && !self.bot_user.get_approved && self.team_id != self.bot_user.team_author_id
      errors.add(:base, I18n.t(:bot_not_approved_for_installation))
    end
  end

  def settings_follow_schema
    if self.bot_user && self.respond_to?(:settings) && self.bot_user.get_settings && !self.settings.blank?
      json_schema = self.bot_user.settings_as_json_schema(true)
      if json_schema
        value = JSON.parse(json_schema)
        errors.add(:settings, JSON::Validator.fully_validate(value, self.settings)) if !JSON::Validator.validate(value, self.settings)
      end
    end
  end

  def set_role
    self.role = self.bot_user&.get_role || 'collaborator'
  end
end
