class DynamicAnnotation::FieldInstance < ApplicationRecord
  belongs_to :field_type_object, class_name: 'DynamicAnnotation::FieldType', primary_key: 'field_type', foreign_key: 'field_type', optional: true
  belongs_to :annotation_type_object, class_name: 'DynamicAnnotation::AnnotationType', primary_key: 'annotation_type', foreign_key: 'annotation_type', optional: true

  serialize :settings

  validates :name, machine_name: true, uniqueness: true
end
