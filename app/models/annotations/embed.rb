class Embed
  include AnnotationBase

  attribute :title, String
  attribute :description, String
  attribute :username, String
  attribute :published_at,  Integer
  attribute :quote, String
  attribute :embed, String
  validate :exist_of_title_or_embed

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

  def exist_of_title_or_embed
    if self.embed.blank? and self.title.blank?
      errors.add(:base, "Should fill at least one filed [title or embed]")
    end
  end

end
