class CreateGeolocationTask < ActiveRecord::Migration
  require 'sample_data'
  include SampleData

  def change
    taskref = DynamicAnnotation::FieldType.where(field_type: 'task_reference').last ||
              create_field_type(field_type: 'task_reference', label: 'Task Reference')
    text = DynamicAnnotation::FieldType.where(field_type: 'text').last ||
           create_field_type(field_type: 'text', label: 'Text')
    geo = create_field_type field_type: 'geolocation', label: 'Geolocation'
    
    at = create_annotation_type annotation_type: 'task_response_geolocation', label: 'Task Response Geolocation'
    create_field_instance annotation_type_object: at, name: 'response_geolocation', label: 'Response', field_type_object: geo, optional: true
    create_field_instance annotation_type_object: at, name: 'note_geolocation', label: 'Note', field_type_object: text, optional: false
    create_field_instance annotation_type_object: at, name: 'task_geolocation', label: 'Task', field_type_object: taskref, optional: false
  end
end
