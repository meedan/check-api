class DynamicAnnotation::FieldInstance < ApplicationRecord
  belongs_to :field_type_object, class_name: 'DynamicAnnotation::FieldType', primary_key: 'field_type', foreign_key: 'field_type'
  belongs_to :annotation_type_object, class_name: 'DynamicAnnotation::AnnotationType', primary_key: 'annotation_type', foreign_key: 'annotation_type'

  serialize :settings

  validates :name, machine_name: true
end
