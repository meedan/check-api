class Claim < Media

  attr_accessor :quote_attributions

  validates :quote, presence: true, on: :create

  before_validation :set_claim_attributions, on: :create

  def text
    self.quote
  end

  private

  def set_claim_attributions
    quote_attributions = JSON.parse(self.quote_attributions) unless self.quote_attributions.nil?
    unless quote_attributions.blank?
      # create source
      s = create_claim_source(quote_attributions['name']) unless quote_attributions['name'].blank?
      self.account = Account.create_for_source(quote_attributions['link'], s) unless quote_attributions['link'].blank?
    end
  end

  def create_claim_source(name)
    s = Source.new
    s.name = name
    s.skip_check_ability = true
    s.save!
    s.reload
  end
end
