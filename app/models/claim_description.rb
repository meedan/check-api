class ClaimDescription < ApplicationRecord
  include ClaimAndFactCheck

  belongs_to :project_media
  has_one :fact_check, dependent: :destroy

  accepts_nested_attributes_for :fact_check, reject_if: proc { |attributes| attributes['summary'].blank? }

  validates_presence_of :project_media
  validates_uniqueness_of :project_media_id

  # To avoid GraphQL conflict with name `context`
  alias_attribute :claim_context, :context

  # FIXME: Required by GraphQL API
  def fact_checks
    self.fact_check ? [self.fact_check] : []
  end

  def text_fields
    ['claim_description_content']
  end
end
