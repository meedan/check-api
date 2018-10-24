require_relative '../test_helper'

class TaskTest < ActiveSupport::TestCase
  def setup
    super
    require 'sidekiq/testing'
    Sidekiq::Testing.inline!
    create_task_status_stuff
  end

  test "should create task" do
    t = nil
    assert_difference 'Task.length' do
      t = create_task
    end
    assert_not_nil t.jsonoptions
    assert_not_nil t.content
  end

  test "should not create task with blank label" do
    assert_no_difference 'Task.length' do
      assert_raises ActiveRecord::RecordInvalid do
        create_task label: nil
      end
    end
  end

  test "should not create task with invalid type" do
    assert_no_difference 'Task.length' do
      assert_raises ActiveRecord::RecordInvalid do
        create_task type: 'invalid'
      end
    end
  end

  test "should create task without description" do
    assert_difference 'Task.length' do
      create_task description: nil
    end
  end

  test "should create task without options" do
    assert_difference 'Task.length' do
      create_task options: nil
    end
  end

  test "should not create task if options is not an array" do
    assert_no_difference 'Task.length' do
      assert_raises ActiveRecord::RecordInvalid do
        create_task options: {}
      end
    end
  end

  test "should parse JSON options" do
    t = Task.new
    t.jsonoptions = ['foo', 'bar'].to_json
    assert_equal ['foo', 'bar'], t.options
  end

  test "should set initial status" do
    t = create_task status: nil
    assert_equal 'Unresolved', t.reload.status
  end

  test "should add response to task" do
    t = create_task
    assert_equal 'Unresolved', t.reload.status
    at = create_annotation_type annotation_type: 'response'
    create_field_instance annotation_type_object: at, name: 'response_test'
    t.response = { annotation_type: 'response', set_fields: { response_test: 'test' }.to_json }.to_json
    t.save!
    assert_equal 'Resolved', t.reload.status
  end

  test "should get task responses" do
    t = create_task
    assert_equal [], t.responses
    at = create_annotation_type annotation_type: 'response'
    ft1 = create_field_type field_type: 'task_reference'
    ft2 = create_field_type field_type: 'text'
    assert_equal [], t.reload.responses
    create_field_instance annotation_type_object: at, field_type_object: ft1, name: 'task'
    create_field_instance annotation_type_object: at, field_type_object: ft2, name: 'response'
    t.disable_es_callbacks = true
    t.response = { annotation_type: 'response', set_fields: { response: 'Test', task: t.id.to_s }.to_json }.to_json
    t.save!
    assert_match /Test/, t.reload.responses.first.content.inspect
  end

  test "should delete responses when task is deleted" do
    t = create_task
    at = create_annotation_type annotation_type: 'response'
    ft1 = create_field_type field_type: 'task_reference'
    ft2 = create_field_type field_type: 'text'
    create_field_instance annotation_type_object: at, field_type_object: ft1, name: 'task'
    create_field_instance annotation_type_object: at, field_type_object: ft2, name: 'response'
    Dynamic.delete_all
    DynamicAnnotation::Field.delete_all
    t.disable_es_callbacks = true
    t.response = { annotation_type: 'response', set_fields: { response: 'Test', task: t.id.to_s }.to_json }.to_json
    t.save!

    assert_equal 2, DynamicAnnotation::Field.count
    assert_equal 1, Dynamic.count
    t.disable_es_callbacks = true
    t.destroy
    assert_equal 0, Dynamic.count
    assert_equal 0, DynamicAnnotation::Field.count
  end

  test "should notify on Slack when task is updated" do
    t = create_team slug: 'test'
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    t.set_slack_notifications_enabled = 1; t.set_slack_webhook = 'https://hooks.slack.com/services/123'; t.set_slack_channel = '#test'; t.save!
    pm = create_project_media project: p
    with_current_user_and_team(u, t) do
      tk = create_task annotator: u, annotated: pm
      tk.label = 'changed'
      tk.description = 'changed'
      tk.save!
      assert tk.sent_to_slack
    end
  end

  test "should notify on Slack when task is resolved" do
    t = create_team slug: 'test'
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    t.set_slack_notifications_enabled = 1; t.set_slack_webhook = 'https://hooks.slack.com/services/123'; t.set_slack_channel = '#test'; t.save!
    at = create_annotation_type annotation_type: 'task_response_free_text', label: 'Task'
    ft1 = create_field_type field_type: 'text_field', label: 'Text Field'
    ft2 = create_field_type field_type: 'task_reference', label: 'Task Reference'
    fi1 = create_field_instance annotation_type_object: at, name: 'response_task', label: 'Response', field_type_object: ft1
    fi2 = create_field_instance annotation_type_object: at, name: 'note_task', label: 'Note', field_type_object: ft1
    fi3 = create_field_instance annotation_type_object: at, name: 'task_reference', label: 'Task', field_type_object: ft2
    pm = create_project_media project: p

    with_current_user_and_team(u, t) do
      tk = create_task annotator: u, annotated: pm
      tk.disable_es_callbacks = true
      tk.response = { annotation_type: 'task_response_free_text', set_fields: { response_task: 'Foo', note_task: 'Bar', task_reference: tk.id.to_s }.to_json }.to_json
      tk.save!
      assert tk.response.sent_to_slack

      d = Dynamic.find(tk.response.id)
      d.set_fields = { response_task: 'Bar', note_task: 'Foo' }.to_json
      d.disable_es_callbacks = true
      d.save!
      assert d.sent_to_slack
    end
  end

  test "should notify on Slack when task is created" do
    t = create_team slug: 'test'
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    t.set_slack_notifications_enabled = 1; t.set_slack_webhook = 'https://hooks.slack.com/services/123'; t.set_slack_channel = '#test'; t.save!
    pm = create_project_media project: p
    with_current_user_and_team(u, t) do
      tk = create_task annotator: u, annotated: pm
      assert tk.sent_to_slack
    end
  end

  test "should get first response from task" do
    at = create_annotation_type annotation_type: 'task_response_free_text', label: 'Task'
    ft1 = create_field_type field_type: 'text_field', label: 'Text Field'
    ft2 = create_field_type field_type: 'task_reference', label: 'Task Reference'
    fi1 = create_field_instance annotation_type_object: at, name: 'response_task', label: 'Response', field_type_object: ft1
    fi2 = create_field_instance annotation_type_object: at, name: 'note_task', label: 'Note', field_type_object: ft1
    fi3 = create_field_instance annotation_type_object: at, name: 'task_reference', label: 'Task', field_type_object: ft2

    t = create_task
    assert_nil t.first_response

    t.disable_es_callbacks = true
    t.response = { annotation_type: 'task_response_free_text', set_fields: { response_task: 'Test', task_reference: t.id.to_s }.to_json }.to_json
    t.save!

    t = Task.find(t.id)
    assert_equal 'Test', t.first_response
  end

  test "should set slug when task is created" do
    t = create_task label: 'Where did it happen?'
    assert_equal 'where_did_it_happen', t.slug
  end

  test "should send Slack notification in background" do
    Bot::Slack.any_instance.stubs(:bot_send_slack_notification).returns(nil)
    t = create_team slug: 'test'
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    t.set_slack_notifications_enabled = 1; t.set_slack_webhook = 'https://hooks.slack.com/services/123'; t.set_slack_channel = '#test'; t.save!
    pm = create_project_media project: p
    with_current_user_and_team(u, t) do
      tk = create_task annotator: u, annotated: pm
      tk = Task.find(tk.id)
      tk.data = { label: 'Foo', type: 'free_text' }.with_indifferent_access
      tk.save!
    end
    Bot::Slack.any_instance.unstub(:bot_send_slack_notification)
  end

  test "should load task" do
    t = create_task
    assert_equal t, t.task
  end

  test "should have cached log count" do
    t = create_task
    assert_nil t.log_count
    c = create_comment annotated: t
    assert_equal 1, t.reload.log_count
    create_comment annotated: t
    assert_equal 2, t.reload.log_count
    c.destroy
    assert_equal 1, t.reload.log_count
  end

  test "should have log" do
    u = create_user is_admin: true
    t = create_team
    with_current_user_and_team(u, t) do
      tk = create_task
      assert_equal 0, tk.reload.log.count
      create_comment annotated: tk
      assert_equal 1, tk.reload.log.count
      create_comment annotated: tk
      assert_equal 2, tk.reload.log.count
    end
  end

  test "should update parent log count when comment is added to task" do
    u = create_user is_admin: true
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p
    tk = create_task annotated: pm
    with_current_user_and_team(u, t) do
      assert_equal 0, pm.reload.cached_annotations_count
      create_comment annotated: tk
      assert_equal 2, pm.reload.cached_annotations_count
      c = create_comment annotated: tk
      assert_equal 4, pm.reload.cached_annotations_count
    end
  end

  test "should save comment in version" do
    u = create_user is_admin: true
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p
    with_current_user_and_team(u, t) do
      tk = create_task annotated: pm
      c = create_comment annotated: tk, text: 'Foo Bar'
      meta = pm.reload.get_versions_log.where(event_type: 'update_task').last.meta
      assert_equal 'Foo Bar', JSON.parse(meta)['data']['text']
    end
  end

  test "should not answer task if is a bot" do
    text = create_field_type field_type: 'text', label: 'Text'
    at = create_annotation_type annotation_type: 'task_response_free_text', label: 'Task Response Free Text'
    create_field_instance annotation_type_object: at, name: 'response_free_text', label: 'Response', field_type_object: text, optional: false

    e = assert_raises ActiveRecord::RecordInvalid do
      User.current = create_bot_user(is_admin: true)
      t = create_task
      t.response = { annotation_type: 'task_response_free_text', set_fields: { response_free_text: 'Test' }.to_json }.to_json
      t.save!
    end
    assert_equal "Validation failed: #{I18n.t('bot_cant_add_response_to_task')}", e.message

    assert_nothing_raised do
      User.current = create_user(is_admin: true)
      t = create_task
      t.response = { annotation_type: 'task_response_free_text', set_fields: { response_free_text: 'Test' }.to_json }.to_json
      t.save!
    end

    User.current = nil
  end

  test "should accept suggestion from bot" do
    text = create_field_type field_type: 'text', label: 'Text'
    json = create_field_type field_type: 'json', label: 'JSON'
    task = create_field_type field_type: 'task_reference', label: 'Task Reference'
    at = create_annotation_type annotation_type: 'task_response_free_text', label: 'Task Response Free Text'
    create_field_instance annotation_type_object: at, name: 'review_free_text', label: 'Review', field_type_object: json, optional: true
    create_field_instance annotation_type_object: at, name: 'response_free_text', label: 'Response', field_type_object: text, optional: false
    create_field_instance annotation_type_object: at, name: 'suggestion_free_text', label: 'Suggestion', field_type_object: json, optional: true
    create_field_instance annotation_type_object: at, name: 'task_free_text', label: 'Task', field_type_object: task, optional: false

    tb = create_team_bot
    t = create_task type: 'free_text'
    assert_raises ActiveRecord::RecordInvalid do
      t.response = { annotation_type: 'task_response_free_text', set_fields: { response_free_text: '', task_free_text: t.id.to_s, suggestion_free_text: 'invalid' }.to_json }.to_json
    end
    t.response = { annotation_type: 'task_response_free_text', set_fields: { response_free_text: '', task_free_text: t.id.to_s, suggestion_free_text: { suggestion: 'Test', comment: 'Nothing' }.to_json }.to_json }.to_json
    t.save!
    assert_equal '', t.reload.first_response

    t = Task.where(id: t.id).last
    t.accept_suggestion = 0
    t.save!
    assert_equal 'Test', t.reload.first_response

    t = create_task type: 'free_text'
    t.response = { annotation_type: 'task_response_free_text', set_fields: { response_free_text: '', task_free_text: t.id.to_s, suggestion_free_text: { suggestion: 'Test', comment: 'Nothing' }.to_json }.to_json }.to_json
    t.save!
    assert_equal '', t.reload.first_response

    t = Task.where(id: t.id).last
    t.reject_suggestion = 0
    t.save!
    assert_equal '', t.reload.first_response

    u = create_user is_admin: true
    with_current_user_and_team(u, create_team) do
      t = create_task type: 'free_text'
      assert_nil t.reload.suggestions_count
      t.response = { annotation_type: 'task_response_free_text', set_fields: { response_free_text: '', task_free_text: t.id.to_s, suggestion_free_text: { suggestion: 'Test', comment: 'Nothing' }.to_json }.to_json }.to_json
      assert_equal 1, Task.find(t.id).suggestions_count
      f = t.responses.first.get_fields.select{ |f| f.field_name =~ /suggestion/ }.last
      assert_equal 'Task', f.versions.last.associated_type
      assert_equal t.id, f.versions.last.associated_id
    end
  end
end
