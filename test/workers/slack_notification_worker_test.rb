require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class SlackNotificationWorkerTest < ActiveSupport::TestCase
  def setup
    super
    require 'sidekiq/testing'
    Sidekiq::Testing.fake!
  end

  test "should notify Slack in background" do
    Rails.stubs(:env).returns(:production)
    t = create_team slug: 'test'
    t.set_slack_notifications_enabled = 1; t.set_slack_webhook = 'https://hooks.slack.com/services/123'; t.set_slack_channel = '#test'; t.save!
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    assert_equal 0, SlackNotificationWorker.jobs.size
    with_current_user_and_team(u, t) do
      p = create_project team: t
      assert_equal 1, SlackNotificationWorker.jobs.size
      SlackNotificationWorker.drain
      assert_equal 0, SlackNotificationWorker.jobs.size
      Rails.unstub(:env)
    end
  end

end
