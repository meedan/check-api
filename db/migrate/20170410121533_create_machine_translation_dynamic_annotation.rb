class CreateMachineTranslationDynamicAnnotation < ActiveRecord::Migration
  require 'sample_data'
  include SampleData

  def change
    ft = create_field_type(field_type: 'mt_text', label: 'Machine translation')
    at = create_annotation_type annotation_type: 'mt', label: 'Machine translation'
    create_field_instance annotation_type_object: at, name: 'mt_text', label: 'Machine translation', field_type_object: ft, optional: false
  end
end
