class CreateTranslationStatusApproverField < ActiveRecord::Migration[4.2]
  require 'sample_data'
  include SampleData

  def change
    at = DynamicAnnotation::AnnotationType.where(annotation_type: 'translation_status').last
    ft = DynamicAnnotation::FieldType.where(field_type: 'json').last || create_field_type(field_type: 'json', label: 'JSON')
    create_field_instance annotation_type_object: at, name: 'translation_status_approver', label: 'Translation Status Approver', field_type_object: ft, optional: true
  end
end
