class CreateMachineTranslationDynamicAnnotation < ActiveRecord::Migration[4.2]
  require 'sample_data'
  include SampleData

  def change
    ft = create_field_type(field_type: 'json', label: 'JSON structure')
    at = create_annotation_type annotation_type: 'mt', label: 'Machine translation'
    create_field_instance annotation_type_object: at, name: 'mt_translations', label: 'Machine translations', field_type_object: ft, optional: false
  end
end
