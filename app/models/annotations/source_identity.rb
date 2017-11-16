class SourceIdentity < ActiveRecord::Base
  include AnnotationBase
  include HasImage

  field :name
  field :bio

  validates_presence_of :name
  validate :source_is_unique
  
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

  private

  def source_is_unique
    if self.annotated_type == 'Source'
      if !self.annotated.nil? && self.annotated.annotations.where(annotation_type: 'sourceidentity').exists?
        errors.add(:base, I18n.t(:duplicate_source)) 
      end
    end
  end

end
