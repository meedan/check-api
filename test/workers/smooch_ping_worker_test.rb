require_relative '../test_helper'

class SmoochPingWorkerTest < ActiveSupport::TestCase
  def setup
    super
    require 'sidekiq/testing'
    WebMock.disable_net_connect! allow: /#{CONFIG['elasticsearch_host']}/
    SmoochApi::ConversationApi.any_instance.stubs(:post_message)
    @project = create_project
    @bid = random_string
    TeamBot.delete_all
    settings = [
      { name: 'smooch_app_id', label: 'Smooch App ID', type: 'string', default: '' },
      { name: 'smooch_secret_key_key_id', label: 'Smooch Secret Key: Key ID', type: 'string', default: '' },
      { name: 'smooch_secret_key_secret', label: 'Smooch Secret Key: Secret', type: 'string', default: '' },
      { name: 'smooch_webhook_secret', label: 'Smooch Webhook Secret', type: 'string', default: '' },
      { name: 'smooch_template_namespace', label: 'Smooch Template Namespace', type: 'string', default: '' },
      { name: 'smooch_bot_id', label: 'Smooch Bot ID', type: 'string', default: '' },
      { name: 'smooch_project_id', label: 'Check Project ID', type: 'number', default: '' },
      { name: 'smooch_window_duration', label: 'Window Duration (in hours - after this time since the last message from the user, the user will be notified... enter 0 to disable)', type: 'number', default: 20 }
    ]
    @bot = create_team_bot name: 'Smooch', identifier: 'smooch', approved: true, settings: settings
    @app_id = random_string
    settings = { 'smooch_project_id' => @project.id, 'smooch_bot_id' => @bid, 'smooch_webhook_secret' => 'test', 'smooch_app_id' => @app_id, 'smooch_secret_key_key_id' => random_string, 'smooch_secret_key_secret' => random_string, 'smooch_template_namespace' => random_string, 'smooch_window_duration' => 10 }
    @installation = create_team_bot_installation team_bot_id: @bot.id, settings: settings
    Bot::Smooch.get_installation('smooch_webhook_secret', 'test')
  end

  test "should send message to Smooch user" do
    Sidekiq::Testing.inline!
    assert_nothing_raised do
      SmoochPingWorker.perform_async(random_string, @app_id)
    end
  end

  test "should not send message if cannot find bot installation" do
    Sidekiq::Testing.inline!
    assert_nothing_raised do
      SmoochPingWorker.perform_async(random_string, 'Unexistent')
    end
  end

end
