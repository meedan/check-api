class Embed < ActiveRecord::Base
  include AnnotationBase

  attr_accessible :annotator_type, :annotated_type, :annotated_id, :annotator_type, :annotator_id, :entities, :data

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

  def update_elasticsearch_embed
    self.update_media_search(%w(title description)) if self.annotated_type == 'ProjectMedia'
  end

end
