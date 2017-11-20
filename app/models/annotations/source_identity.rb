class SourceIdentity < ActiveRecord::Base
  include AnnotationBase
  include HasImage

  field :name
  field :bio

  validates_presence_of :name
  validate :source_is_unique, on: :create

  after_save :update_elasticsearch_source
  
  def content
    { 
      name: self.name,
      bio: self.bio 
      # avatar: self.file
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

  private

  def source_is_unique
    if self.annotated_type == 'Source'
      if !self.annotated.nil? && self.annotated.annotations.where(annotation_type: 'sourceidentity').exists?
        errors.add(:base, I18n.t(:duplicate_source)) 
      end
    end
  end

end
