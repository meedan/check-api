class ApiKey < ActiveRecord::Base
  validates_presence_of :access_token, :expire_at
  validates_uniqueness_of :access_token

  before_validation :generate_access_token, on: :create
  before_validation :calculate_expiration_date, on: :create
  
  attr_accessible :application

  # Reimplement this method in your application
  def self.applications
    [nil]
  end
  
  validates :application, inclusion: { in: proc { ApiKey.applications } }

  private

  def generate_access_token
    begin
      self.access_token = SecureRandom.hex
    end while ApiKey.where(access_token: access_token).exists?
  end

  def calculate_expiration_date
    self.expire_at = Time.now.since(30.days)
  end
end
