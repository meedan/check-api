class Check::TooManyRequestsError < StandardError
end

class ApiKey < ApplicationRecord
  belongs_to :team, optional: true
  belongs_to :user, optional: true

  validates_presence_of :access_token, :expire_at
  validates_uniqueness_of :access_token

  before_validation :generate_access_token, on: :create
  before_validation :calculate_expiration_date, on: :create
  before_validation :set_user_and_team

  has_one :bot_user

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

  def set_user_and_team
    self.user ||= User.current
    self.team ||= Team.current
  end

  def calculate_expiration_date
    self.expire_at ||= Time.now.since(30.days)
  end
end
