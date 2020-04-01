require_relative '../test_helper'

class TeamTaskTest < ActiveSupport::TestCase
  def setup
    super
    TeamTask.delete_all
    create_translation_status_stuff
    create_verification_status_stuff(false)
    create_task_status_stuff(false)
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

  test "should update teamwide tasks with zero answers" do
    t =  create_team
    p = create_project team: t
    p2 = create_project team: t
    pm = create_project_media project: p
    create_project_media project: p, archived: 1
    Team.stubs(:current).returns(t)
    tt = create_team_task team_id: t.id, project_ids: [p2.id],required: false, description: 'Foo', options: [{ label: 'Foo' }]
    pm2 = create_project_media project: p2
    pm3 = create_project_media project: p2
    # set pm3 in final state
    s = pm3.last_status_obj
    s.status = CONFIG['app_name'] == 'Check' ? 'verified' : 'ready'
    s.save!
    pm_tt = pm.annotations('task').select{|t| t.team_task_id == tt.id}.last
    pm2_tt = pm2.annotations('task').select{|t| t.team_task_id == tt.id}.last
    pm3_tt = pm3.annotations('task').select{|t| t.team_task_id == tt.id}.last
    assert_nil pm_tt
    assert_not_nil pm2_tt
    assert_not_nil pm2_tt
    Sidekiq::Testing.inline! do
      # update title
      tt.label = 'update label'; tt.save!
      pm2_tt = pm2_tt.reload
      assert_equal 'update label', pm2_tt.label
      assert_equal 'Foo', pm2_tt.description
      assert_equal([{ 'label' => 'Foo' }], pm2_tt.options)
      assert_not pm2_tt.required
      # update description
      tt.description = 'update desc'; tt.save!
      pm2_tt = pm2_tt.reload
      assert_equal 'update label', pm2_tt.label
      assert_equal 'update desc', pm2_tt.description
      assert_equal([{ 'label' => 'Foo' }], pm2_tt.options)
      assert_not pm2_tt.required
      # update options
      tt.json_options = [{ label: 'Test' }].to_json; tt.save!
      pm2_tt = pm2_tt.reload
      assert_equal 'update label', pm2_tt.label
      assert_equal 'update desc', pm2_tt.description
      assert_equal([{ 'label' => 'Test' }], pm2_tt.options)
      assert_not pm2_tt.required
      # update required (False => True)
      tt.required = true; tt.save!
      pm2_tt = pm2_tt.reload
      assert_equal 'update label', pm2_tt.label
      assert_equal 'update desc', pm2_tt.description
      assert_equal([{ 'label' => 'Test' }], pm2_tt.options)
      assert pm2_tt.required
      assert_not pm3_tt.reload.required
      # update title/description/options/required (True => False)
      tt.label = 'update label2'
      tt.description = 'update desc2'
      tt.json_options = [{ label: 'Test2' }].to_json
      tt.required = false
      tt.save!
      pm2_tt = pm2_tt.reload
      assert_equal 'update label2', pm2_tt.label
      assert_equal 'update desc2', pm2_tt.description
      assert_equal([{ 'label' => 'Test2' }], pm2_tt.options)
      assert_not pm2_tt.required
      pm3_tt = pm3_tt.reload
      assert_equal 'update label2', pm3_tt.label
      assert_equal 'update desc2', pm3_tt.description
      assert_equal([{ 'label' => 'Test2' }], pm3_tt.options)
      assert_not pm3_tt.required
      # test add/remove projects
      tt.json_project_ids = [p.id].to_json
      tt.save!
      pm_tt = pm.annotations('task').select{|t| t.team_task_id == tt.id}.last
      assert_not_nil pm_tt
      assert_not_nil pm2_tt.reload
      assert_not_nil pm3_tt.reload
    end
    Team.unstub(:current)
  end

  test "should update teamwide tasks with answers" do
    t =  create_team
    p = create_project team: t
    p2 = create_project team: t
    pm = create_project_media project: p
    pm1 = create_project_media project: p
    # set pm1 in final state
    s = pm1.last_status_obj
    s.status = CONFIG['app_name'] == 'Check' ? 'verified' : 'ready'
    s.save!
    Team.stubs(:current).returns(t)
    tt = create_team_task team_id: t.id, project_ids: [p2.id], required: false, label: 'Foo', description: 'Foo', options: [{ label: 'Foo' }]
    pm2 = create_project_media project: p2
    pm3 = create_project_media project: p2
    pm4 = create_project_media project: p2
    # set pm3 & pm4 in final state
    s = pm3.last_status_obj
    s.status = CONFIG['app_name'] == 'Check' ? 'verified' : 'ready'
    s.save!
    s = pm4.last_status_obj
    s.status = CONFIG['app_name'] == 'Check' ? 'verified' : 'ready'
    s.save!
    pm_tt = pm.annotations('task').select{|t| t.team_task_id == tt.id}.last
    pm1_tt = pm.annotations('task').select{|t| t.team_task_id == tt.id}.last
    pm2_tt = pm2.annotations('task').select{|t| t.team_task_id == tt.id}.last
    pm3_tt = pm3.annotations('task').select{|t| t.team_task_id == tt.id}.last
    pm4_tt = pm4.annotations('task').select{|t| t.team_task_id == tt.id}.last
    assert_nil pm_tt
    assert_nil pm1_tt
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
    Sidekiq::Testing.inline! do
      # update title/description/options
      tt.label = 'update label'
      tt.description = 'update desc'
      tt.json_options = [{ label: 'Test' }].to_json
      tt.save!
      pm2_tt = pm2_tt.reload
      assert_equal 'Foo', pm2_tt.label
      assert_equal 'Foo', pm2_tt.description
      assert_equal([{ 'label' => 'Foo' }], pm2_tt.options)
      pm3_tt = pm3_tt.reload
      assert_equal 'update label', pm3_tt.label
      assert_equal 'update desc', pm3_tt.description
      assert_equal([{ 'label' => 'Test' }], pm3_tt.options)
      pm4_tt = pm4_tt.reload
      assert_equal 'Foo', pm4_tt.label
      assert_equal 'Foo', pm4_tt.description
      assert_equal([{ 'label' => 'Foo' }], pm4_tt.options)
      # update required (False => True)
      tt.required = true; tt.save!
      assert pm2_tt.reload.required
      assert_not pm3_tt.reload.required
      assert pm4_tt.reload.required
      # test add/remove projects
      tt.json_project_ids = [p.id].to_json
      tt.save!
      pm_tt = pm.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm1_tt = pm1.annotations('task').select{|t| t.team_task_id == tt.id}.last
      assert_not_nil pm_tt
      assert_not_nil pm1_tt
      assert_nothing_raised ActiveRecord::RecordNotFound do
        pm2_tt.reload
        pm4_tt.reload
        pm3_tt.reload
      end
    end
    Team.unstub(:current)
  end

  test "should destroy teamwide tasks" do
    t =  create_team
    p = create_project team: t
    Team.stubs(:current).returns(t)
    tt = create_team_task team_id: t.id, project_ids: [p.id]
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
    # set pm2 and pm4 in terminal status
    s = pm2.last_status_obj
    s.status = CONFIG['app_name'] == 'Check' ? 'verified' : 'ready'
    s.save!
    s = pm4.last_status_obj
    s.status = CONFIG['app_name'] == 'Check' ? 'verified' : 'ready'
    s.save!
    Sidekiq::Testing.inline! do
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

  test "should not duplicate team task when add a project" do
    t =  create_team
    p = create_project team: t
    p2 = create_project team: t
    Team.stubs(:current).returns(t)
    tt = create_team_task team_id: t.id, project_ids: [p.id]
    pm = create_project_media project: p
    pm_tt = pm.annotations('task').select{|t| t.team_task_id == tt.id}.last
    # add response to task for pm
    at = create_annotation_type annotation_type: 'task_response_free_text', label: 'Task'
    ft1 = create_field_type field_type: 'text_field', label: 'Text Field'
    fi1 = create_field_instance annotation_type_object: at, name: 'response_task', label: 'Response', field_type_object: ft1
    pm_tt.response = { annotation_type: 'task_response_free_text', set_fields: { response_task: 'Foo' }.to_json }.to_json
    pm_tt.save!
    Sidekiq::Testing.inline! do
      # test add/remove projects
      tt.json_project_ids = [p2.id].to_json
      tt.save!
      assert_nothing_raised ActiveRecord::RecordNotFound do
        pm_tt.reload
      end
      assert_equal 1, pm.annotations('task').select{|t| t.team_task_id == tt.id}.count
      tt.json_project_ids = [p.id].to_json
      tt.save!
      assert_nothing_raised ActiveRecord::RecordNotFound do
        pm_tt.reload
      end
      assert_equal 1, pm.annotations('task').select{|t| t.team_task_id == tt.id}.count
    end
    Team.unstub(:current)
  end

  test "should notify error when handling team tasks" do
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p
    tt = create_team_task team_id: t.id, project_ids: [p.id]
    ProjectMedia.any_instance.stubs(:create_auto_tasks).raises(StandardError)
    tt.send(:handle_added_projects, [p])
    ProjectMedia.any_instance.unstub(:create_auto_tasks)
  end
end
