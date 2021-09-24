class CreateTranslationAnnotations < ActiveRecord::Migration[4.2]
  require 'sample_data'
  include SampleData

  def change
    ft = DynamicAnnotation::FieldType.where(field_type: 'text').last || create_field_type(field_type: 'text', label: 'Text')
    lt = create_field_type(field_type: 'language', label: 'Language')
    at = create_annotation_type annotation_type: 'translation', label: 'Translation'
    create_field_instance annotation_type_object: at, name: 'translation_text', label: 'Translation Text', field_type_object: ft, optional: false
    create_field_instance annotation_type_object: at, name: 'translation_note', label: 'Translation Note', field_type_object: ft, optional: true
    create_field_instance annotation_type_object: at, name: 'translation_language', label: 'Translation Language', field_type_object: lt, optional: false
  end
end
