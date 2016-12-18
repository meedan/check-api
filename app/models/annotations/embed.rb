class Embed < ActiveRecord::Base
  include AnnotationBase

  attr_accessible

  field :title
  field :description
  field :quote
  field :embed
  field :username
  field :published_at, Integer

  validate :validate_quote_for_media_with_empty_url
  after_save :update_elasticsearch_embed

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

  def update_elasticsearch_embed
    self.update_media_search(%w(title description quote)) if self.annotated_type == 'Media'
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
