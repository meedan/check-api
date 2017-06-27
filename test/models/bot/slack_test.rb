require_relative '../../test_helper'
require 'sidekiq/testing'

class Bot::SlackTest < ActiveSupport::TestCase
  def setup
    super
    @bot = create_slack_bot
  end

  test "should notify super admin when if there are settings and notifications are enabled" do
    t = create_team slug: 'test'
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    @bot.set_slack_notifications_enabled = 1; @bot.set_slack_webhook = 'https://hooks.slack.com/services/123'; @bot.set_slack_channel = '#test'; @bot.save!
    with_current_user_and_team(u, t) do
      p = create_project team: t
      @bot.notify_super_admin(p, t, p)
      assert p.sent_to_slack
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
