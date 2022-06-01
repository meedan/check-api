class ClaimDescription < ApplicationRecord
  include ClaimAndFactCheck
  has_paper_trail on: [:create, :update], ignore: [:updated_at, :created_at], if: proc { |_x| User.current.present? }, versions: { class_name: 'Version' }

  belongs_to :project_media
  has_one :fact_check, dependent: :destroy

  validates_presence_of :user, :project_media

  # FIXME: Required by GraphQL API
  def fact_checks
    self.fact_check ? [self.fact_check] : []
  end

  def text_fields
    ['claim_description_content']
  end
end
