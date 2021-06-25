class AddTranslationRequestIdDynamicField < ActiveRecord::Migration[4.2]
  require 'sample_data'
  include SampleData

  def change
    at = DynamicAnnotation::AnnotationType.where(annotation_type: 'translation_request').last
    ft = DynamicAnnotation::FieldType.where(field_type: 'id').last || create_field_type(field_type: 'id', label: 'ID')
    create_field_instance annotation_type_object: at, name: 'translation_request_id', label: 'Translation Request Id', field_type_object: ft, optional: false
  end
end
