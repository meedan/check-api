class DynamicAnnotation::FieldType < ApplicationRecord
  validates :field_type, machine_name: true

  has_many :field_instances, class_name: 'DynamicAnnotation::FieldInstance', foreign_key: 'field_type', primary_key: 'field_type'
end
