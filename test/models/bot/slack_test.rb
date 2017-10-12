require_relative '../../test_helper'
require 'sidekiq/testing'

class Bot::SlackTest < ActiveSupport::TestCase
  def setup
    super
    @bot = create_slack_bot
  end

  test "should notify super admin if settings and notifications are enabled" do
    at = create_annotation_type annotation_type: 'task_response_free_text', label: 'Task'
    ft = create_field_type field_type: 'task_reference', label: 'Task Reference'
    fi = create_field_instance annotation_type_object: at, name: 'task_free_text', label: 'Task', field_type_object: ft
    t = create_team slug: 'test'
    t.checklist = [ { 'label' => 'When?', 'type' => 'free_text', 'description' => '', 'projects' => [] } ]
    t.save!
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    @bot.set_slack_notifications_enabled = 1; @bot.set_slack_webhook = 'https://hooks.slack.com/services/123'; @bot.set_slack_channel = '#test'; @bot.save!
    with_current_user_and_team(u, t) do
      p = create_project team: t
      pm = create_project_media project: p
      @bot.notify_super_admin(pm, t, p)
      assert pm.sent_to_slack
    end
  end

  test "should notify super admin even if team is limited" do
    at = create_annotation_type annotation_type: 'task_response_free_text', label: 'Task'
    ft = create_field_type field_type: 'task_reference', label: 'Task Reference'
    fi = create_field_instance annotation_type_object: at, name: 'task_free_text', label: 'Task', field_type_object: ft
    t = create_team slug: 'test'
    t.checklist = [ { 'label' => 'When?', 'type' => 'free_text', 'description' => '', 'projects' => [] } ]
    t.set_limits_slack_integration = false
    t.save!
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    @bot.set_slack_notifications_enabled = 1; @bot.set_slack_webhook = 'https://hooks.slack.com/services/123'; @bot.set_slack_channel = '#test'; @bot.save!
    with_current_user_and_team(u, t) do
      p = create_project team: t
      pm = create_project_media project: p
      assert pm.sent_to_slack
    end
  end

  test "should not notify super admin if there are no settings" do
    @bot.set_slack_notifications_enabled = 0; @bot.save!
    t = create_team slug: 'test'
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    with_current_user_and_team(u, t) do
      p = create_project team: t
      @bot.notify_super_admin(p, t, p)
      assert_nil p.sent_to_slack
    end
  end

end
