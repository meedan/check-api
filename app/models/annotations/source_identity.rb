class SourceIdentity < ActiveRecord::Base
  include AnnotationBase
  include HasImage

  field :name
  field :bio

  validates_presence_of :name
  
  def content
    { 
      name: self.name,
      bio: self.bio 
    }.to_json
  end

  def file_mandatory?
    false
  end

end
