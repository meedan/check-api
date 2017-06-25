require_relative '../test_helper'

class DynamicAnnotationIntegrationTest < ActionDispatch::IntegrationTest
  test "should create task response free text" do
    assert_nothing_raised do
      at = create_annotation_type annotation_type: 'task_response_free_text', label: 'Task Response Free Text', description: 'Free text response that can added to a task'
      ft = create_field_type field_type: 'text_field', label: 'Text Field', description: 'A text field'
      fi1 = create_field_instance name: 'response', label: 'Response', description: 'The response to a task', field_type_object: ft, optional: false, settings: {}
      fi2 = create_field_instance name: 'note', label: 'Note', description: 'A note that explains a response to a task', field_type_object: ft, optional: true, settings: {}
      a = create_dynamic_annotation annotation_type: 'task_response_free_text'
      f1 = create_field annotation_id: a.id, field_name: 'response', value: 'This is a response to a task'
      f2 = create_field annotation_id: a.id, field_name: 'note', value: 'This is a note to a task'
    end
  end
end
