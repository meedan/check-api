class CreateUrlTaskType < ActiveRecord::Migration[5.2]
  require 'sample_data'
  include SampleData

  def change
    url = create_field_type field_type: 'url', label: 'URL'
    json = DynamicAnnotation::FieldType.where(field_type: 'json').last || create_field_type(field_type: 'json', label: 'JSON')
    at = create_annotation_type annotation_type: 'task_response_url', label: 'Task Response URL'
    create_field_instance annotation_type_object: at, name: 'response_url', label: 'Response', field_type_object: url, optional: true
    create_field_instance annotation_type_object: at, name: 'suggestion_url', label: 'Suggestion', field_type_object: json, optional: true
    create_field_instance annotation_type_object: at, name: 'review_url', label: 'Review', field_type_object: json, optional: true
  end
end
