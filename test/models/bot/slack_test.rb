require_relative '../../test_helper'
require 'sidekiq/testing'

class Bot::SlackTest < ActiveSupport::TestCase
  def setup
    super
    @bot = create_slack_bot
    create_annotation_type_and_fields('Slack Message', { 'Id' => ['Id', false], 'Attachments' => ['JSON', false], 'Channel' => ['Text', false] })
    User.current = create_user(is_admin: true)
  end

  def teardown
    super
    User.current = nil
  end

  test "should notify admin if settings and notifications are enabled" do
    at = create_annotation_type annotation_type: 'task_response_free_text', label: 'Task'
    fi = create_field_instance annotation_type_object: at, name: 'task_free_text', label: 'Task'
    t = create_team slug: 'test'
    create_team_task team_id: t.id, label: 'When?'
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    @bot.set_slack_notifications_enabled = 1; @bot.set_slack_webhook = 'https://hooks.slack.com/services/123'; @bot.set_slack_channel = '#test'; @bot.save!
    pm = create_project_media team: t
    with_current_user_and_team(u, t) do
      @bot.notify_admin(pm, t, 'message')
      assert pm.sent_to_slack
      s = create_source
      @bot.notify_admin(s, t)
      assert_not s.sent_to_slack
    end
  end

  test "should notify admin even if team is limited" do
    at = create_annotation_type annotation_type: 'task_response_free_text', label: 'Task'
    fi = create_field_instance annotation_type_object: at, name: 'task_free_text', label: 'Task'
    t = create_team slug: 'test'
    create_team_task label: 'When?', team_id: t.id
    t.set_limits_slack_integration = false
    slack_notifications = [{
      "label": random_string,
      "event_type": "any_activity",
      "slack_channel": "#test"
    }]
    t.slack_notifications = slack_notifications.to_json
    t.save!
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    @bot.set_slack_notifications_enabled = 1; @bot.set_slack_webhook = 'https://hooks.slack.com/services/123'; @bot.set_slack_channel = '#test'; @bot.save!
    with_current_user_and_team(u, t) do
      pm = create_project_media team: t
      assert pm.sent_to_slack
    end
  end

  test "should send message to Slack thread if there is annotation" do
    WebMock.disable_net_connect! allow: [CheckConfig.get('storage_endpoint')]
    stub = WebMock.stub_request(:get, /^https:\/\/slack\.com\/api\/chat\./).to_return(body: 'ok')
    pm = create_project_media
    2.times do
      create_dynamic_annotation annotated: pm, annotation_type: 'slack_message', set_fields: { slack_message_id: '12.34', slack_message_attachments: '[]', slack_message_channel: 'C0123Y' }.to_json
    end
    stub_configs({ 'slack_token' => '123456' }) do
      Sidekiq::Testing.inline! do
        create_task annotated: pm
      end
    end
    assert_equal 2, WebMock::RequestRegistry.instance.times_executed(stub.request_pattern)
    WebMock.allow_net_connect!
  end

  test "should not send message to Slack thread if there is no annotation" do
    WebMock.disable_net_connect! allow: [CheckConfig.get('storage_endpoint')]
    stub = WebMock.stub_request(:get, /^https:\/\/slack\.com\/api\/chat\./).to_return(body: 'ok')
    pm = create_project_media
    2.times do
      create_dynamic_annotation annotation_type: 'slack_message', set_fields: { slack_message_id: '12.34', slack_message_attachments: '[]', slack_message_channel: 'C0123Y' }.to_json
    end
    stub_configs({ 'slack_token' => '123456' }) do
      Sidekiq::Testing.inline! do
        create_task annotated: pm
      end
    end
    assert_equal 0, WebMock::RequestRegistry.instance.times_executed(stub.request_pattern)
    WebMock.allow_net_connect!
  end

  test "should not send message to Slack thread if there is no annotation type" do
    WebMock.disable_net_connect! allow: [CheckConfig.get('storage_endpoint')]
    stub = WebMock.stub_request(:get, /^https:\/\/slack\.com\/api\/chat\./).to_return(body: 'ok')
    pm = create_project_media
    2.times do
      create_dynamic_annotation annotated: pm, annotation_type: 'slack_message', set_fields: { slack_message_id: '12.34', slack_message_attachments: '[]', slack_message_channel: 'C0123Y' }.to_json
    end
    DynamicAnnotation::AnnotationType.where(annotation_type: 'slack_message').last.delete
    stub_configs({ 'slack_token' => nil }) do
      Sidekiq::Testing.inline! do
        create_task annotated: pm
      end
    end
    assert_equal 0, WebMock::RequestRegistry.instance.times_executed(stub.request_pattern)
    WebMock.allow_net_connect!
  end

  test "should send message to Slack thread if there is annotation (one message per annotation / thread)" do
    WebMock.disable_net_connect! allow: [CheckConfig.get('storage_endpoint')]
    stub = WebMock.stub_request(:get, /^https:\/\/slack\.com\/api\/chat\./).to_return(body: 'ok')
    pm = create_project_media
    3.times do
      create_dynamic_annotation annotated: pm, annotation_type: 'slack_message', set_fields: { slack_message_id: '12.34', slack_message_attachments: '[]', slack_message_channel: 'C0123Y' }.to_json
    end
    stub_configs({ 'slack_token' => '123456' }) do
      Sidekiq::Testing.inline! do
        create_task annotated: pm
      end
    end
    assert_equal 3, WebMock::RequestRegistry.instance.times_executed(stub.request_pattern)
    WebMock.allow_net_connect!
  end

  # Ignore fixing this test as we are going to depreacte
  # test "should update message on Slack thread when status is changed" do
  #   create_verification_status_stuff(false)
  #   WebMock.disable_net_connect! allow: [CheckConfig.get('storage_endpoint')]
  #   RequestStore.store[:disable_es_callbacks] = true
  #   stub = WebMock.stub_request(:get, /^https:\/\/slack\.com\/api\/chat\./).to_return(body: 'ok')
  #   pm = create_project_media
  #   3.times do
  #     a = [{ fields: [{}, {}, {}, {}, {}, {}] }].to_json
  #     d = create_dynamic_annotation annotated: pm, annotation_type: 'slack_message', set_fields: { slack_message_id: '12.34', slack_message_attachments: a, slack_message_channel: 'C0123Y' }.to_json
  #   end
  #   stub_configs({ 'slack_token' => '123456' }) do
  #     Sidekiq::Testing.inline! do
  #       s = pm.annotations.where(annotation_type: pm.default_project_media_status_type).last.load
  #       s.status = 'in_progress'
  #       s.disable_es_callbacks = true
  #       s.save!
  #     end
  #   end
  #   RequestStore.store[:disable_es_callbacks] = false
  #   assert_equal 6, WebMock::RequestRegistry.instance.times_executed(stub.request_pattern)
  #   WebMock.allow_net_connect!
  # end

  test "should update message on Slack thread when title is changed" do
    RequestStore.store[:disable_es_callbacks] = true
    create_verification_status_stuff(false)
    WebMock.disable_net_connect! allow: [CheckConfig.get('storage_endpoint')]
    stub = WebMock.stub_request(:get, /^https:\/\/slack\.com\/api\/chat\./).to_return(body: 'ok')
    pm = create_project_media
    3.times do
      a = [{ fields: [{}, {}, {}, {}, {}, {}] }].to_json
      d = create_dynamic_annotation annotated: pm, annotation_type: 'slack_message', set_fields: { slack_message_id: '12.34', slack_message_attachments: a, slack_message_channel: 'C0123Y' }.to_json
    end
    stub_configs({ 'slack_token' => '123456' }) do
      Sidekiq::Testing.inline! do
        info = { title: 'Foo', content: 'Bar' }
        pm.analysis = info
        pm.save!
      end
    end
    assert_equal 12, WebMock::RequestRegistry.instance.times_executed(stub.request_pattern)
    RequestStore.store[:disable_es_callbacks] = false
    WebMock.allow_net_connect!
  end

  test "should not through error for slack notification if attachments fields is nil" do
    RequestStore.store[:disable_es_callbacks] = true
    create_verification_status_stuff(false)
    WebMock.disable_net_connect! allow: [CheckConfig.get('storage_endpoint')]
    stub = WebMock.stub_request(:get, /^https:\/\/slack\.com\/api\/chat\./).to_return(body: 'ok')
    pm = create_project_media
    a = [{ fields: [{}, {}, {}, nil, {}, {}] }].to_json
    d = create_dynamic_annotation annotated: pm, annotation_type: 'slack_message', set_fields: { slack_message_id: '12.34', slack_message_attachments: a, slack_message_channel: 'C0123Y' }.to_json
    stub_configs({ 'slack_token' => '123456' }) do
      Sidekiq::Testing.inline! do
        info = { title: 'Foo', content: 'Bar' }
        pm.analysis = info
        pm.save!
      end
    end
    assert_equal 4, WebMock::RequestRegistry.instance.times_executed(stub.request_pattern)
    RequestStore.store[:disable_es_callbacks] = false
    WebMock.allow_net_connect!
  end

  test "should truncate text" do
    assert_equal 280, Bot::Slack.to_slack(random_string(300)).size
  end

  test "should notify about related claims" do
    t = create_team slug: 'test'
    slack_notifications = [{
      "label": random_string,
      "event_type": "any_activity",
      "slack_channel": "#test"
    }]
    t.slack_notifications = slack_notifications.to_json
    t.save!
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    @bot.set_slack_notifications_enabled = 1
    @bot.set_slack_webhook = 'https://hooks.slack.com/services/123'
    @bot.set_slack_channel = '#test'
    @bot.save!
    with_current_user_and_team(u, t) do
      pmp = create_project_media team: t
      pmc = create_project_media team: t, related_to_id: pmp.id
      assert pmc.sent_to_slack
    end
  end

  test "should not notify if object does not exist" do
    e = create_metadata
    id = e.id
    e.delete
    assert_nothing_raised do
      Dynamic.call_slack_api(id, nil, 'message', create_user.id)
    end
  end
end
