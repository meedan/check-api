class TeamBotInstallation < TeamUser
  before_validation :apply_default_settings, on: :create
  before_validation :set_role, on: :create

  validate :can_be_installed_if_approved, on: :create
  validate :settings_follow_schema

  check_settings

  def json_settings=(json)
    self.settings = JSON.parse(json)
  end

  def json_settings
    self.settings.to_json
  end

  def bot_user
    BotUser.where(id: self.user_id).last
  end

  private

  def can_be_installed_if_approved
    if self.bot_user.present? && !self.bot_user.get_approved && self.team_id != self.bot_user.team_author_id
      errors.add(:base, I18n.t(:bot_not_approved_for_installation))
    end
  end

  def settings_follow_schema
    errors.add(:settings, 'must follow the schema') if self.bot_user && self.respond_to?(:settings) && self.bot_user.get_settings && !self.settings.blank? && !JSON::Validator.validate(JSON.parse(self.bot_user.settings_as_json_schema), self.settings)
  end

  def apply_default_settings
    bot = self.bot_user
    if !bot.blank? && !bot.get_settings.blank? && self.settings.blank?
      settings = {}
      bot.get_settings.each do |setting|
        s = setting.with_indifferent_access
        type = s[:type]
        default = s[:default]
        default = default.to_i if type == 'number'
        default = (default == 'true') if type == 'boolean'
        settings[s[:name]] = default
      end
      self.settings = settings
    end
  end

  def set_role
    self.role = self.bot_user&.get_role || 'contributor'
  end
end
