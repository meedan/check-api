class Claim < Media

  attr_accessor :quote_attributions

  validates :quote, presence: true, on: :create

  after_create :set_claim_attributions

  def text
    self.quote
  end

  private

  def set_claim_attributions
    quote_attributions = JSON.parse(self.quote_attributions) unless self.quote_attributions.nil?
    unless quote_attributions.blank?
      # create source
      s = create_source(quote_attributions['name']) unless quote_attributions['name'].blank?
      unless quote_attributions['link'].blank?
        self.account = Account.create_for_source(quote_attributions['link'], s)
        self.save!
      end
      create_claim_source(s) if self.account.nil?

    end
  end

  def create_source(name)
    s = Source.new
    s.name = name
    s.skip_check_ability = true
    s.save!
    s.reload
  end

  def create_claim_source(source)
    return if source.nil?
    cs = ClaimSource.new
    cs.source_id = source.id
    cs.media_id = self.id
    cs.skip_check_ability = true
    cs.save!
  end
end
