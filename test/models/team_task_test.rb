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

  test "should not create if no limit" do
    t = create_team
    assert_difference 'TeamTask.count' do
      create_team_task team_id: t.id
    end
    t.set_limits_custom_tasks_list(true)
    t.save!
    assert_difference 'TeamTask.count' do
      create_team_task team_id: t.id
    end
    t.set_limits_custom_tasks_list(false)
    t.save!
    assert_raises ActiveRecord::RecordInvalid do
      assert_no_difference 'TeamTask.count' do
        create_team_task team_id: t.id
      end
    end
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
end
