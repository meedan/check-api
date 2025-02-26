require_relative '../test_helper'

class TaskTest < ActiveSupport::TestCase
  def setup
    super
    require 'sidekiq/testing'
    Sidekiq::Testing.inline!
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

  test "should add response to task" do
    t = create_task
    assert_equal 0, t.responses.count
    at = create_annotation_type annotation_type: 'task_response'
    create_field_instance annotation_type_object: at, name: 'response_test'
    t.response = { annotation_type: 'task_response', set_fields: { response_test: 'test' }.to_json }.to_json
    t.save!
    assert_equal 1, t.reload.responses.count
  end

  test "should get task responses" do
    t = create_task
    assert_equal [], t.responses
    at = create_annotation_type annotation_type: 'task_response'
    ft2 = create_field_type field_type: 'text'
    assert_equal [], t.reload.responses
    create_field_instance annotation_type_object: at, field_type_object: ft2, name: 'response'
    t.disable_es_callbacks = true
    t.response = { annotation_type: 'task_response', set_fields: { response: 'Test' }.to_json }.to_json
    t.save!
    assert_match /Test/, t.reload.responses.first.content.inspect
  end

  test "should delete responses when task is deleted" do
    at = create_annotation_type annotation_type: 'task_response'
    ft2 = create_field_type field_type: 'text'
    create_field_instance annotation_type_object: at, field_type_object: ft2, name: 'response'
    Dynamic.delete_all
    DynamicAnnotation::Field.delete_all
    t = create_task
    t.disable_es_callbacks = true
    t.response = { annotation_type: 'task_response', set_fields: { response: 'Test' }.to_json }.to_json
    t.save!
    r = t.responses.first
    assert_not_nil Annotation.where(id: r.id).last
    assert_equal 1, DynamicAnnotation::Field.where("annotation_type LIKE 'task_response%'").count
    assert_equal 1, Dynamic.where("annotation_type LIKE 'task_response%'").count
    t.disable_es_callbacks = true
    t.destroy
    assert_nil Annotation.where(id: r.id).last
    assert_equal 0, DynamicAnnotation::Field.where("annotation_type LIKE 'task_response%'").count
    assert_equal 0, Dynamic.where("annotation_type LIKE 'task_response%'").count
  end

  test "should set assigner when task assigned" do
    t = create_team slug: 'test'
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    p = create_project team: t
    pm = create_project_media project: p
    with_current_user_and_team(u, t) do
      tk = create_task annotator: u, annotated: pm
      u2 = create_user
      create_team_user user: u2, team: t
      tk.save!
      tk.assign_user(u2.id)
      a = tk.assignments.last
      assert_equal u.id, a.assigner_id
    end
  end

  test "should notify on Slack when task is updated" do
    t = create_team slug: 'test'
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    p = create_project team: t
    t.set_slack_notifications_enabled = 1
    t.set_slack_webhook = 'https://hooks.slack.com/services/123'
    slack_notifications = [{
      "label": random_string,
      "event_type": "any_activity",
      "slack_channel": "#test"
    }]
    t.slack_notifications = slack_notifications.to_json
    t.save!
    pm = create_project_media project: p
    with_current_user_and_team(u, t) do
      tk = create_task annotator: u, annotated: pm
      tk.label = 'changed'
      tk.description = 'changed'
      tk.save!
      assert tk.sent_to_slack

      tk = Task.find(tk.id)
      tg = create_tag annotated: tk
      assert_not tk.sent_to_slack
      assert !tg.sent_to_slack
    end
  end

  test "should notify on Slack when task is resolved" do
    create_annotation_type_and_fields('Slack Message', { 'Data' => ['JSON', false] })
    t = create_team slug: 'test'
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    p = create_project team: t
    t.set_slack_notifications_enabled = 1
    t.set_slack_webhook = 'https://hooks.slack.com/services/123'
    slack_notifications = [{
      "label": random_string,
      "event_type": "any_activity",
      "slack_channel": "#test"
    }]
    t.slack_notifications = slack_notifications.to_json
    t.save!
    at = create_annotation_type annotation_type: 'task_response_free_text', label: 'Task'
    ft1 = create_field_type field_type: 'text_field', label: 'Text Field'
    fi1 = create_field_instance annotation_type_object: at, name: 'response_task', label: 'Response', field_type_object: ft1
    pm = create_project_media project: p
    pm2 = create_project_media project: p
    tk2 = create_task annotator: u, annotated: pm2
    pm3 = create_project_media project: p
    tk3 = create_task annotator: u, annotated: pm3
    tk3.response = { annotation_type: 'task_response_free_text', set_fields: { response_task: 'Foo' }.to_json }.to_json
    tk3.save!

    with_current_user_and_team(u, t) do
      tk = create_task annotator: u, annotated: pm
      assert tk.sent_to_slack
      create_dynamic_annotation annotated: pm, annotation_type: 'slack_message'

      tk.disable_es_callbacks = true
      tk.response = { annotation_type: 'task_response_free_text', set_fields: { response_task: 'Foo' }.to_json }.to_json
      tk.save!
      assert !tk.response.sent_to_slack
      tk2.response = { annotation_type: 'task_response_free_text', set_fields: { response_task: 'Foo' }.to_json }.to_json
      tk2.save!
      assert tk2.response.sent_to_slack

      d = Dynamic.find(tk.response.id)
      d.set_fields = { response_task: 'Bar' }.to_json
      d.disable_es_callbacks = true
      d.save!
      assert !d.sent_to_slack

      d = Dynamic.find(tk3.response.id)
      d.set_fields = { response_task: 'Bar' }.to_json
      d.disable_es_callbacks = true
      d.save!
      assert d.sent_to_slack
    end
  end

  test "should notify on Slack when task is created" do
    t = create_team slug: 'test'
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    p = create_project team: t
    t.set_slack_notifications_enabled = 1
    t.set_slack_webhook = 'https://hooks.slack.com/services/123'
    slack_notifications = [{
      "label": random_string,
      "event_type": "any_activity",
      "slack_channel": "#test"
    }]
    t.slack_notifications = slack_notifications.to_json
    t.save!
    pm = create_project_media project: p
    with_current_user_and_team(u, t) do
      tk = create_task annotator: u, annotated: pm
      assert tk.sent_to_slack
    end
  end

  test "should get first response from task" do
    at = create_annotation_type annotation_type: 'task_response_free_text', label: 'Task'
    ft1 = create_field_type field_type: 'text_field', label: 'Text Field'
    fi1 = create_field_instance annotation_type_object: at, name: 'response_task', label: 'Response', field_type_object: ft1

    t = create_task
    assert_nil t.first_response

    t.disable_es_callbacks = true
    t.response = { annotation_type: 'task_response_free_text', set_fields: { response_task: 'Test' }.to_json }.to_json
    t.save!

    t = Task.find(t.id)
    assert_equal 'Test', t.first_response
  end

  test "should set slug when task is created" do
    t = create_task label: 'Where did it happen?'
    assert_equal 'where_did_it_happen', t.slug
  end

  test "should send Slack notification in background" do
    t = create_team slug: 'test'
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    p = create_project team: t
    t.set_slack_notifications_enabled = 1
    t.set_slack_webhook = 'https://hooks.slack.com/services/123'
    slack_notifications = [{
      "label": random_string,
      "event_type": "any_activity",
      "slack_channel": "#test"
    }]
    t.slack_notifications = slack_notifications.to_json
    t.save!
    pm = create_project_media project: p
    with_current_user_and_team(u, t) do
      tk = create_task annotator: u, annotated: pm
      tk = Task.find(tk.id)
      tk.data = { label: 'Foo', type: 'free_text', fieldset: 'tasks' }.with_indifferent_access
      tk.save!
    end
  end

  test "should load task" do
    t = create_task
    assert_equal t, t.task
  end

  test "should get completed and opended tasks" do
    at = create_annotation_type annotation_type: 'task_response'
    create_field_instance annotation_type_object: at, name: 'response_test'
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p
    tk = create_task annotated: pm
    tk2 = create_task annotated: pm
    assert_equal 2, pm.open_tasks.count
    assert_equal 0, pm.completed_tasks_count
    u1 = create_user
    u2 = create_user
    create_team_user team: t, user: u1, role: 'collaborator'
    create_team_user team: t, user: u2, role: 'collaborator'
    tk.assign_user(u1.id)
    tk.assign_user(u2.id)
    User.current = u1
    tk = Task.find(tk.id)
    tk.response = { annotation_type: 'task_response', set_fields: { response_test: 'test' }.to_json }.to_json
    tk.save!
    assert_equal 1, pm.open_tasks.count
    assert_equal 1, pm.completed_tasks_count
    User.current = u2
    tk = Task.find(tk.id)
    tk.response = { annotation_type: 'task_response', set_fields: { response_test: 'test' }.to_json }.to_json
    tk.save!
    assert_equal 1, pm.open_tasks.count
    assert_equal 1, pm.completed_tasks_count
    tk2 = Task.find(tk2.id)
    tk2.response = { annotation_type: 'task_response', set_fields: { response_test: 'test' }.to_json }.to_json
    tk2.save!
    assert_equal 0, pm.open_tasks.count
    assert_equal 2, pm.completed_tasks_count
  end

  test "should allow editor to delete task" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'editor'
    p = create_project team: t
    pm = create_project_media project: p
    tk = create_task annotated: pm
    at = create_annotation_type annotation_type: 'task_response'
    create_field_instance annotation_type_object: at, name: 'response_test'
    tk.response = { annotation_type: 'task_response', set_fields: { response_test: 'test' }.to_json }.to_json
    tk.save!
    with_current_user_and_team(u, t) do
      assert_difference 'Annotation.where(annotation_type: "task").count', -1 do
        tk.destroy
      end
    end
  end

  test "should define a JSON schema" do
    t = create_task

    assert_raises ActiveRecord::RecordInvalid do
      t.json_schema = { not: 'a valid schema' }
      t.save!
    end

    schema = {
      type: 'object',
      required: ['bar'],
      properties: {
        foo: { type: 'integer' },
        bar: { type: 'string' }
      }
    }

    t.json_schema = schema
    t.save!

    assert JSON::Validator.validate(t.reload.json_schema, { foo: 12, bar: 'test' })
    assert !JSON::Validator.validate(t.reload.json_schema, { foo: 12 })

    schema = {
      type: 'string',
    }

    t.json_schema = schema
    t.save!

    assert JSON::Validator.validate(t.reload.json_schema, 'string')
    assert !JSON::Validator.validate(t.reload.json_schema, 123)

    schema = {
      type: 'string',
      pattern: '^[a-z]*$'
    }

    t.json_schema = schema
    t.save!

    assert JSON::Validator.validate(t.reload.json_schema, 'string')
    assert !JSON::Validator.validate(t.reload.json_schema, 'STRING')

    schema = {
      type: 'string',
      pattern: '^https?://[^.]+\.[^.]+.*$'
    }

    t.json_schema = schema
    t.save!

    assert JSON::Validator.validate(t.reload.json_schema, 'https://meedan.com')
    assert !JSON::Validator.validate(t.reload.json_schema, 'Foo Bar')
  end

  test "should validate task answer against JSON schema" do
    at = create_annotation_type annotation_type: 'task_response_free_text', label: 'Task'
    ft1 = create_field_type field_type: 'text_field', label: 'Text Field'
    fi1 = create_field_instance annotation_type_object: at, name: 'response_free_text', label: 'Response', field_type_object: ft1

    schema = {
      type: 'string',
      pattern: '^https?://[^.]+\.[^.]+.*$'
    }

    tk = create_task json_schema: schema
    tk.save!
    tk = Task.find(tk.id)

    assert_nothing_raised do
      tk.response = { annotation_type: 'task_response_free_text', set_fields: { response_free_text: 'https://meedan.com' }.to_json }.to_json
      tk.save!

      d = Dynamic.find(tk.response.id)
      d.set_fields = { response_free_text: 'https://checkmedia.org' }.to_json
      d.save!
    end

    assert_raises ActiveRecord::RecordInvalid do
      d = Dynamic.find(tk.response.id)
      d.set_fields = { response_free_text: 'Foo Bar' }.to_json
      d.save!
    end
  end

  test "should not create task with invalid fieldset" do
    assert_difference 'Task.length', 2 do
      create_task fieldset: 'tasks'
      create_task fieldset: 'metadata'
    end
    assert_no_difference 'Task.length' do
      assert_raises ActiveRecord::RecordInvalid do
        create_task fieldset: 'invalid'
      end
      assert_raises ActiveRecord::RecordInvalid do
        create_task fieldset: ''
      end
      assert_raises ActiveRecord::RecordInvalid do
        create_task fieldset: nil
      end
    end
  end

  test "should get tasks by fieldset" do
    t1 = create_task fieldset: 'tasks'
    t2 = create_task fieldset: 'tasks'
    t3 = create_task fieldset: 'metadata'
    t4 = create_task fieldset: 'metadata'
    assert_equal [t1, t2].sort, Task.from_fieldset('tasks').sort
    assert_equal [t3, t4].sort, Task.from_fieldset('metadata').sort
  end

  test "should create tasks with fieldset from team task" do
    t = create_team
    tt1 = create_team_task team_id: t.id, fieldset: 'tasks'
    tt2 = create_team_task team_id: t.id, fieldset: 'metadata'
    pm = create_project_media team: t
    assert_equal 1, Task.where(annotated_type: 'ProjectMedia', annotated_id: pm.id).from_fieldset('tasks').count
    assert_equal 1, Task.where(annotated_type: 'ProjectMedia', annotated_id: pm.id).from_fieldset('metadata').count
  end

  test "should return task answers" do
    create_task_stuff
    t = create_team
    tt1a = create_team_task team_id: t.id 
    tt1b = create_team_task team_id: t.id 
    tt2a = create_team_task team_id: t.id 
    tt2b = create_team_task team_id: t.id 
    
    pm1 = create_project_media team: t
    t1a = create_task annotated: pm1, type: 'multiple_choice', options: ['Apple', 'Orange', 'Banana'], label: 'Fruits you like', team_task_id: tt1a.id
    t1a.response = { annotation_type: 'task_response_multiple_choice', set_fields: { response_multiple_choice: { selected: ['Apple', 'Orange'], other: nil }.to_json }.to_json }.to_json
    t1a.save!

    t1b = create_task annotated: pm1, type: 'single_choice', options: ['The Beatles', 'Iron Maiden', 'Helloween'], label: 'Best band', team_task_id: tt1b.id
    t1b.response = { annotation_type: 'task_response_single_choice', set_fields: { response_single_choice: { selected: 'The Beatles', other: nil }.to_json }.to_json }.to_json
    t1b.save!

    assert_equal ['Apple', 'Orange', 'The Beatles'], pm1.reload.task_answer_selected_values.sort
    assert pm1.selected_value_for_task?(tt1a.id, 'Apple')
    assert pm1.selected_value_for_task?(tt1a.id, 'Orange')
    assert !pm1.selected_value_for_task?(tt1a.id, 'Banana')
    assert pm1.selected_value_for_task?(tt1b.id, 'The Beatles')
    assert !pm1.selected_value_for_task?(tt1b.id, 'Iron Maiden')
    assert !pm1.selected_value_for_task?(tt1b.id, 'Helloween')
    
    pm2 = create_project_media team: t

    t2a = create_task annotated: pm2, type: 'multiple_choice', options: ['Brazil', 'Canada', 'Egypt'], label: 'Places to visit', team_task_id: tt2a.id
    t2a.response = { annotation_type: 'task_response_multiple_choice', set_fields: { response_multiple_choice: { selected: ['Brazil', 'Egypt'], other: nil }.to_json }.to_json }.to_json
    t2a.save!

    t2b = create_task annotated: pm2, type: 'single_choice', options: ['January', 'February', 'March'], label: 'Month you were born', team_task_id: tt2b.id
    t2b.response = { annotation_type: 'task_response_single_choice', set_fields: { response_single_choice: 'January' }.to_json }.to_json
    t2b.save!

    assert_equal ['Brazil', 'Egypt', 'January'], pm2.reload.task_answer_selected_values.sort

    assert pm2.selected_value_for_task?(tt2a.id, 'Brazil')
    assert pm2.selected_value_for_task?(tt2a.id, 'Egypt')
    assert !pm2.selected_value_for_task?(tt2a.id, 'Canada')
    assert pm2.selected_value_for_task?(tt2b.id, 'January')
    assert !pm2.selected_value_for_task?(tt2b.id, 'February')
    assert !pm2.selected_value_for_task?(tt2b.id, 'March')
  end

  test "should set order when task is created" do
    pm = create_project_media
    t1 = create_task annotated: pm, fieldset: 'tasks'
    m1 = create_task annotated: pm, fieldset: 'metadata'
    assert_equal 1, t1.reload.order
    assert_equal 1, m1.reload.order
    t2 = create_task annotated: pm, fieldset: 'tasks'
    m2 = create_task annotated: pm, fieldset: 'metadata'
    assert_equal 2, t2.reload.order
    assert_equal 2, m2.reload.order
    Task.swap_order(t1, t2)
    assert_equal 1, t2.reload.order
    assert_equal 2, t1.reload.order
    Task.swap_order(m1, m2)
    assert_equal 1, m2.reload.order
    assert_equal 2, m1.reload.order
  end

  test "should move tasks up and down" do
    pm = create_project_media
    t1 = create_task annotated: pm, fieldset: 'tasks'; sleep 1
    m1 = create_task annotated: pm, fieldset: 'metadata'; sleep 1
    t2 = create_task annotated: pm, fieldset: 'tasks'; sleep 1
    m2 = create_task annotated: pm, fieldset: 'metadata'; sleep 1
    t3 = create_task annotated: pm, fieldset: 'tasks'; sleep 1
    m3 = create_task annotated: pm, fieldset: 'metadata'; sleep 1
    t4 = create_task annotated: pm, fieldset: 'tasks'; sleep 1
    m4 = create_task annotated: pm, fieldset: 'metadata'; sleep 1
    t5 = create_task annotated: pm, fieldset: 'tasks'; sleep 1
    m5 = create_task annotated: pm, fieldset: 'metadata'; sleep 1
    assert_equal [t1, t2, t3, t4, t5].map(&:id), pm.ordered_tasks('tasks').map(&:id)
    [t1, t2, t3, t4, t5].each { |t| t.order = nil ; t.save! }
    assert_equal [t1, t2, t3, t4, t5].map(&:id), pm.ordered_tasks('tasks').map(&:id)
    t4.move_up
    [t1, t2, t4, t3, t5].each_with_index { |t, i| assert_equal i + 1, t.reload.order }
    t1.move_up
    [t1, t2, t4, t3, t5].each_with_index { |t, i| assert_equal i + 1, t.reload.order }
    t5.move_down
    [t1, t2, t4, t3, t5].each_with_index { |t, i| assert_equal i + 1, t.reload.order }
    t2.move_up
    [t2, t1, t4, t3, t5].each_with_index { |t, i| assert_equal i + 1, t.reload.order }
    t3.move_down
    [t2, t1, t4, t5, t3].each_with_index { |t, i| assert_equal i + 1, t.reload.order }
    assert_equal [m1, m2, m3, m4, m5].map(&:id), pm.ordered_tasks('metadata').map(&:id)
    [m1, m2, m3, m4, m5].each { |t| t.order = nil ; t.save! }
    assert_equal [m1, m2, m3, m4, m5].map(&:id), pm.ordered_tasks('metadata').map(&:id)
    m4.move_up
    [m1, m2, m4, m3, m5].each_with_index { |t, i| assert_equal i + 1, t.reload.order }
    m1.move_up
    [m1, m2, m4, m3, m5].each_with_index { |t, i| assert_equal i + 1, t.reload.order }
    m5.move_down
    [m1, m2, m4, m3, m5].each_with_index { |t, i| assert_equal i + 1, t.reload.order }
    m2.move_up
    [m2, m1, m4, m3, m5].each_with_index { |t, i| assert_equal i + 1, t.reload.order }
    m3.move_down
    [m2, m1, m4, m5, m3].each_with_index { |t, i| assert_equal i + 1, t.reload.order }
  end

  test "should reorder when task is created" do
    pm = create_project_media
    t1 = create_task annotated: pm ; sleep 1
    t2 = create_task annotated: pm ; sleep 1
    t3 = create_task annotated: pm ; sleep 1
    [t1, t2, t3].each { |t| t.order = nil ; t.save! }
    assert_equal [t1, t2, t3], pm.ordered_tasks('tasks')
    [t1, t2, t3].each { |t| assert_nil t.reload.order }
    t4 = create_task annotated: pm
    assert_equal [t1, t2, t3, t4], pm.ordered_tasks('tasks')
    [t1, t2, t3, t4].each_with_index { |t, i| assert_equal i + 1, t.reload.order }
  end

  test "should reorder when task is destroyed" do
    pm = create_project_media
    t1 = create_task annotated: pm ; sleep 1
    t2 = create_task annotated: pm ; sleep 1
    t3 = create_task annotated: pm ; sleep 1
    [t1, t2, t3].each { |t| t.order = nil ; t.save! }
    assert_equal [t1, t2, t3], pm.ordered_tasks('tasks')
    [t1, t2, t3].each { |t| assert_nil t.reload.order }
    t2.destroy!
    assert_equal [t1, t3], pm.ordered_tasks('tasks')
    [t1, t3].each_with_index { |t, i| assert_equal i + 1, t.reload.order }
  end

  test "should notify on Slack thread when task is saved" do
    create_annotation_type_and_fields('Slack Message', { 'Id' => ['Id', false], 'Attachments' => ['JSON', false], 'Channel' => ['Text', false] })
    t = create_team slug: 'test'
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    t.set_slack_notifications_enabled = 1
    t.set_slack_webhook = 'https://hooks.slack.com/services/123'
    slack_notifications = [{
      "label": random_string,
      "event_type": "any_activity",
      "slack_channel": "#test"
    }]
    t.slack_notifications = slack_notifications.to_json
    t.save!
    pm = create_project_media team: t
    create_dynamic_annotation annotation_type: 'slack_message', annotated: pm, set_fields: { slack_message_id: random_string, slack_message_channel: '#test', slack_message_attachments: [], slack_message_token: random_string }.to_json
    with_current_user_and_team(u, t) do
      pm.updated_at = Time.now
      pm.save!
      create_task annotator: u, annotated: pm
    end
  end

  test "should upload multiple files to task" do
    t = create_task
    at = create_annotation_type annotation_type: 'task_response'
    t.file = [File.new(File.join(Rails.root, 'test', 'data', 'rails.png')), File.new(File.join(Rails.root, 'test', 'data', 'rails2.png'))]
    t.response = { annotation_type: 'task_response' }.to_json
    t.save!
    file_urls = t.reload.first_response_obj.file_data
    assert_kind_of Hash, file_urls
    assert_equal 2, file_urls[:file_urls].size
  end

  test "should get team task from task" do
    t = create_team
    tt = create_team_task team_id: t.id
    pm = create_project_media team: t
    assert_equal tt, Task.where(annotated_type: 'ProjectMedia', annotated_id: pm.id).last.team_task
  end
end
