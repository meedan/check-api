class SourceIdentity < ActiveRecord::Base
  include AnnotationBase
  include HasImage

  field :name
  field :bio

  validates_presence_of :name

  after_save :update_elasticsearch_source
  
  def content
    { 
      name: self.name,
      bio: self.bio,
      avatar: self.file
    }.to_json
  end

  def file_mandatory?
    false
  end

  def update_elasticsearch_source
    return if self.disable_es_callbacks
    if self.annotated_type == 'TeamSource'
      parent = Base64.encode64("TeamSource/#{self.annotated_id}")
      self.update_media_search(%w(title description), {'title' => self.name, 'description' => self.bio}, parent)
    end
  end

end
