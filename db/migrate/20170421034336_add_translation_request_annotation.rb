class AddTranslationRequestAnnotation < ActiveRecord::Migration[4.2]
  require 'sample_data'
  include SampleData

  def change
    ft = DynamicAnnotation::FieldType.where(field_type: 'text').last || create_field_type(field_type: 'text', label: 'Text')
    at = create_annotation_type annotation_type: 'translation_request', label: 'Translation Request'
    create_field_instance annotation_type_object: at, name: 'translation_request_raw_data', label: 'Translation Request Raw Data', field_type_object: ft, optional: false
    create_field_instance annotation_type_object: at, name: 'translation_request_type', label: 'Translation Request Type', field_type_object: ft, optional: false
  end
end
