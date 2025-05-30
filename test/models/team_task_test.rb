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
    assert_no_difference 'TeamTask.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_team_task label: nil
        create_team_task label: ''
      end
    end
  end

  test "should not have team task without team" do
    assert_no_difference 'TeamTask.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_team_task team_id: nil
      end
    end
  end

  test "should not create team task with invalid type" do
    assert_no_difference 'TeamTask.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_team_task task_type: 'foo_bar'
      end
    end
  end

  test "should serialize options as array" do
    tt = create_team_task
    assert_kind_of Array, tt.options
  end

  test "should set options as JSON" do
    tt = create_team_task
    tt.json_options = [{ label: 'Foo' }].to_json
    tt.save!
    assert_equal([{ 'label' => 'Foo' }], tt.reload.options)
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
      tt = create_team_task team_id: t.id, fieldset: 'metadata', associated_type: 'Source', description: 'Foo', options: [{ label: 'Foo' }]
      tt2 = create_team_task team_id: t.id, fieldset: 'metadata', associated_type: 'ProjectMedia', description: 'Foo2', options: [{ label: 'Foo2' }]
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
    t = create_team
    Team.stubs(:current).returns(t)
    Sidekiq::Testing.inline! do
      pm = create_project_media team: t
      pm2 = create_project_media team: t, archived: CheckArchivedFlags::FlagCodes::UNCONFIRMED
      tt = create_team_task team_id: t.id, order: 2, description: 'Foo', options: [{ label: 'Foo' }]
      tt2 = create_team_task team_id: t.id, order: 1, description: 'Foo2', options: [{ label: 'Foo2' }]
      pm_tt = pm.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm_tt2 = pm.annotations('task').select{|t| t.team_task_id == tt2.id}.last
      pm2_tt = pm2.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm2_tt2 = pm2.annotations('task').select{|t| t.team_task_id == tt2.id}.last
      assert_not_nil pm_tt
      assert_not_nil pm_tt2
      assert_not_nil pm2_tt
      assert_not_nil pm2_tt2
      assert_equal pm_tt.order, tt.order
      assert_equal pm_tt2.order, tt2.order

      assert_equal 1, pm.annotations('task').select{|t| t.team_task_id == tt.id}.count
      assert_equal 1, pm.annotations('task').select{|t| t.team_task_id == tt2.id}.count
    end
    Team.unstub(:current)
  end

  test "should bypass trashed items" do
    t = create_team
    u = create_user
    u2 = create_user
    create_team_user team: t, user: u, role: 'admin'
    create_team_user team: t, user: u2
    Sidekiq::Testing.inline! do
      pm = create_project_media team: t, archived: 1
      tt =create_team_task team_id: t.id
      pm2 = create_project_media team: t
      # Assign task to user and archive the item
      pm2_tt = pm2.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm2_tt.assigned_to_ids = u2.id
      pm2_tt.save!
      pm2.archived = 1
      pm2.save!
      with_current_user_and_team(u, t) do
        assert_no_difference 'Task.length' do
          create_team_task team_id: t.id
        end
        assert_nothing_raised do
          tt.destroy
        end
      end
    end
  end

  test "should skip check permission for background tasks" do
    t = create_team
    u = create_user
    u2 = create_user
    create_team_user user: u, team: t, role: 'admin'
    create_team_user user: u2, team: t
    Sidekiq::Testing.inline! do
      tt = nil
      with_current_user_and_team(u, t) do
        tt = create_team_task team_id: t.id, description: 'Foo', options: [{ label: 'Foo' }]
        pm = create_project_media team: t
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
    t = create_team
    Team.stubs(:current).returns(t)
    Sidekiq::Testing.inline! do
      create_project_media team: t, archived: 1
      tt = create_team_task team_id: t.id, description: 'Foo', task_type: 'single_choice', options: [{ label: 'Foo' }]
      pm = create_project_media team: t
      pm2 = create_project_media team: t
      pm_tt = pm.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm2_tt = pm2.annotations('task').select{|t| t.team_task_id == tt.id}.last
      assert_not_nil pm_tt
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
      # update order
      order = pm2_tt.order + 1
      tt.order = order; tt.save!
      pm2_tt = pm2_tt.reload
      assert_equal 'update label', pm2_tt.label
      assert_equal 'update desc', pm2_tt.description
      assert_equal 'multiple_choice', pm2_tt.type
      assert_equal([{ 'label' => 'Test' }], pm2_tt.options)
      assert_equal order, pm2_tt.order
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
      pm_tt = pm.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm2_tt = pm.annotations('task').select{|t| t.team_task_id == tt.id}.last
      assert_not_nil pm_tt
      assert_not_nil pm2_tt
    end
    Team.unstub(:current)
  end

  test "should update teamwide tasks with or without answers" do
    t = create_team
    Team.stubs(:current).returns(t)
    Sidekiq::Testing.inline! do
      tt = create_team_task team_id: t.id, label: 'Foo', description: 'Foo', task_type: 'single_choice', options: [{ label: 'Foo' }]
      pm = create_project_media team: t
      pm2 = create_project_media team: t
      pm_tt = pm.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm2_tt = pm2.annotations('task').select{|t| t.team_task_id == tt.id}.last
      assert_not_nil pm_tt
      assert_not_nil pm2_tt
      # add response to task for pm2 & pm4
      at = create_annotation_type annotation_type: 'task_response_free_text', label: 'Task'
      ft1 = create_field_type field_type: 'text_field', label: 'Text Field'
      fi1 = create_field_instance annotation_type_object: at, name: 'response_task', label: 'Response', field_type_object: ft1
      pm2_tt.response = { annotation_type: 'task_response_free_text', set_fields: { response_task: 'Foo' }.to_json }.to_json
      pm2_tt.save!
      # update title/description/
      tt.label = 'update label'
      tt.description = 'update desc'
      tt.save!
      pm_tt = pm_tt.reload
      assert_equal 'update label', pm_tt.label
      assert_equal 'update desc', pm_tt.description
      assert_equal 'single_choice', pm_tt.type
      assert_equal([{ 'label' => 'Foo' }], pm_tt.options)
      pm2_tt = pm2_tt.reload
      assert_equal 'update label', pm2_tt.label
      assert_equal 'update desc', pm2_tt.description
      assert_equal 'single_choice', pm2_tt.type
      assert_equal([{ 'label' => 'Foo' }], pm2_tt.options)
    end
    Team.unstub(:current)
  end

  test "should update single_choice task with answers" do
    setup_elasticsearch
    create_task_stuff
    t = create_team
    Team.stubs(:current).returns(t)
    Sidekiq::Testing.inline! do
      tt = create_team_task team_id: t.id, label: 'Foo or Faa', description: 'Foo', task_type: 'single_choice', options: [{ label: 'Foo'}, { label: 'Faa' }]
      pm = create_project_media team: t
      pm2 = create_project_media team: t
      pm_tt = pm.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm2_tt = pm2.annotations('task').select{|t| t.team_task_id == tt.id}.last
      assert_not_nil pm_tt
      assert_not_nil pm2_tt
      # add response to task for pm & pm2
      pm_tt.response = { annotation_type: 'task_response_single_choice', set_fields: { response_single_choice: 'Foo' }.to_json }.to_json
      pm_tt.save!
      pm2_tt.response = { annotation_type: 'task_response_single_choice', set_fields: { response_single_choice: 'Faa' }.to_json }.to_json
      pm2_tt.save!
      r_id = pm_tt.reload.first_response_obj.id
      # update options
      tt.json_options = [{ label: 'Food' }, { label: 'Feed' }, { label: 'Faad' }].to_json
      tt.options_diff = { deleted: ['Foo'], changed: { Faa: 'Faad' }, added: ['Food', 'Feed'] }
      tt.save!
      assert_equal([{ 'label' => 'Food' }, { 'label'  => 'Feed' }, { 'label'  => 'Faad' }], tt.reload.options)
      assert_nil Dynamic.where(id: r_id).last
      assert_equal pm2_tt.reload.first_response, 'Faad'
      sleep 1
      result = $repository.find(get_es_id(pm))['task_responses']
      pm_sc = result.select{|r| r['team_task_id'] == tt.id}.first
      assert_not pm_sc.keys.include?('value')
      result = $repository.find(get_es_id(pm2))['task_responses']
      pm2_sc = result.select{|r| r['team_task_id'] == tt.id}.first
      assert pm2_sc.keys.include?('value')
      assert_equal ['Faad'], pm2_sc['value']
    end
    Team.unstub(:current)
  end

  test "should update multiple_choice task with answers" do
    setup_elasticsearch
    create_task_stuff
    t = create_team
    Team.stubs(:current).returns(t)
    Sidekiq::Testing.inline! do
      tt = create_team_task team_id: t.id, label: 'Foo or Faa', description: 'Foo', task_type: 'multiple_choice', options: [{ label: 'Option A'}, { label: 'Option B' }, { label: 'Option C'}, { label: 'Other', other: true }]
      pm = create_project_media team: t
      pm2 = create_project_media team: t
      pm3 = create_project_media team: t
      pm4 = create_project_media team: t
      pm5 = create_project_media team: t
      pm6 = create_project_media team: t
      pm7 = create_project_media team: t
      pm_tt = pm.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm2_tt = pm2.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm3_tt = pm3.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm4_tt = pm4.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm5_tt = pm5.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm6_tt = pm6.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm7_tt = pm7.annotations('task').select{|t| t.team_task_id == tt.id}.last
      # add response to tasks
      pm_tt.response = { annotation_type: 'task_response_multiple_choice', set_fields: { response_multiple_choice: { selected: ['Option B'], other: nil }.to_json }.to_json }.to_json
      pm_tt.save!
      pm2_tt.response = { annotation_type: 'task_response_multiple_choice', set_fields: { response_multiple_choice: { selected: ['Option A', 'Option B'], other: nil }.to_json }.to_json }.to_json
      pm2_tt.save!
      pm3_tt.response = { annotation_type: 'task_response_multiple_choice', set_fields: { response_multiple_choice: { selected: ['Option A'], other: nil }.to_json }.to_json }.to_json
      pm3_tt.save!
      pm4_tt.response = { annotation_type: 'task_response_multiple_choice', set_fields: { response_multiple_choice: { selected: ['Option B'], other: 'Hello' }.to_json }.to_json }.to_json
      pm4_tt.save!
      pm5_tt.response = { annotation_type: 'task_response_multiple_choice', set_fields: { response_multiple_choice: { selected: ['Option A', 'Option B'], other: 'Hello' }.to_json }.to_json }.to_json
      pm5_tt.save!
      pm6_tt.response = { annotation_type: 'task_response_multiple_choice', set_fields: { response_multiple_choice: { selected: [], other: 'Hello' }.to_json }.to_json }.to_json
      pm6_tt.save!
      pm7_tt.response = { annotation_type: 'task_response_multiple_choice', set_fields: { response_multiple_choice: { selected: ['Option C'], other: nil }.to_json }.to_json }.to_json
      pm7_tt.save!
      r_id = pm_tt.reload.first_response_obj.id
      # update options
      tt.json_options = [{ label: 'Option 1' }, { label: 'Option 2' }, { label: 'Option 3' }, { label: 'Option C' }, { label: 'Other', other: true }].to_json
      tt.options_diff = { deleted: ['Option B'], changed: { 'Option A': 'Option 1' }, added: ['Option 2', 'Option 3'] }
      tt.save!
      assert_equal([{ 'label' => 'Option 1' }, { 'label' => 'Option 2' }, { 'label' => 'Option 3' }, { 'label' => 'Option C' }, { 'label' => 'Other', 'other' => true }], tt.reload.options)
      assert_nil Dynamic.where(id: r_id).last
      assert_equal 'Option 1', pm2_tt.reload.first_response
      assert_equal 'Option 1', pm3_tt.reload.first_response
      assert_equal 'Hello', pm4_tt.reload.first_response
      assert_equal 'Option 1, Hello', pm5_tt.reload.first_response
      assert_equal 'Hello', pm6_tt.reload.first_response
      assert_equal 'Option C', pm7_tt.reload.first_response
      sleep 1
      # Verify ES data
      result = $repository.find(get_es_id(pm))['task_responses']
      pm_mc = result.select{|r| r['team_task_id'] == tt.id}.first
      assert_not pm_mc.keys.include?('value')

      result = $repository.find(get_es_id(pm2))['task_responses']
      mc = result.select{|r| r['team_task_id'] == tt.id}.first
      assert_equal ['Option 1'], mc['value']

      result = $repository.find(get_es_id(pm3))['task_responses']
      mc = result.select{|r| r['team_task_id'] == tt.id}.first
      assert_equal ['Option 1'], mc['value']

      result = $repository.find(get_es_id(pm4))['task_responses']
      mc = result.select{|r| r['team_task_id'] == tt.id}.first
      assert_equal ['Hello'], mc['value']

      result = $repository.find(get_es_id(pm5))['task_responses']
      mc = result.select{|r| r['team_task_id'] == tt.id}.first
      assert_equal ['Option 1', 'Hello'].sort, mc['value'].sort

      result = $repository.find(get_es_id(pm6))['task_responses']
      mc = result.select{|r| r['team_task_id'] == tt.id}.first
      assert_equal ['Hello'], mc['value']

      result = $repository.find(get_es_id(pm7))['task_responses']
      mc = result.select{|r| r['team_task_id'] == tt.id}.first
      assert_equal ['Option C'], mc['value']

      # delete Other
      # tt.json_options = [{ label: 'Option 1' }, { label: 'Option 2' }, { label: 'Option 3' }, { label: 'Option C' }].to_json
      # tt.options_diff = { deleted: [], changed: {}, added: [], delete_other: true }
      # tt.save!
      # assert_equal nil, pm4_tt.reload.first_response
      # assert_equal nil, pm6_tt.reload.first_response
    end
    Team.unstub(:current)
  end

  test "should not update type from teamwide tasks with answers" do
    t = create_team
    Team.stubs(:current).returns(t)
    Sidekiq::Testing.inline! do
      tt = create_team_task team_id: t.id, label: 'Foo', description: 'Foo', task_type: 'single_choice', options: [{ label: 'Foo' }]
      pm = create_project_media team: t
      pm2 = create_project_media team: t
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

  test "should delete teamwide tasks based on keep_completed_tasks attr" do
    t = create_team
    tt = create_team_task team_id: t.id, label: 'Foo', description: 'Foo', options: [{ label: 'Foo' }]
    Team.stubs(:current).returns(t)
    Sidekiq::Testing.inline! do
      pm = create_project_media team: t
      pm2 = create_project_media team: t
      pm_tt = pm.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm2_tt = pm2.annotations('task').select{|t| t.team_task_id == tt.id}.last
      at = create_annotation_type annotation_type: 'task_response_free_text', label: 'Task'
      ft1 = create_field_type field_type: 'text_field', label: 'Text Field'
      fi1 = create_field_instance annotation_type_object: at, name: 'response_task', label: 'Response', field_type_object: ft1
      pm2_tt.response = { annotation_type: 'task_response_free_text', set_fields: { response_task: 'Foo' }.to_json }.to_json
      pm2_tt.save!
      # delete - keep completed tasks
      tt.keep_completed_tasks = true
      tt.destroy!
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
    t = create_team
    Team.stubs(:current).returns(t)
    tt = create_team_task team_id: t.id
    Sidekiq::Testing.inline! do
      pm = create_project_media team: t
      pm2 = create_project_media team: t
      pm3 = create_project_media team: t
      pm4 = create_project_media team: t
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

  test "should notify error when handling team tasks for sources" do
    t = create_team
    pm = create_project_media team: t
    create_source team: t
    # Source error
    tt = create_team_task team_id: t.id, fieldset: 'metadata', associated_type: 'Source'
    Source.any_instance.stubs(:create_auto_tasks).raises(StandardError)
    Sidekiq::Testing.inline! do
      tt.add_teamwide_tasks_bg
    end
    Source.any_instance.unstub(:create_auto_tasks)
  end

  test "should notify error when handling team tasks for project medias" do
    t = create_team
    pm = create_project_media team: t
    tt = create_team_task team_id: t.id, fieldset: 'metadata', associated_type: 'ProjectMedia'
    # Project Media error
    ProjectMedia.any_instance.stubs(:create_auto_tasks).raises(StandardError)
    Sidekiq::Testing.inline! do
      assert_no_difference 'Task.count' do
        tt.add_teamwide_tasks_bg
      end
    end
    ProjectMedia.any_instance.unstub(:create_auto_tasks)
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
    create_tag_text text: 'test', team_id: t.id
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
          "action_definition": "add_tag",
          "action_value": "test"
        }
      ]
    }
    t.rules = rules.to_json
    t.save!
    tt = create_team_task team_id: t.id
    Team.stubs(:current).returns(t)
    Sidekiq::Testing.inline! do
      pm = nil
      assert_difference 'Task.length', 1 do
        pm = create_project_media team: t, quote: 'test by sawy'
      end
      pm_tasks = pm.annotations('task').select{|t| t.team_task_id == tt.id}
      assert_equal 1, pm_tasks.count
      tt2 = create_team_task team_id: t.id
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
    t = create_team
    Team.stubs(:current).returns(t)
    Sidekiq::Testing.inline! do
      tt = create_team_task team_id: t.id, label: 'Foo', description: 'Foo', task_type: 'single_choice', options: [{ label: 'Foo' }]
      pm = create_project_media team: t
      pm2 = create_project_media team: t
      pm3 = create_project_media team: t
      pm4 = create_project_media team: t
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

  test "should notify error when adding team tasks to project medias" do
    t = create_team
    pm = create_project_media team: t
    tt = create_team_task team_id: t.id, fieldset: 'metadata', associated_type: 'ProjectMedia'
    Task.delete_all
    assert_equal 0, pm.get_annotations('task').count
    ProjectMedia.any_instance.stubs(:create_auto_tasks).raises(StandardError)
    tt.send(:add_to_project_medias)
    ProjectMedia.any_instance.unstub(:create_auto_tasks)
    assert_equal 0, pm.get_annotations('task').count
  end
end
