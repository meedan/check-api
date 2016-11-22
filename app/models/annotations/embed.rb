class Embed < ActiveRecord::Base
  include AnnotationBase

  field :title
  field :description
  field :quote
  field :embed
  field :username
  field :published_at, Integer
  
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

  def search_context
    data = self.data || {}
    data[:search_context] || []
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
