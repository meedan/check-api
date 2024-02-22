class Claim < Media
  attr_accessor :quote_attributions

  before_validation :remove_null_bytes
  validates :quote, presence: true, on: :create

  def text
    self.quote
  end

  def media_type
    'quote'
  end

  def uuid
    Media.where(type: 'Claim', quote: self.quote.to_s.strip).first&.id || self.id
  end

  private

  def remove_null_bytes
    self.quote = self.quote.gsub("\u0000", "\\u0000") unless self.quote.nil?
  end
end
