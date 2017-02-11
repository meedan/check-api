require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class DynamicTest < ActiveSupport::TestCase
  test "should create dynamic annotation" do
    u = create_user
    pm = create_project_media
    assert_difference 'Annotation.count' do
      create_dynamic_annotation annotator: u, annotated: pm
    end
  end

  test "should belong to annotation type" do
    at = create_annotation_type annotation_type: 'task_response_free_text'
    a = create_dynamic_annotation annotation_type: 'task_response_free_text'
    assert_equal at, a.reload.annotation_type_object
  end

  test "should have many fields" do
    a = create_dynamic_annotation
    f1 = create_field annotation_id: a.id
    f2 = create_field annotation_id: a.id
    assert_equal [f1, f2], a.reload.fields
  end

  test "should load" do
    a = create_dynamic_annotation annotation_type: 'test'
    a = Annotation.find(a.id)
    assert_equal 'Dynamic', a.load.class.name
  end
end
