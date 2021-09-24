class CreateVerificationStatus < ActiveRecord::Migration[4.2]
  require 'sample_data'
  include SampleData

  def change
    ft = DynamicAnnotation::FieldType.where(field_type: 'select').last || create_field_type(field_type: 'select', label: 'Select')
    at = create_annotation_type annotation_type: 'verification_status', label: 'Verification Status'
    create_field_instance annotation_type_object: at, name: 'verification_status_status', label: 'Verification Status', field_type_object: ft, optional: false
  end
end
