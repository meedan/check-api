require_relative '../test_helper'

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
    assert_equal [f1, f2].sort, a.reload.fields.to_a.sort
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
    ft2 = create_field_type field_type: 'text'
    create_field_instance annotation_type_object: at, field_type_object: ft2, name: 'response'
    Dynamic.delete_all
    DynamicAnnotation::Field.delete_all
    t.disable_es_callbacks = true
    t.response = { annotation_type: 'response', set_fields: { response: 'Test' }.to_json }.to_json
    t.save!

    assert_equal 1, DynamicAnnotation::Field.count
    assert_equal 1, Dynamic.count
    d = Dynamic.last
    d.disable_es_callbacks = true
    d.destroy
    assert_equal 0, Dynamic.count
    assert_equal 0, DynamicAnnotation::Field.count
  end

  test "should delete fields when annotation is deleted" do
    t = create_task
    at = create_annotation_type annotation_type: 'response'
    ft2 = create_field_type field_type: 'text'
    create_field_instance annotation_type_object: at, field_type_object: ft2, name: 'response'
    Dynamic.delete_all
    DynamicAnnotation::Field.delete_all
    t.disable_es_callbacks = true
    t.response = { annotation_type: 'response', set_fields: { response: 'Test' }.to_json }.to_json
    t.save!

    assert_equal 1, DynamicAnnotation::Field.count
    assert_equal 1, Dynamic.count
    a = Annotation.last
    a.disable_es_callbacks = true
    a.destroy
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
    u1 = User.find(u1.id)
    u2 = User.find(u2.id)
    u3 = User.find(u3.id)
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

  test "should have Slack message for verification status" do
    u = create_user
    t = create_team
    DynamicAnnotation::AnnotationType.delete_all
    create_verification_status_stuff
    d = create_dynamic_annotation annotator: u, annotation_type: 'verification_status', set_fields: { verification_status_status: 'undetermined' }.to_json
    d = Dynamic.find(d.id)
    d.set_fields = { verification_status_status: 'verified' }.to_json
    d.disable_es_callbacks = true
    d.save!
    with_current_user_and_team(u, t) do
      assert_match /verification status/, d.slack_notification_message[:pretext]
    end
  end

  test "should store previous verification status" do
    DynamicAnnotation::AnnotationType.delete_all
    create_verification_status_stuff
    d = create_dynamic_annotation annotation_type: 'verification_status', set_fields: { verification_status_status: 'undetermined' }.to_json
    assert_equal 'Unstarted', d.verification_status
    d = Dynamic.find(d.id)
    d.set_fields = { verification_status_status: 'verified' }.to_json
    d.disable_es_callbacks = true
    d.save!
    assert_equal 'Unstarted', d.previous_verification_status
    assert_equal 'Verified', d.verification_status
  end

  test "should ignore fields that do not exist" do
    at = create_annotation_type annotation_type: 'test'
    ft = create_field_type
    fi = create_field_instance name: 'test', field_type_object: ft, annotation_type_object: at
    a = create_dynamic_annotation annotation_type: 'test', set_fields: { test: 'Test', test2: 'Test 2' }.to_json
    assert_kind_of DynamicAnnotation::Field, a.get_field('test')
    assert_nil a.get_field('test2')
  end

  test "should set attribution" do
    assert_task_response_attribution
  end

  test "should not assign to attribution users that are not in the team" do
    u1 = create_user
    u2 = create_user
    u3 = create_user
    u4 = create_user
    u5 = create_user is_admin: true
    t = create_team
    create_team_user team: t, user: u1
    create_team_user team: t, user: u2
    create_team_user team: t, user: u3, status: 'requested'
    p = create_project team: t
    pm = create_project_media project: p
    at = create_annotation_type annotation_type: 'task_response_foo_bar'
    d = create_dynamic_annotation annotated: pm, annotation_type: 'task_response_foo_bar'
    assert_nothing_raised do
      d.set_attribution = [u1.id, u2.id].join(',')
      d.save!
    end
    assert_raises ActiveRecord::RecordInvalid do
      d.set_attribution = [u1.id, u2.id, u3.id].join(',')
      d.save!
    end
    assert_raises ActiveRecord::RecordInvalid do
      d.set_attribution = [u1.id, u2.id, u4.id].join(',')
      d.save!
    end
    assert_nothing_raised do
      d.set_attribution = [u1.id, u5.id].join(',')
      d.save!
    end
  end

  test "should not edit same instance concurrently" do
    s = create_source
    a = create_dynamic_annotation annotation_type: 'metadata', annotated: s
    assert_equal 0, a.lock_version
    assert_nothing_raised do
      a.updated_at = Time.now + 1
      a.save!
    end
    assert_equal 1, a.reload.lock_version
    assert_raises ActiveRecord::StaleObjectError do
      a.lock_version = 0
      a.updated_at = Time.now + 2
      a.save!
    end

    create_annotation_type annotation_type: 'notmetadata'
    a = create_dynamic_annotation annotation_type: 'notmetadata'
    assert_equal 0, a.lock_version
    assert_nothing_raised do
      a.updated_at = Time.now + 1
      a.save!
    end
    assert_equal 0, a.reload.lock_version
    assert_nothing_raised do
      a.lock_version = 0
      a.updated_at = Time.now + 2
      a.save!
    end
  end

  test "should check if field response datetime exist before get field" do
    u = create_user
    pm = create_project_media

    d = create_dynamic_annotation annotation_type: 'task_response_datetime', annotator: u, annotated: pm
    assert d.get_field(:response_datetime).nil?
    assert_nothing_raised do
      d.send(:add_update_elasticsearch_dynamic_annotation_task_response_datetime)
    end
  end

  test "should save report design image in a path" do
    create_report_design_annotation_type
    d = create_dynamic_annotation annotation_type: 'report_design', file: 'rails.png', set_fields: { image: '' }.to_json, action: 'save'
    assert_not_nil d.file
    assert_match /rails.png/, d.reload.get_field_value('image')
    d.set_fields = { image: 'http://imgur.com/test.png' }.to_json
    d.save!
    d = Dynamic.find(d.id)
    assert_equal 'http://imgur.com/test.png', d.get_field_value('image')
  end

  test "should not crash if introduction is null" do
    create_report_design_annotation_type
    d = create_dynamic_annotation annotation_type: 'report_design', set_fields: {}.to_json
    assert_equal '', d.report_design_introduction({ 'text' => random_string })
  end

  test "should not send report for secondary item if primary does not have a report" do
    create_report_design_annotation_type
    pm = create_project_media
    d = create_dynamic_annotation annotated: pm, annotation_type: 'report_design', set_fields: {}.to_json
    d.destroy!
    assert_nothing_raised do
      Bot::Smooch.send_report_to_users(pm, 'publish')
    end
  end
end
