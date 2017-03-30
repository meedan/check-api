require File.join(File.expand_path(File.dirname(__FILE__)), '..', '..', 'test_helper')

class DynamicAnnotation::FieldTest < ActiveSupport::TestCase
  test "should create field" do
    assert_difference 'DynamicAnnotation::Field.count' do
      create_field
    end
  end

  test "should set annotation type automatically" do
    at = create_annotation_type annotation_type: 'task_response_free_text'
    a = create_dynamic_annotation annotation_type: 'task_response_free_text' 
    f = create_field annotation_type: nil, annotation_id: a.id
    assert_equal 'task_response_free_text', f.reload.annotation_type
    assert_equal at, f.reload.annotation_type_object
  end

  test "should belong to annotation" do
    a = create_dynamic_annotation
    f = create_field annotation_id: a.id
    assert_equal a, f.reload.annotation
  end

  test "should belong to field instance" do
    fi = create_field_instance name: 'response'
    f = create_field field_name: 'response'
    assert_equal fi, f.reload.field_instance
  end

  test "should set field_type automatically" do
    ft = create_field_type field_type: 'text_field'
    fi = create_field_instance name: 'response', field_type_object: ft
    f = create_field field_name: 'response'
    assert_equal 'text_field', f.reload.field_type
    assert_equal ft, f.reload.field_type_object
  end

  test "should have value" do
    value = { lat: '-13.34', lon: '2.54' }
    f = create_field value: value
    assert_equal value, f.reload.value
  end

  test "should have versions" do
    ft = create_field_type field_type: 'text_field'
    fi = create_field_instance name: 'response', field_type_object: ft
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    pm = create_project_media project: p
    a = create_dynamic_annotation annotated: pm, annotator: u
    with_current_user_and_team(u, t) do
      assert_difference 'PaperTrail::Version.count' do
        create_field annotation_id: a.id, field_name: 'response'
      end
    end
  end

  test "should get string value" do
    ft = create_field_type field_type: 'text_field'
    fi = create_field_instance name: 'response', field_type_object: ft
    f = create_field field_name: 'response', value: '{"selected":["Hello","Aloha"],"other":null}'
    assert_equal 'Hello, Aloha', f.to_s
    f = create_field field_name: 'response', value: 'Test'
    assert_equal 'Test', f.to_s
  end
end
