class DynamicAnnotation::AnnotationType < ActiveRecord::Base
  
  validates :annotation_type, machine_name: true
  validate :annotation_type_is_available
  
  has_many :schema, class_name: 'DynamicAnnotation::FieldInstance', foreign_key: 'annotation_type', primary_key: 'annotation_type'
  has_many :annotations, class_name: 'Annotation', foreign_key: 'annotation_type', primary_key: 'annotation_type'

  private

  def annotation_type_is_available
    begin
      self.annotation_type.camelize.constantize
      errors.add(:annotation_type, 'is not available')
    rescue NameError
      # Not defined
    end
  end
end
