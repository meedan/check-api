class ClaimDescription < ApplicationRecord
  include ClaimAndFactCheck

  belongs_to :project_media
  has_one :fact_check

  validates_presence_of :user, :project_media

  # FIXME: Required by GraphQL API
  def fact_checks
    self.fact_check ? [self.fact_check] : []
  end

  def text_fields
    ['claim_description_content']
  end
end
