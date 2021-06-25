class AddFieldsToMemebusterAnnotation < ActiveRecord::Migration[4.2]
  require 'sample_data'
  include SampleData

  def change
    at = DynamicAnnotation::AnnotationType.where(annotation_type: 'memebuster').last
    ft = DynamicAnnotation::FieldType.where(field_type: 'text').last || create_field_type(field_type: 'text', label: 'Text')
    ft2 = DynamicAnnotation::FieldType.where(field_type: 'boolean').last || create_field_type(field_type: 'boolean', label: 'Boolean')
    create_field_instance annotation_type_object: at, name: 'memebuster_disclaimer', label: 'Memebuster Disclaimer', field_type_object: ft, optional: true
    create_field_instance annotation_type_object: at, name: 'memebuster_tasks', label: 'Memebuster Tasks', field_type_object: ft, optional: true
    create_field_instance annotation_type_object: at, name: 'memebuster_custom_url', label: 'Memebuster Custom URL', field_type_object: ft, optional: true
    create_field_instance annotation_type_object: at, name: 'memebuster_show_analysis', label: 'Memebuster Show Analysis', field_type_object: ft2, optional: true
  end
end
