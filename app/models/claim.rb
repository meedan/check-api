class Claim < Media

  attr_accessor :quote_attributions

  validates :quote, presence: true, on: :create

  after_create :set_claim_attributions

  def text
    self.quote
  end

  def media_type
    'quote'
  end

  private

  def set_claim_attributions
    quote_attributions = JSON.parse(self.quote_attributions) unless self.quote_attributions.nil?
    unless quote_attributions.blank?
      # create source
      create_claim_source(quote_attributions['name']) unless quote_attributions['name'].blank?
    end
  end

  def create_claim_source(name)
    source = Source.create_source(name)
    unless source.nil?
      cs = ClaimSource.new
      cs.source_id = source.id
      cs.media_id = self.id
      cs.skip_check_ability = true
      cs.save!
    end
  end
end
