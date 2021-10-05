class AddTranslationPublishedFields < ActiveRecord::Migration[4.2]
  require 'sample_data'
  include SampleData

  def change
    at = DynamicAnnotation::AnnotationType.where(annotation_type: 'translation').last
    ft = DynamicAnnotation::FieldType.where(field_type: 'json').last || create_field_type(field_type: 'json', label: 'JSON')
    create_field_instance annotation_type_object: at, name: 'translation_published', label: 'Translation Published', field_type_object: ft, optional: true
  end
end
