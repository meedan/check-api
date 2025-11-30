class Check::TooManyRequestsError < StandardError
end

class ApiKey < ApplicationRecord
  attr_accessor :skip_create_bot_user

  belongs_to :team, optional: true
  belongs_to :user, optional: true

  validates_presence_of :access_token, :expire_at
  validates_uniqueness_of :access_token
  validates :title, uniqueness: { scope: :team }

  before_validation :generate_access_token, on: :create
  before_validation :calculate_expiration_date, on: :create
  before_validation :set_user_and_team
  after_create :create_bot_user, unless: proc { |key| key.skip_create_bot_user }

  validate :validate_team_api_keys_limit, on: :create

  has_one :bot_user

  after_destroy :delete_bot_user

  # Reimplement this method in your application
  def self.applications
    [nil]
  end

  validates :application, inclusion: { in: proc { ApiKey.applications } }

  def self.current
    RequestStore.store[:api_key]
  end

  def self.current=(api_key)
    RequestStore.store[:api_key] = api_key
  end

  private

  def generate_access_token
    loop do
      self.access_token = SecureRandom.hex
      break unless ApiKey.where(access_token: access_token).exists?
    end
  end

  def create_bot_user
    if self.bot_user.blank? && self.team.present?
      bot_name = "#{self.team.slug}-bot-#{self.title}"
      new_bot_user = BotUser.new(api_key: self, name: bot_name, login: bot_name)
      new_bot_user.skip_check_ability = true
      new_bot_user.set_role 'editor'
      new_bot_user.save!
    end
  end

  def delete_bot_user
    if bot_user.present? && bot_user.owns_media?
      bot_user.update(api_key_id: nil)
    else
      bot_user.destroy
    end
  end

  def set_user_and_team
    self.user = User.current unless User.current.nil?
    self.team = Team.current unless Team.current.nil?
  end

  def calculate_expiration_date
    api_default_expiry_days = CheckConfig.get('api_default_expiry_days', 30).to_i
    self.expire_at ||= Time.now.since(api_default_expiry_days.days)
  end

  def validate_team_api_keys_limit
    return unless team

    max_team_api_keys =  CheckConfig.get('max_team_api_keys', 20).to_i
    errors.add(:base, "Maximum number of API keys exceeded") if team.api_keys.count >= max_team_api_keys
  end
end
