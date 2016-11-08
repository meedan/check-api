class Embed
  include AnnotationBase

  attribute :title, String, mapping: { analyzer: 'hashtag' }
  attribute :description, String, mapping: { analyzer: 'hashtag' }
  attribute :quote, String, mapping: { analyzer: 'hashtag' }

  attribute :embed, String
  attribute :username, String
  attribute :published_at, Integer
  attribute :search_context, Array
  
  validate :validate_quote_for_media_with_empty_url

  def content
    {
      title: self.title,
      description: self.description,
      username: self.username,
      published_at: self.published_at,
      quote: self.quote,
      embed: self.embed
    }.to_json
  end

  private

  def validate_quote_for_media_with_empty_url
    unless self.annotated.nil?
      if self.annotated_type == 'Media' and self.annotated.url.blank? and self.quote.blank?
        errors.add(:base, "quote can't be blank")
      end
    end
  end

end
