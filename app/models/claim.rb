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

  private

  def remove_null_bytes
    self.quote = self.quote.gsub("\u0000", "\\u0000") unless self.quote.nil?
  end

  def set_uuid
    uuid = Claim.where('lower(quote) = ?', self.quote.to_s.strip.downcase).joins("INNER JOIN project_medias pm ON pm.media_id = medias.id").first&.id
    uuid ||= self.id
    self.update_column(:uuid, uuid)
  end
end
