require_relative '../../test_helper'

class StatisticsTest < ActiveSupport::TestCase
  # override default test setup
  def before_all; end
  def after_all; end

  def setup
    Check::Application.load_tasks

    Team.delete_all
    TeamBotInstallation.delete_all
    ProjectMedia.delete_all
    MonthlyTeamStatistic.delete_all
  end

  def teardown; end

  test "check:data:statistics saves historic statistics data for any workspaces with tipline data" do
    fake_current_date = DateTime.new(2022,5,15)

    other_team = create_team(slug: 'other-team')
    other_team_user = create_user(team: other_team)
    3.times{|i| create_project_media(user: other_team_user, claim: "Claim: other team #{i}", team: other_team, created_at: fake_current_date) }

    tipline_team = create_team(slug: 'test-team')
    tipline_team.set_languages(['en', 'es'])
    tipline_team.save!
    create_team_bot_installation(team_id: tipline_team.id, user_id: BotUser.smooch_user.id)
    3.times{|i| create_project_media(user: BotUser.smooch_user, claim: "Claim: correct team #{i}", team: tipline_team, created_at: fake_current_date) }

    start_of_month = DateTime.new(2022,5,1,0,0,0).beginning_of_month
    end_of_month = DateTime.new(2022,5,31,23,59,59).end_of_month

    TeamBotInstallation.any_instance.stubs(:smooch_enabled_integrations).returns({whatsapp: 'foo'})
    CheckStatistics.expects(:get_statistics).with(start_of_month, end_of_month, tipline_team.id, :whatsapp, 'en').returns(
      {
        platform: 'WhatsApp',
        language: 'en',
        start_date: start_of_month,
        end_date: end_of_month,
        conversations: 1,
        average_messages_per_day: 2,
        unique_users: 3,
        returning_users: 4,
        valid_new_requests: 5,
        published_native_reports: 6,
        published_imported_reports: 7,
        requests_answered_with_report: 8,
        reports_sent_to_users: 9,
        unique_users_who_received_report: 10,
        median_response_time: 11,
        unique_newsletters_sent: 12,
        new_newsletter_subscriptions: 13,
        newsletter_cancellations: 14,
        current_subscribers: 15,
      }
    )
    CheckStatistics.expects(:get_statistics).with(start_of_month, end_of_month, tipline_team.id, :whatsapp, 'es').returns({
      platform: 'WhatsApp',
      language: 'es',
      start_date: start_of_month,
      end_date: end_of_month,
      conversations: 200,
    })

    assert_nil Rails.cache.read("data:report:#{tipline_team.id}")

    travel_to fake_current_date

    assert_equal 0, MonthlyTeamStatistic.where(team: tipline_team).count

    Rake::Task['check:data:statistics'].invoke

    assert_equal 2, MonthlyTeamStatistic.where(team: tipline_team).count

    stats = MonthlyTeamStatistic.first
    # Check every attribute, since we're doing an insert_all,
    # which bypasses ActiveRecord's usual callbacks and validations
    assert_equal start_of_month.to_i, stats.start_date.to_i
    assert_equal end_of_month.to_i, stats.end_date.to_i
    assert_equal 'en', stats.language
    assert_equal 'WhatsApp', stats.platform
    assert_equal 4, stats.returning_users
    assert_equal 5, stats.valid_new_requests
    assert_equal 6, stats.published_native_reports
    assert_equal 7, stats.published_imported_reports
    assert_equal 8, stats.requests_answered_with_report
    assert_equal 9, stats.reports_sent_to_users
    assert_equal 10, stats.unique_users_who_received_report
    assert_equal 11, stats.median_response_time
    assert_equal 12, stats.unique_newsletters_sent
    assert_equal 13, stats.new_newsletter_subscriptions
    assert_equal 14, stats.newsletter_cancellations
    assert_equal 15, stats.current_subscribers

    assert_equal MonthlyTeamStatistic.last.conversations, 200
  ensure
    travel_back
  end
end
