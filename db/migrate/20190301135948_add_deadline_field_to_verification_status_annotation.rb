class AddDeadlineFieldToVerificationStatusAnnotation < ActiveRecord::Migration[4.2]
  require 'sample_data'
  include SampleData

  def change
    at = DynamicAnnotation::AnnotationType.where(annotation_type: 'verification_status').last
    ft = DynamicAnnotation::FieldType.where(field_type: 'timestamp').last || create_field_type(field_type: 'timestamp', label: 'Timestamp')
    create_field_instance annotation_type_object: at, name: 'deadline', label: 'Deadline', field_type_object: ft, optional: true
  end
end
