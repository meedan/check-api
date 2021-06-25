class CreateGeolocationTask < ActiveRecord::Migration[4.2]
  require 'sample_data'
  include SampleData

  def change
    taskref = DynamicAnnotation::FieldType.where(field_type: 'task_reference').last ||
              create_field_type(field_type: 'task_reference', label: 'Task Reference')
    geo = create_field_type field_type: 'geojson', label: 'GeoJSON'
    
    at = create_annotation_type annotation_type: 'task_response_geolocation', label: 'Task Response Geolocation'
    create_field_instance annotation_type_object: at, name: 'response_geolocation', label: 'Response', field_type_object: geo, optional: true
    create_field_instance annotation_type_object: at, name: 'task_geolocation', label: 'Task', field_type_object: taskref, optional: false
  end
end
