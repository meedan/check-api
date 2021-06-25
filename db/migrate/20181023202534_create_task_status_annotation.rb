class CreateTaskStatusAnnotation < ActiveRecord::Migration[4.2]
  require 'sample_data'
  include SampleData

  def change
    ft = DynamicAnnotation::FieldType.where(field_type: 'select').last || create_field_type(field_type: 'select', label: 'Select')
    at = create_annotation_type annotation_type: 'task_status', label: 'Task Status'
    create_field_instance annotation_type_object: at, name: 'task_status_status', label: 'Task Status', field_type_object: ft, optional: true
  end
end
