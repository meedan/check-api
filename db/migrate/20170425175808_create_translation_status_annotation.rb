class CreateTranslationStatusAnnotation < ActiveRecord::Migration[4.2]
  require 'sample_data'
  include SampleData

  def change
    ft1 = DynamicAnnotation::FieldType.where(field_type: 'select').last || create_field_type(field_type: 'select', label: 'Select')
    ft2 = DynamicAnnotation::FieldType.where(field_type: 'text').last || create_field_type(field_type: 'text', label: 'Text')
    at = create_annotation_type annotation_type: 'translation_status', label: 'Translation Status'
    create_field_instance annotation_type_object: at, name: 'translation_status_status', label: 'Translation Status', field_type_object: ft1, optional: false
    create_field_instance annotation_type_object: at, name: 'translation_status_note', label: 'Translation Status Note', field_type_object: ft2, optional: true
  end
end
