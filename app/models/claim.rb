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
      create_claim_source(quote_attributions['name']) unless quote_attributions['name'].blank?
    end
  end

  def create_source(name)
    s = Source.new
    s.name = name
    s.skip_check_ability = true
    s.save!
    s.reload
  end

  def create_claim_source(name)
    team_id = Team.current.nil? ? nil : Team.current.id
    source = Source.where(name: name, team_id: team_id).last
    source = create_source(name) if source.nil?
    unless source.nil?
      cs = ClaimSource.new
      cs.source_id = source.id
      cs.media_id = self.id
      cs.skip_check_ability = true
      cs.save!
    end
  end
end
