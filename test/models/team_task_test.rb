require_relative '../test_helper'

class TeamTaskTest < ActiveSupport::TestCase
  def setup
    super
    TeamTask.delete_all
  end

  test "should create" do
    assert_difference 'TeamTask.count' do
      create_team_task
    end
  end

  test "should not have empty label" do
    assert_raises ActiveRecord::RecordInvalid do
      assert_no_difference 'TeamTask.count' do
        create_team_task label: nil
        create_team_task label: ''
      end
    end
  end

  test "should not have team task without team" do
    assert_raises ActiveRecord::RecordInvalid do
      assert_no_difference 'TeamTask.count' do
        create_team_task team_id: nil
      end
    end
  end

  test "should not create team task with invalid type" do
    assert_raises ActiveRecord::RecordInvalid do
      assert_no_difference 'TeamTask.count' do
        create_team_task task_type: 'foo_bar'
      end
    end
  end

  test "should serialize options as array" do
    tt = create_team_task
    assert_kind_of Array, tt.options
  end

  test "should serialize project ids as array" do
    tt = create_team_task
    assert_kind_of Array, tt.project_ids
  end

  test "should set options as JSON" do
    tt = create_team_task
    tt.json_options = [{ label: 'Foo' }].to_json
    tt.save!
    assert_equal([{ 'label' => 'Foo' }], tt.reload.options)
  end

  test "should set project ids as JSON" do
    tt = create_team_task
    tt.json_project_ids = [1, 2].to_json
    tt.save!
    assert_equal [1, 2].sort, tt.reload.project_ids
  end

  test "should belong to team" do
    t = create_team
    tt = create_team_task team_id: t.id
    assert_equal t, tt.reload.team
  end

  test "should access JSON data" do
    tt = create_team_task task_type: 'free_text'
    assert_equal 'free_text', tt.as_json['type']
    assert_equal 'free_text', tt.as_json[:type]
  end

  test "should get projects" do
    tt = create_team_task project_ids: [1, 2]
    assert_equal [1, 2], tt.projects
  end

  test "should get type" do
    tt = create_team_task task_type: 'free_text'
    assert_equal 'free_text', tt.type
  end

  test "should add teamwide metadata to sources" do
    t = create_team
    s = create_source team: t
    Team.stubs(:current).returns(t)
    Sidekiq::Testing.inline! do
      pm = create_project_media team: t, source: s
      tt = create_team_task team_id: t.id, project_ids: [], fieldset: 'metadata', associated_type: 'Source', description: 'Foo', options: [{ label: 'Foo' }]
      tt2 = create_team_task team_id: t.id, project_ids: [], fieldset: 'metadata', associated_type: 'ProjectMedia', description: 'Foo2', options: [{ label: 'Foo2' }]
      pm_tt = pm.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm_tt2 = pm.annotations('task').select{|t| t.team_task_id == tt2.id}.last
      assert_nil pm_tt
      assert_not_nil pm_tt2
      s_tt = s.annotations('task').select{|t| t.team_task_id == tt.id}.last
      s_tt2 = s.annotations('task').select{|t| t.team_task_id == tt2.id}.last
      assert_not_nil s_tt
      assert_nil s_tt2
      # test adding to new sources
      s2 = nil
      assert_difference 'Task.length', 1 do
        s2 = create_source
      end
      s2_tt = s2.annotations('task').select{|t| t.team_task_id == tt.id}.last
      assert_not_nil s2_tt
      # test update
      tt.label = 'update label'; tt.save!
      assert_equal 'update label', s_tt.reload.label
      assert_equal 'update label', s2_tt.reload.label
      # test destroy
      assert_difference 'Task.length', -1 do
        tt2.destroy
      end
      assert_raises ActiveRecord::RecordNotFound do
        pm_tt2.reload
      end
      assert_nothing_raised do
        s_tt.reload
      end
      tt.destroy
      assert_raises ActiveRecord::RecordNotFound do
        s_tt.reload
      end
      assert_raises ActiveRecord::RecordNotFound do
        s2_tt.reload
      end
    end
    Team.unstub(:current)
  end

  test "should add teamwide task to existing items" do
    t =  create_team
    p = create_project team: t
    Team.stubs(:current).returns(t)
    Sidekiq::Testing.inline! do
      pm = create_project_media project: p
      pm3 = create_project_media team: t
      tt = create_team_task team_id: t.id, project_ids: [p.id], order: 2, description: 'Foo', options: [{ label: 'Foo' }]
      tt2 = create_team_task team_id: t.id, project_ids: [p.id], order: 1, description: 'Foo2', options: [{ label: 'Foo2' }]
      pm_tt = pm.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm_tt2 = pm.annotations('task').select{|t| t.team_task_id == tt2.id}.last
      pm3_tt = pm3.annotations('task').select{|t| t.team_task_id == tt.id}.last
      assert_not_nil pm_tt
      assert_not_nil pm_tt2
      assert_equal pm_tt.order, tt.order
      assert_equal pm_tt2.order, tt2.order
      assert_nil pm3_tt
      # update project list to all items
      assert_difference 'Task.length', 1 do
        tt.json_project_ids = [].to_json
        tt.save!
      end
      assert_equal 1, pm.annotations('task').select{|t| t.team_task_id == tt.id}.count
      pm3_tt = pm3.annotations('task').select{|t| t.team_task_id == tt.id}.last
      assert_not_nil pm3_tt
    end
    Team.unstub(:current)
  end

  test "should bypass trashed items" do
    t =  create_team
    u = create_user
    u2 = create_user
    create_team_user team: t, user: u, role: 'admin'
    create_team_user team: t, user: u2
    p = create_project team: t
    p2 = create_project team: t
    Sidekiq::Testing.inline! do
      pm = create_project_media project: p, archived: 1
      tt =create_team_task team_id: t.id, project_ids: [p2.id]
      pm2 = create_project_media project: p2
      # Assign task to user and archive the item
      pm2_tt = pm2.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm2_tt.assigned_to_ids = u2.id
      pm2_tt.save!
      pm2.archived = 1
      pm2.save!
      with_current_user_and_team(u, t) do
        assert_no_difference 'Task.length' do
          create_team_task team_id: t.id, project_ids: [p.id]
        end
        assert_nothing_raised do
          tt.destroy
        end
      end
    end
  end

  test "should add or remove teamwide task to items related to team" do
    t =  create_team
    p = create_project team: t
    p2 = create_project team: t
    Team.stubs(:current).returns(t)
    Sidekiq::Testing.inline! do
      pm = create_project_media project: p
      pm2 = create_project_media project: p2
      pm3 = create_project_media team: t
      tt = nil
      assert_difference 'Task.length', 3 do
        tt = create_team_task team_id: t.id, project_ids: [], description: 'Foo', options: [{ label: 'Foo' }]
      end
      # update project list to specfic list
      assert_difference 'Task.length', -2 do
        tt.json_project_ids = [p.id].to_json
        tt.save!
      end
      assert_no_difference 'Task.length' do
        tt.json_project_ids = [p2.id].to_json
        tt.save!
      end
      assert_equal 1, pm2.annotations('task').select{|t| t.team_task_id == tt.id}.count
      assert_difference 'Task.length', 2 do
        tt.json_project_ids = [].to_json
        tt.save!
      end
    end
    Team.unstub(:current)
  end

  test "should skip check permission for background tasks" do
    t =  create_team
    u = create_user
    u2 = create_user
    create_team_user user: u, team: t, role: 'admin'
    create_team_user user: u2, team: t
    Sidekiq::Testing.inline! do
      tt = nil
      with_current_user_and_team(u, t) do
        p = create_project team: t
        tt = create_team_task team_id: t.id, project_ids: [p.id], description: 'Foo', options: [{ label: 'Foo' }]
        pm = create_project_media project: p
        pm_tt = pm.annotations('task').select{|t| t.team_task_id == tt.id}.last
        assert_not_nil pm_tt
      end
      with_current_user_and_team(u2, t) do
        tt.label = 'update label'
        tt.skip_check_ability = true
        assert_nothing_raised do
          tt.save!
        end
      end
    end
  end

  test "should update teamwide tasks with zero answers" do
    t =  create_team
    p = create_project team: t
    p2 = create_project team: t
    Team.stubs(:current).returns(t)
    Sidekiq::Testing.inline! do
      pm = create_project_media project: p
      create_project_media project: p, archived: 1
      tt = create_team_task team_id: t.id, project_ids: [p2.id], description: 'Foo', task_type: 'single_choice', options: [{ label: 'Foo' }]
      pm2 = create_project_media project: p2
      pm_tt = pm.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm2_tt = pm2.annotations('task').select{|t| t.team_task_id == tt.id}.last
      assert_nil pm_tt
      assert_not_nil pm2_tt
      # update title
      tt.label = 'update label'; tt.save!
      pm2_tt = pm2_tt.reload
      assert_equal 'update label', pm2_tt.label
      assert_equal 'Foo', pm2_tt.description
      assert_equal 'single_choice', pm2_tt.type
      assert_equal([{ 'label' => 'Foo' }], pm2_tt.options)
      # update description
      tt.description = 'update desc'; tt.save!
      pm2_tt = pm2_tt.reload
      assert_equal 'update label', pm2_tt.label
      assert_equal 'update desc', pm2_tt.description
      assert_equal 'single_choice', pm2_tt.type
      assert_equal([{ 'label' => 'Foo' }], pm2_tt.options)
      # update type
      tt.task_type = 'multiple_choice'; tt.save!
      pm2_tt = pm2_tt.reload
      assert_equal 'update label', pm2_tt.label
      assert_equal 'update desc', pm2_tt.description
      assert_equal 'multiple_choice', pm2_tt.type
      assert_equal([{ 'label' => 'Foo' }], pm2_tt.options)
      # update options
      tt.json_options = [{ label: 'Test' }].to_json; tt.save!
      pm2_tt = pm2_tt.reload
      assert_equal 'update label', pm2_tt.label
      assert_equal 'update desc', pm2_tt.description
      assert_equal 'multiple_choice', pm2_tt.type
      assert_equal([{ 'label' => 'Test' }], pm2_tt.options)
      # update title/description/type/options
      tt.label = 'update label2'
      tt.description = 'update desc2'
      tt.task_type = 'single_choice'
      tt.json_options = [{ label: 'Test2' }].to_json
      tt.save!
      pm2_tt = pm2_tt.reload
      assert_equal 'update label2', pm2_tt.label
      assert_equal 'update desc2', pm2_tt.description
      assert_equal 'single_choice', pm2_tt.type
      assert_equal([{ 'label' => 'Test2' }], pm2_tt.options)
      # test add/remove projects
      tt.json_project_ids = [p.id].to_json
      tt.save!
      pm_tt = pm.annotations('task').select{|t| t.team_task_id == tt.id}.last
      assert_not_nil pm_tt
      assert_raises ActiveRecord::RecordNotFound do
        pm2_tt.reload
      end
    end
    Team.unstub(:current)
  end

  test "should update teamwide tasks with answers" do
    t =  create_team
    p = create_project team: t
    p2 = create_project team: t
    Team.stubs(:current).returns(t)
    Sidekiq::Testing.inline! do
      pm = create_project_media project: p
      tt = create_team_task team_id: t.id, project_ids: [p2.id], label: 'Foo', description: 'Foo', task_type: 'single_choice', options: [{ label: 'Foo' }]
      pm2 = create_project_media project: p2
      pm3 = create_project_media project: p2
      pm4 = create_project_media project: p2
      pm_tt = pm.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm2_tt = pm2.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm3_tt = pm3.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm4_tt = pm4.annotations('task').select{|t| t.team_task_id == tt.id}.last
      assert_nil pm_tt
      assert_not_nil pm2_tt
      assert_not_nil pm3_tt
      assert_not_nil pm4_tt
      # add response to task for pm2 & pm4
      at = create_annotation_type annotation_type: 'task_response_free_text', label: 'Task'
      ft1 = create_field_type field_type: 'text_field', label: 'Text Field'
      fi1 = create_field_instance annotation_type_object: at, name: 'response_task', label: 'Response', field_type_object: ft1
      pm2_tt.response = { annotation_type: 'task_response_free_text', set_fields: { response_task: 'Foo' }.to_json }.to_json
      pm2_tt.save!
      pm4_tt.response = { annotation_type: 'task_response_free_text', set_fields: { response_task: 'Foo' }.to_json }.to_json
      pm4_tt.save!
      # update title/description/
      tt.label = 'update label'
      tt.description = 'update desc'
      tt.keep_completed_tasks = true
      tt.save!
      pm2_tt = pm2_tt.reload
      assert_equal 'Foo', pm2_tt.label
      assert_equal 'Foo', pm2_tt.description
      assert_equal 'single_choice', pm2_tt.type
      assert_equal([{ 'label' => 'Foo' }], pm2_tt.options)
      pm3_tt = pm3_tt.reload
      assert_equal 'update label', pm3_tt.label
      assert_equal 'update desc', pm3_tt.description
      assert_equal 'single_choice', pm3_tt.type
      assert_equal([{ 'label' => 'Foo' }], pm3_tt.options)
      pm4_tt = pm4_tt.reload
      assert_equal 'Foo', pm4_tt.label
      assert_equal 'Foo', pm4_tt.description
      assert_equal 'single_choice', pm4_tt.type
      assert_equal([{ 'label' => 'Foo' }], pm4_tt.options)
      # test add/remove projects
      tt.json_project_ids = [p.id].to_json
      tt.save!
      pm_tt = pm.annotations('task').select{|t| t.team_task_id == tt.id}.last
      assert_not_nil pm_tt
      assert_raises ActiveRecord::RecordNotFound do
        pm2_tt.reload
      end
      assert_raises ActiveRecord::RecordNotFound do
        pm3_tt.reload
      end
      assert_raises ActiveRecord::RecordNotFound do
        pm4_tt.reload
      end
      # test back to all lists
      assert_difference 'Task.length', 3 do
        tt.json_project_ids = [].to_json
        tt.save!
      end
    end
    Team.unstub(:current)
  end

  test "should not update type from teamwide tasks with answers" do
    t =  create_team
    p = create_project team: t
    Team.stubs(:current).returns(t)
    Sidekiq::Testing.inline! do
      tt = create_team_task team_id: t.id, project_ids: [], label: 'Foo', description: 'Foo', task_type: 'single_choice', options: [{ label: 'Foo' }]
      pm = create_project_media project: p
      pm2 = create_project_media project: p
      pm_tt = pm.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm2_tt = pm2.annotations('task').select{|t| t.team_task_id == tt.id}.last
      # add response to task for pm2
      at = create_annotation_type annotation_type: 'task_response_single_choice', label: 'Task'
      ft1 = create_field_type field_type: 'single_choice', label: 'Single Choice'
      fi1 = create_field_instance annotation_type_object: at, name: 'response_task', label: 'Response', field_type_object: ft1
      pm2_tt.response = { annotation_type: 'task_response_single_choice', set_fields: { response_task: 'Foo' }.to_json }.to_json
      pm2_tt.save!
      # update type
      # type can't be edited if tasks has answers
      tt.task_type = 'multiple_choice'
      assert_raises ActiveRecord::RecordInvalid do
        tt.save!
      end
      assert_equal 'single_choice', TeamTask.find(tt.id).task_type
      assert_equal([{ label: 'Foo' }], TeamTask.find(tt.id).options)
    end
    Team.unstub(:current)
  end

  test "should update or delete teamwide tasks based on keep_completed_tasks attr" do
    t =  create_team
    p = create_project team: t
    tt = create_team_task team_id: t.id, project_ids: [], label: 'Foo', description: 'Foo', options: [{ label: 'Foo' }]
    Team.stubs(:current).returns(t)
    Sidekiq::Testing.inline! do
      pm = create_project_media project: p
      pm2 = create_project_media project: p
      pm_tt = pm.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm2_tt = pm2.annotations('task').select{|t| t.team_task_id == tt.id}.last
      at = create_annotation_type annotation_type: 'task_response_free_text', label: 'Task'
      ft1 = create_field_type field_type: 'text_field', label: 'Text Field'
      fi1 = create_field_instance annotation_type_object: at, name: 'response_task', label: 'Response', field_type_object: ft1
      pm2_tt.response = { annotation_type: 'task_response_free_text', set_fields: { response_task: 'Foo' }.to_json }.to_json
      pm2_tt.save!
      # update title/description/options
      # keep completed tasks
      tt.label = 'update label'
      tt.description = 'update desc'
      tt.keep_completed_tasks = true
      tt.save!
      pm_tt = pm_tt.reload
      assert_equal 'update label', pm_tt.label
      assert_equal 'update desc', pm_tt.description
      pm2_tt = pm2_tt.reload
      assert_equal 'Foo', pm2_tt.label
      assert_equal 'Foo', pm2_tt.description
      # apply changes to completed tasks
      tt.label = 'update label2'
      tt.description = 'update desc2'
      tt.keep_completed_tasks = false
      tt.save!
      pm_tt = pm_tt.reload
      assert_equal 'update label2', pm_tt.label
      assert_equal 'update desc2', pm_tt.description
      pm2_tt = pm2_tt.reload
      assert_equal 'update label2', pm_tt.label
      assert_equal 'update desc2', pm_tt.description
      # delete - keep completed tasks
      tt.keep_completed_tasks = true
      tt.destroy
      assert_raises ActiveRecord::RecordNotFound do
        pm_tt.reload
      end
      assert_nothing_raised do
        pm2_tt.reload
      end
    end
    Team.unstub(:current)
  end

  test "should destroy teamwide tasks" do
    t =  create_team
    p = create_project team: t
    Team.stubs(:current).returns(t)
    tt = create_team_task team_id: t.id, project_ids: [p.id]
    Sidekiq::Testing.inline! do
      pm = create_project_media project: p
      pm2 = create_project_media project: p
      pm3 = create_project_media project: p
      pm4 = create_project_media project: p
      pm_tt = pm.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm2_tt = pm2.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm3_tt = pm3.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm4_tt = pm4.annotations('task').select{|t| t.team_task_id == tt.id}.last
      assert_not_nil pm_tt
      assert_not_nil pm2_tt
      assert_not_nil pm3_tt
      assert_not_nil pm4_tt
      # test with these cases
      # pm (0 answer - not verified) / pm2 (0 answer - verified)
      # pm3 (with answer - not verified) / pm4 (with answer - verified)
      # add response to task for pm3 & pm4
      at = create_annotation_type annotation_type: 'task_response_free_text', label: 'Task'
      ft1 = create_field_type field_type: 'text_field', label: 'Text Field'
      fi1 = create_field_instance annotation_type_object: at, name: 'response_task', label: 'Response', field_type_object: ft1
      pm3_tt.response = { annotation_type: 'task_response_free_text', set_fields: { response_task: 'Foo' }.to_json }.to_json
      pm3_tt.save!
      pm4_tt.response = { annotation_type: 'task_response_free_text', set_fields: { response_task: 'Foo' }.to_json }.to_json
      pm4_tt.save!
      tt.keep_completed_tasks = false
      tt.destroy
      assert_raises ActiveRecord::RecordNotFound do
        pm_tt.reload
      end
      assert_raises ActiveRecord::RecordNotFound do
        pm2_tt.reload
      end
      assert_raises ActiveRecord::RecordNotFound do
        pm3_tt.reload
      end
      assert_raises ActiveRecord::RecordNotFound do
        pm4_tt.reload
      end
    end
    Team.unstub(:current)
  end

  test "should notify error when handling team tasks" do
    t = create_team
    p = create_project team: t
    p2 = create_project team: t
    pm = create_project_media project: p
    tt = create_team_task team_id: t.id, project_ids: [p2.id]
    # Project Media error
    ProjectMedia.any_instance.stubs(:create_auto_tasks).raises(StandardError)
    tt.send(:handle_add_projects, { 'project_id': p.id })
    ProjectMedia.any_instance.unstub(:create_auto_tasks)
    # Source error
    tt2 = create_team_task team_id: t.id, fieldset: 'metadata', associated_type: 'Source'
    create_source team: t
    Source.any_instance.stubs(:create_auto_tasks).raises(StandardError)
    tt2.add_teamwide_tasks_bg({}, [], false);
    Source.any_instance.unstub(:create_auto_tasks)
  end

  test "should have valid fieldset" do
    assert_difference 'TeamTask.count', 2 do
      create_team_task fieldset: 'tasks'
      create_team_task fieldset: 'metadata'
    end
    [nil, '', 'invalid'].each do |fieldset|
      assert_raises ActiveRecord::RecordInvalid do
        create_team_task fieldset: fieldset
      end
    end
  end

  test "should set order when team task is created" do
    t = create_team
    t1 = create_team_task team_id: t.id, fieldset: 'tasks'
    m1 = create_team_task team_id: t.id, fieldset: 'metadata'
    assert_equal 1, t1.reload.order
    assert_equal 1, m1.reload.order
    t2 = create_team_task team_id: t.id, fieldset: 'tasks'
    m2 = create_team_task team_id: t.id, fieldset: 'metadata'
    assert_equal 2, t2.reload.order
    assert_equal 2, m2.reload.order
    TeamTask.swap_order(t1, t2)
    assert_equal 1, t2.reload.order
    assert_equal 2, t1.reload.order
    TeamTask.swap_order(m1, m2)
    assert_equal 1, m2.reload.order
    assert_equal 2, m1.reload.order
  end

  test "should move team tasks up and down" do
    t = create_team
    t1 = create_team_task team_id: t.id, fieldset: 'tasks'; sleep 1
    m1 = create_team_task team_id: t.id, fieldset: 'metadata'; sleep 1
    t2 = create_team_task team_id: t.id, fieldset: 'tasks'; sleep 1
    m2 = create_team_task team_id: t.id, fieldset: 'metadata'; sleep 1
    t3 = create_team_task team_id: t.id, fieldset: 'tasks'; sleep 1
    m3 = create_team_task team_id: t.id, fieldset: 'metadata'; sleep 1
    t4 = create_team_task team_id: t.id, fieldset: 'tasks'; sleep 1
    m4 = create_team_task team_id: t.id, fieldset: 'metadata'; sleep 1
    t5 = create_team_task team_id: t.id, fieldset: 'tasks'; sleep 1
    m5 = create_team_task team_id: t.id, fieldset: 'metadata'; sleep 1
    assert_equal [t1, t2, t3, t4, t5].map(&:id), t.ordered_team_tasks('tasks').map(&:id)
    [t1, t2, t3, t4, t5].each { |t| t.order = nil ; t.save! }
    assert_equal [t1, t2, t3, t4, t5].map(&:id), t.ordered_team_tasks('tasks').map(&:id)
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
    assert_equal [m1, m2, m3, m4, m5].map(&:id), t.ordered_team_tasks('metadata').map(&:id)
    [m1, m2, m3, m4, m5].each { |t| t.order = nil ; t.save! }
    assert_equal [m1, m2, m3, m4, m5].map(&:id), t.ordered_team_tasks('metadata').map(&:id)
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

  test "should reorder when team task is created" do
    t = create_team
    t1 = create_team_task team_id: t.id
    t2 = create_team_task team_id: t.id
    t3 = create_team_task team_id: t.id
    TeamTask.update_all(order: nil)
    assert_equal [t1, t2, t3], t.ordered_team_tasks('tasks')
    [t1, t2, t3].each { |t| assert_nil t.reload.order }
    t4 = create_team_task team_id: t.id
    assert_equal [t1, t2, t3, t4], t.ordered_team_tasks('tasks')
    [t1, t2, t3, t4].each_with_index { |t, i| assert_equal i + 1, t.reload.order }
  end

  test "should reorder when team task is destroyed" do
    t = create_team
    t1 = create_team_task team_id: t.id
    t2 = create_team_task team_id: t.id
    t3 = create_team_task team_id: t.id
    TeamTask.update_all(order: nil)
    assert_equal [t1, t2, t3], t.ordered_team_tasks('tasks')
    [t1, t2, t3].each { |t| assert_nil t.reload.order }
    t2.destroy!
    assert_equal [t1, t3], t.ordered_team_tasks('tasks')
    [t1, t3].each_with_index { |t, i| assert_equal i + 1, t.reload.order }
  end

  test "should show or hide in browser extension" do
    tt = create_team_task show_in_browser_extension: true
    t = create_task team_task_id: tt.id
    assert t.show_in_browser_extension
    tt = create_team_task show_in_browser_extension: false
    t = create_task team_task_id: tt.id
    assert !t.show_in_browser_extension
  end

  test "should add-remove team tasks based on rule" do
    create_task_stuff
    t = create_team
    p = create_project team: t
    rules = []
    rules << {
      name: 'Rule 1',
      rules: {
        operator: 'and',
        groups: [
          {
            operator: 'and',
            conditions: [
              {
                rule_definition: 'title_contains_keyword',
                rule_value: 'test'
              },
            ]
          }
        ]
      },
      actions: [
        {
          action_definition: 'move_to_project',
          action_value: p.id
        }
      ]
    }
    t.rules = rules.to_json
    t.save!
    tt = create_team_task team_id: t.id, project_ids: []
    Team.stubs(:current).returns(t)
    Sidekiq::Testing.inline! do
      pm = nil
      assert_difference 'Task.length', 1 do
        pm = create_project_media team: t, quote: 'test by sawy'
      end
      pm_tasks = pm.annotations('task').select{|t| t.team_task_id == tt.id}
      assert_equal 1, pm_tasks.count
      tt2 = create_team_task team_id: t.id, project_ids: [p.id]
      pm2 = nil
      assert_difference 'Task.length', 2 do
        pm2 = create_project_media team: t, quote: 'another test by sawy'
      end
      pm2_tt = pm2.annotations('task').select{|t| t.team_task_id == tt.id}
      pm2_tt2 = pm2.annotations('task').select{|t| t.team_task_id == tt2.id}
      assert_equal 1, pm2_tt.count
      assert_equal 1, pm2_tt2.count
    end
    Team.unstub(:current)
  end

  test "should count teamwide tasks" do
    t =  create_team
    p = create_project team: t
    Team.stubs(:current).returns(t)
    Sidekiq::Testing.inline! do
      tt = create_team_task team_id: t.id, project_ids: [], label: 'Foo', description: 'Foo', task_type: 'single_choice', options: [{ label: 'Foo' }]
      pm = create_project_media project: p
      pm2 = create_project_media project: p
      pm3 = create_project_media project: p
      pm4 = create_project_media project: p
      # add response to task for pm4
      at = create_annotation_type annotation_type: 'task_response_single_choice', label: 'Task'
      ft1 = create_field_type field_type: 'single_choice', label: 'Single Choice'
      fi1 = create_field_instance annotation_type_object: at, name: 'response_task', label: 'Response', field_type_object: ft1
      pm4_tt = pm4.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm4_tt.response = { annotation_type: 'task_response_single_choice', set_fields: { response_task: 'Foo' }.to_json }.to_json
      pm4_tt.save!

      assert_equal 4, tt.tasks_count
      assert_equal 1, tt.tasks_with_answers_count
    end
    Team.unstub(:current)
  end
end
