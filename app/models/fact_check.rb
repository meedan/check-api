class FactCheck < ApplicationRecord
  include ClaimAndFactCheck

  belongs_to :claim_description

  validates_presence_of :summary, :title, :user, :claim_description
  validates_format_of :url, with: URI.regexp, allow_blank: true, allow_nil: true

  def text_fields
    ['fact_check_title', 'fact_check_summary']
  end

  def project_media
    self.claim_description.project_media
  end
end
