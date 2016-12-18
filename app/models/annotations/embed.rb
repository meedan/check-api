class Embed < ActiveRecord::Base
  include AnnotationBase

  attr_accessible

  field :title
  field :description
  field :embed
  field :username
  field :published_at, Integer

  after_save :update_elasticsearch_embed

  def content
    {
      title: self.title,
      description: self.description,
      username: self.username,
      published_at: self.published_at,
      embed: self.embed
    }.to_json
  end

  def search_context
    data = self.data || {}
    data[:search_context] || []
  end

  def search_context=(value)
    data = self.data || {}
    data[:search_context] = value
  end

  def update_elasticsearch_embed
    self.update_media_search(%w(title description)) if self.annotated_type == 'Media'
  end

end
