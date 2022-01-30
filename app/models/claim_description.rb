class ClaimDescription < ApplicationRecord
  belongs_to :user
  belongs_to :project_media
  has_one :fact_check

  before_validation :set_user, on: :create
  validates_presence_of :description, :user, :project_media

  # FIXME: Required by GraphQL API
  def fact_checks
    self.fact_check ? [self.fact_check] : []
  end

  private

  def set_user
    self.user ||= User.current
  end
end
