class TeamBotInstallation < ActiveRecord::Base
  belongs_to :team
  belongs_to :team_bot

  before_validation :apply_default_settings, on: :create

  validates :team_id, :team_bot_id, presence: true
  validate :can_be_installed_if_approved, on: :create
  validate :can_be_installed_if_limited, on: :create
  validate :settings_follow_schema

  after_create :give_access_to_team
  after_destroy :remove_access_from_team
  
  check_settings

  def json_settings=(json)
    self.settings = JSON.parse(json)
  end

  def json_settings
    self.settings.to_json
  end

  private

  def can_be_installed_if_approved
    if self.team_bot.present? && !self.team_bot.approved && self.team_id != self.team_bot.team_author_id
      errors.add(:base, I18n.t(:bot_not_approved_for_installation))
    end
  end

  def can_be_installed_if_limited
    if self.team_bot.present? && self.team_bot.limited && !self.team.send("get_limits_#{self.team_bot.identifier}") && self.team_bot.team_author_id != self.team_id
      errors.add(:base, I18n.t(:bot_limited_team_not_pro))
    end
  end

  def give_access_to_team
    if TeamUser.where(user_id: self.team_bot.bot_user_id, team_id: self.team_id).last.nil?
      team_user = TeamUser.new
      team_user.role = self.team_bot.role
      team_user.status = 'member'
      team_user.user_id = self.team_bot.bot_user_id
      team_user.team_id = self.team_id
      team_user.skip_check_ability = true
      team_user.save!
    end
  end

  def remove_access_from_team
    team_bot = self.team_bot
    unless team_bot.nil?
      team_user = TeamUser.where(user_id: team_bot.bot_user_id, team_id: self.team_id).last
      unless team_user.nil?
        team_user.skip_check_ability = true
        team_user.destroy!
      end
    end
  end

  def settings_follow_schema
    errors.add(:settings, 'must follow the schema') if self.respond_to?(:settings) && self.team_bot.respond_to?(:settings) && !self.team_bot.settings.blank? && !self.settings.blank? && !JSON::Validator.validate(JSON.parse(self.team_bot.settings_as_json_schema), self.settings)
  end

  def apply_default_settings
    team_bot = self.team_bot
    if team_bot.respond_to?(:settings) && !team_bot.settings.blank? && self.settings.blank?
      settings = {}
      team_bot.settings.each do |setting|
        s = setting.with_indifferent_access
        type = s[:type]
        default = s[:default]
        default = default.to_i if type == 'number'
        default = (default == 'true' ? true : false) if type == 'boolean'
        settings[s[:name]] = default
      end
      self.settings = settings
    end
  end
end
