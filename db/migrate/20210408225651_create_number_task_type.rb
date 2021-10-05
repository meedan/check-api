class CreateNumberTaskType < ActiveRecord::Migration[4.2]
  require 'sample_data'
  include SampleData

  def change
    number = create_field_type field_type: 'number', label: 'Number'
    json = DynamicAnnotation::FieldType.where(field_type: 'json').last || create_field_type(field_type: 'json', label: 'JSON')
    at = create_annotation_type annotation_type: 'task_response_number', label: 'Task Response Number'
    create_field_instance annotation_type_object: at, name: 'response_number', label: 'Response', field_type_object: number, optional: true
    create_field_instance annotation_type_object: at, name: 'suggestion_number', label: 'Suggestion', field_type_object: json, optional: true
    create_field_instance annotation_type_object: at, name: 'review_number', label: 'Review', field_type_object: json, optional: true
  end
end
