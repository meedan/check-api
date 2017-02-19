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
    create_annotation_type annotation_type: 'test'
    a = create_dynamic_annotation annotation_type: 'test'
    a = Annotation.find(a.id)
    assert_equal 'Dynamic', a.load.class.name
  end

  test "should not create annotation if annotation type does not exist" do
    u = create_user
    pm = create_project_media
    assert_no_difference 'Annotation.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_dynamic_annotation annotation_type: 'test', skip_create_annotation_type: true, annotator: u, annotated: pm
      end
    end
    assert_difference 'Annotation.count' do
      create_dynamic_annotation annotation_type: 'test', annotator: u, annotated: pm
    end
  end

  test "should create fields" do
    at = create_annotation_type annotation_type: 'location', label: 'Location', description: 'Where this media happened'
    ft1 = create_field_type field_type: 'text_field', label: 'Text Field', description: 'A text field'
    ft2 = create_field_type field_type: 'location', label: 'Location', description: 'A pair of coordinates (lat, lon)'
    fi1 = create_field_instance name: 'location_position', label: 'Location position', description: 'Where this happened', field_type_object: ft2, optional: false, settings: { view_mode: 'map' }
    fi2 = create_field_instance name: 'location_name', label: 'Location name', description: 'Name of the location', field_type_object: ft1, optional: false, settings: {}
    pm = create_project_media
    assert_difference 'DynamicAnnotation::Field.count', 2 do
      create_dynamic_annotation annotation_type: 'location', annotator: pm.user, annotated: pm, set_fields: { location_name: 'Salvador', location_position: '3,-51' }.to_json
    end
  end

  test "should make sure that mandatory fields are set" do
    at = create_annotation_type annotation_type: 'location', label: 'Location', description: 'Where this media happened'
    ft1 = create_field_type field_type: 'text_field', label: 'Text Field', description: 'A text field'
    ft2 = create_field_type field_type: 'location', label: 'Location', description: 'A pair of coordinates (lat, lon)'
    fi1 = create_field_instance annotation_type_object: at, name: 'location_position', label: 'Location position', description: 'Where this happened', field_type_object: ft2, optional: false, settings: { view_mode: 'map' }
    fi2 = create_field_instance annotation_type_object: at, name: 'location_name', label: 'Location name', description: 'Name of the location', field_type_object: ft1, optional: true, settings: {}
    pm = create_project_media
    assert_no_difference 'DynamicAnnotation::Field.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_dynamic_annotation annotation_type: 'location', annotator: pm.user, annotated: pm, set_fields: { location_name: 'Salvador' }.to_json
      end
    end
    assert_difference 'DynamicAnnotation::Field.count' do
      create_dynamic_annotation annotation_type: 'location', annotator: pm.user, annotated: pm, set_fields: { location_position: '1,2' }.to_json
    end
  end

  test "should delete fields when dynamic is deleted" do
    t = create_task
    at = create_annotation_type annotation_type: 'response'
    ft1 = create_field_type field_type: 'task_reference'
    ft2 = create_field_type field_type: 'text'
    create_field_instance annotation_type_object: at, field_type_object: ft1, name: 'task'
    create_field_instance annotation_type_object: at, field_type_object: ft2, name: 'response'
    Dynamic.delete_all
    DynamicAnnotation::Field.delete_all
    t.response = { annotation_type: 'response', set_fields: { response: 'Test', task: t.id.to_s }.to_json }.to_json
    t.save!

    assert_equal 2, DynamicAnnotation::Field.count
    assert_equal 1, Dynamic.count
    Dynamic.last.destroy
    assert_equal 0, Dynamic.count
    assert_equal 0, DynamicAnnotation::Field.count
  end

  test "should delete fields when annotation is deleted" do
    t = create_task
    at = create_annotation_type annotation_type: 'response'
    ft1 = create_field_type field_type: 'task_reference'
    ft2 = create_field_type field_type: 'text'
    create_field_instance annotation_type_object: at, field_type_object: ft1, name: 'task'
    create_field_instance annotation_type_object: at, field_type_object: ft2, name: 'response'
    Dynamic.delete_all
    DynamicAnnotation::Field.delete_all
    t.response = { annotation_type: 'response', set_fields: { response: 'Test', task: t.id.to_s }.to_json }.to_json
    t.save!

    assert_equal 2, DynamicAnnotation::Field.count
    assert_equal 1, Dynamic.count
    Annotation.last.destroy
    assert_equal 0, Dynamic.count
    assert_equal 0, DynamicAnnotation::Field.count
  end
end
