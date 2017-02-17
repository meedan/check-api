class CreateResponseAnnotations < ActiveRecord::Migration
  require 'sample_data'
  include SampleData

  def change
    return if Rails.env.test?
    taskref = create_field_type field_type: 'task_reference', label: 'Task Reference'
    text = create_field_type field_type: 'text', label: 'Text'
    yn = create_field_type field_type: 'yes_no', label: 'Yes / No'
    sel = create_field_type field_type: 'select', label: 'Select'
    
    at = create_annotation_type annotation_type: 'task_response_free_text', label: 'Task Response Free Text'
    create_field_instance annotation_type_object: at, name: 'response_text', label: 'Response', field_type_object: text, optional: false
    create_field_instance annotation_type_object: at, name: 'note_text', label: 'Note', field_type_object: text, optional: true
    create_field_instance annotation_type_object: at, name: 'task_text', label: 'Task', field_type_object: taskref, optional: false

    at = create_annotation_type annotation_type: 'task_response_yes_no', label: 'Task Response Yes No'
    create_field_instance annotation_type_object: at, name: 'response_yes_no', label: 'Response', field_type_object: yn, optional: false
    create_field_instance annotation_type_object: at, name: 'note_yes_no', label: 'Note', field_type_object: text, optional: true
    create_field_instance annotation_type_object: at, name: 'task_yes_no', label: 'Task', field_type_object: taskref, optional: false

    at = create_annotation_type annotation_type: 'task_response_single_choice', label: 'Task Response Single Choice'
    create_field_instance annotation_type_object: at, name: 'response_single', label: 'Response', field_type_object: sel, optional: false, settings: { multiple: false }
    create_field_instance annotation_type_object: at, name: 'note_single', label: 'Note', field_type_object: text, optional: true
    create_field_instance annotation_type_object: at, name: 'task_single', label: 'Task', field_type_object: taskref, optional: false

    at = create_annotation_type annotation_type: 'task_response_multi_choice', label: 'Task Response Multi Choice'
    create_field_instance annotation_type_object: at, name: 'response_multi', label: 'Response', field_type_object: sel, optional: false, settings: { multiple: true }
    create_field_instance annotation_type_object: at, name: 'note_multi', label: 'Note', field_type_object: text, optional: true
    create_field_instance annotation_type_object: at, name: 'task_multi', label: 'Task', field_type_object: taskref, optional: false

    # How to create fields:
    # a = create_dynamic_annotation annotation_type: 'task_response_free_text'
    # create_field annotation_id: a.id, field_name: 'response', value: 'This is a response to a task'
    # create_field annotation_id: a.id, field_name: 'note', value: 'This is a note to a task'
    # create_field annotation_id: a.id, field_name: 'task', value: Task.last.id
  end
end
