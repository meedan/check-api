require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class DynamicTest < ActiveSupport::TestCase
  def setup
    require 'sidekiq/testing'
    Sidekiq::Testing.inline!
    super
  end

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

  test "should update fields" do
    at = create_annotation_type annotation_type: 'location', label: 'Location', description: 'Where this media happened'
    ft1 = create_field_type field_type: 'text_field', label: 'Text Field', description: 'A text field'
    ft2 = create_field_type field_type: 'location', label: 'Location', description: 'A pair of coordinates (lat, lon)'
    fi1 = create_field_instance name: 'location_position', label: 'Location position', description: 'Where this happened', field_type_object: ft2, optional: false, settings: { view_mode: 'map' }
    fi2 = create_field_instance name: 'location_name', label: 'Location name', description: 'Name of the location', field_type_object: ft1, optional: false, settings: {}
    pm = create_project_media
    a = create_dynamic_annotation annotation_type: 'location', annotator: pm.user, annotated: pm, set_fields: { location_name: 'Salvador', location_position: '3,-51' }.to_json
    f = DynamicAnnotation::Field.where(field_name: 'location_name').last
    assert_equal 'Salvador', f.value
    assert_equal '3,-51', DynamicAnnotation::Field.where(field_name: 'location_position').last.value
    a = a.reload

    assert_no_difference 'DynamicAnnotation::Field.count' do
      a.set_fields = { location_name: 'San Francisco' }.to_json
      a.save!
    end

    assert_equal 'San Francisco', f.reload.value
  end

  test "should set annotator on update" do
    u1 = create_user
    u2 = create_user
    u3 = create_user
    t = create_team
    create_team_user team: t, user: u1
    create_team_user team: t, user: u2
    create_team_user team: t, user: u3
    p = create_project team: t
    pm1 = create_project_media project: p
    pm2 = create_project_media project: p
    at = create_annotation_type
    User.current = u1
    d1 = create_dynamic_annotation annotator: u3, annotated: pm1, annotation_type: at.annotation_type
    assert_equal u1, d1.reload.annotator
    User.current = u2
    d2 = Dynamic.last
    d2.annotated = pm2
    d2.save!
    assert_equal u2, d2.reload.annotator
    User.current = nil
  end

  test "should get field" do
    at = create_annotation_type annotation_type: 'test'
    ft = create_field_type
    fi = create_field_instance name: 'test', field_type_object: ft, annotation_type_object: at
    a = create_dynamic_annotation annotation_type: 'test', set_fields: { test: 'Test' }.to_json
    assert_kind_of DynamicAnnotation::Field, a.get_field('test')
    assert_nil a.get_field('test2')
  end

  test "should get field value" do
    at = create_annotation_type annotation_type: 'test'
    ft = create_field_type
    fi = create_field_instance name: 'test', field_type_object: ft, annotation_type_object: at
    a = create_dynamic_annotation annotation_type: 'test', set_fields: { test: 'Test' }.to_json
    assert_equal 'Test', a.get_field_value('test')
    assert_nil a.get_field_value('test2')
  end

  test "should have Slack message for translation status" do
    DynamicAnnotation::AnnotationType.delete_all
    at = create_annotation_type annotation_type: 'translation_status'
    create_field_instance annotation_type_object: at, name: 'translation_status_status', label: 'Translation Status', optional: false, settings: { options_and_roles: { pending: 'contributor', in_progress: 'contributor', translated: 'contributor', ready: 'editor', error: 'editor' } }
    d = create_dynamic_annotation annotation_type: 'translation_status', set_fields: { translation_status_status: 'pending' }.to_json
    d = Dynamic.find(d.id)
    d.set_fields = { translation_status_status: 'ready' }.to_json
    d.save!
    u = create_user
    t = create_team
    with_current_user_and_team(u, t) do
      assert_kind_of String, d.slack_notification_message
    end
  end

  test "should store previous translation status" do
    DynamicAnnotation::AnnotationType.delete_all
    at = create_annotation_type annotation_type: 'translation_status'
    create_field_instance annotation_type_object: at, name: 'translation_status_status', label: 'Translation Status', optional: false, settings: { options_and_roles: { pending: 'contributor', in_progress: 'contributor', translated: 'contributor', ready: 'editor', error: 'editor' } }
    d = create_dynamic_annotation annotation_type: 'translation_status', set_fields: { translation_status_status: 'pending' }.to_json
    assert_equal 'Pending', d.translation_status
    d = Dynamic.find(d.id)
    d.set_fields = { translation_status_status: 'translated' }.to_json
    d.save!
    assert_equal 'Pending', d.previous_translation_status
    assert_equal 'Translated', d.translation_status
  end

  test "should not notify embed system if type is not translation" do
    at = create_annotation_type annotation_type: 'translation'
    create_field_instance annotation_type_object: at, name: 'translation_text'
    Dynamic.any_instance.stubs(:notify_embed_system).never
    d = create_dynamic_annotation
    Dynamic.any_instance.unstub(:notify_embed_system)
  end

  test "should notify embed system when translation is created" do
    pm = create_project_media
    at = create_annotation_type annotation_type: 'translation'
    create_field_instance annotation_type_object: at, name: 'translation_text'
    Dynamic.any_instance.stubs(:notify_embed_system).with('created', { id: pm.id.to_s}).once
    d = create_dynamic_annotation annotation_type: 'translation', annotated: pm
    Dynamic.any_instance.unstub(:notify_embed_system)
  end

  test "should notify embed system when translation is updated" do
    pm = create_project_media
    at = create_annotation_type annotation_type: 'translation'
    create_field_instance annotation_type_object: at, name: 'translation_text'
    d = create_dynamic_annotation annotation_type: 'translation', annotated: pm
    d.set_fields = { translation_text: 'translated' }.to_json
    Dynamic.any_instance.stubs(:notify_embed_system).with('updated', { id: pm.id.to_s}).once
    d.save!
    Dynamic.any_instance.unstub(:notify_embed_system)
  end

  test "should notify embed system when translation is destroyed" do
    pm = create_project_media
    at = create_annotation_type annotation_type: 'translation'
    create_field_instance annotation_type_object: at, name: 'translation_text'
    d = create_dynamic_annotation annotation_type: 'translation', annotated: pm
    Dynamic.any_instance.stubs(:notify_embed_system).with('destroyed', nil).once
    d.destroy
    Dynamic.any_instance.unstub(:notify_embed_system)
  end

end
