require_relative '../../test_helper'
require 'sidekiq/testing'

class Bot::SlackTest < ActiveSupport::TestCase
  def setup
    super
    Bot::Slack.delete_all
    @bot = create_slack_bot
    create_annotation_type_and_fields('Slack Message', { 'Id' => ['Id', false], 'Attachments' => ['JSON', false], 'Channel' => ['Text', false] })
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

  test "should send message to Slack thread if there is annotation" do
    WebMock.disable_net_connect!
    stub = WebMock.stub_request(:get, /^https:\/\/slack\.com\/api\/chat\./).to_return(body: 'ok')
    pm = create_project_media
    2.times do
      create_dynamic_annotation annotated: pm, annotation_type: 'slack_message', set_fields: { slack_message_id: '12.34', slack_message_attachments: '[]', slack_message_channel: 'C0123Y' }.to_json
    end
    stub_config('slack_token', '123456') do
      Sidekiq::Testing.inline! do
        create_comment annotated: pm
      end
    end
    assert_equal 2, WebMock::RequestRegistry.instance.times_executed(stub.request_pattern)
    WebMock.allow_net_connect!
  end

  test "should not send message to Slack thread if there is no annotation" do
    WebMock.disable_net_connect!
    stub = WebMock.stub_request(:get, /^https:\/\/slack\.com\/api\/chat\./).to_return(body: 'ok')
    pm = create_project_media
    2.times do
      create_dynamic_annotation annotation_type: 'slack_message', set_fields: { slack_message_id: '12.34', slack_message_attachments: '[]', slack_message_channel: 'C0123Y' }.to_json
    end
    stub_config('slack_token', '123456') do
      Sidekiq::Testing.inline! do
        create_comment annotated: pm
      end
    end
    assert_equal 0, WebMock::RequestRegistry.instance.times_executed(stub.request_pattern)
    WebMock.allow_net_connect!
  end

  test "should not send message to Slack thread if there is no token" do
    WebMock.disable_net_connect!
    stub = WebMock.stub_request(:get, /^https:\/\/slack\.com\/api\/chat\./).to_return(body: 'ok')
    pm = create_project_media
    2.times do
      create_dynamic_annotation annotated: pm, annotation_type: 'slack_message', set_fields: { slack_message_id: '12.34', slack_message_attachments: '[]', slack_message_channel: 'C0123Y' }.to_json
    end
    stub_config('slack_token', nil) do
      Sidekiq::Testing.inline! do
        create_comment annotated: pm
      end
    end
    assert_equal 0, WebMock::RequestRegistry.instance.times_executed(stub.request_pattern)
    WebMock.allow_net_connect!
  end

  test "should send message to Slack thread if there is annotation (one message per annotation / thread)" do
    WebMock.disable_net_connect!
    stub = WebMock.stub_request(:get, /^https:\/\/slack\.com\/api\/chat\./).to_return(body: 'ok')
    pm = create_project_media
    3.times do
      create_dynamic_annotation annotated: pm, annotation_type: 'slack_message', set_fields: { slack_message_id: '12.34', slack_message_attachments: '[]', slack_message_channel: 'C0123Y' }.to_json
    end
    stub_config('slack_token', '123456') do
      Sidekiq::Testing.inline! do
        create_comment annotated: pm
      end
    end
    assert_equal 3, WebMock::RequestRegistry.instance.times_executed(stub.request_pattern)
    WebMock.allow_net_connect!
  end

  test "should update message on Slack thread when status is changed" do
    WebMock.disable_net_connect! 
    stub = WebMock.stub_request(:get, /^https:\/\/slack\.com\/api\/chat\./).to_return(body: 'ok')
    pm = create_project_media
    3.times do
      a = [{ fields: [{}, {}, {}, {}, {}, {}] }].to_json
      create_dynamic_annotation annotated: pm, annotation_type: 'slack_message', set_fields: { slack_message_id: '12.34', slack_message_attachments: a, slack_message_channel: 'C0123Y' }.to_json
    end
    stub_config('slack_token', '123456') do
      Sidekiq::Testing.inline! do
        s = pm.annotations.where(annotation_type: 'status').last.load
        s.status = 'in_progress'
        s.disable_es_callbacks = true
        s.save!
      end
    end
    assert_equal 3, WebMock::RequestRegistry.instance.times_executed(stub.request_pattern)
    WebMock.allow_net_connect!
  end
end
