class DynamicAnnotation::AnnotationType < ApplicationRecord
  include HasJsonSchema

  validates :annotation_type, machine_name: true, uniqueness: true
  validate :annotation_type_is_available

  has_many :schema, class_name: 'DynamicAnnotation::FieldInstance', foreign_key: 'annotation_type', primary_key: 'annotation_type'
  has_many :annotations, class_name: 'Annotation', foreign_key: 'annotation_type', primary_key: 'annotation_type'

  def json_schema_enabled?
    self.respond_to?('json_schema=') && ApplicationRecord.connection.column_exists?(:dynamic_annotation_annotation_types, :json_schema)
  end

  private

  def annotation_type_is_available
    if !self.annotation_type.blank? && Object.const_defined?(self.annotation_type.camelize)
      errors.add(:annotation_type, 'is not available')
    end
  end
end
