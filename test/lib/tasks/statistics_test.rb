require_relative '../../test_helper'
require 'rake'

class StatisticsTest < ActiveSupport::TestCase
  # override default test setup
  def before_all; end
  def after_all; end

  def setup
    Rake.application.rake_require("tasks/data/statistics")
    Rake::Task.define_task(:environment)

    MonthlyTeamStatistic.delete_all
    Team.delete_all
    TeamBotInstallation.delete_all
    ProjectMedia.delete_all

    @current_date = DateTime.new(2022,5,15,5,30,00)
    @start_of_month =  DateTime.new(2022,5,1,0,0,0).beginning_of_month
    @end_of_month = DateTime.new(2022,5,31,23,59,59).end_of_month

    # Create data for tipline team
    @tipline_team = create_team(slug: 'test-team')
    create_team_bot_installation(team_id: @tipline_team.id, user_id: BotUser.smooch_user.id)
    3.times{|i| create_project_media(user: BotUser.smooch_user, claim: "Claim: correct team #{i}", team: @tipline_team, created_at: @current_date) }

    TeamBotInstallation.any_instance.stubs(:smooch_enabled_integrations).returns({whatsapp: 'foo'})
  end

  def teardown
    travel_back
  end

  test "generates statistics data for every platform and language of tipline teams" do
    @tipline_team.set_languages(['en', 'es'])
    @tipline_team.save!

    non_tipline_team = create_team(slug: 'other-team')
    non_tipline_team_user = create_user(team: non_tipline_team)
    3.times{|i| create_project_media(user: non_tipline_team_user, claim: "Claim: other team #{i}", team: non_tipline_team, created_at: @current_date) }

    CheckStatistics.expects(:get_statistics).with(@start_of_month, @current_date, @tipline_team.id, :whatsapp, 'en').returns(
      {
        platform: 'whatsapp',
        language: 'en',
        start_date: @start_of_month,
        end_date: @current_date,
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
    CheckStatistics.expects(:get_statistics).with(@start_of_month, @current_date, @tipline_team.id, :whatsapp, 'es').returns({
      platform: 'whatsapp',
      language: 'es',
      start_date: @start_of_month,
      end_date: @current_date,
      conversations: 200,
    })
    travel_to @current_date

    assert_equal 0, MonthlyTeamStatistic.where(team: @tipline_team).count

    Rake::Task['check:data:statistics'].invoke
    Rake::Task['check:data:statistics'].reenable

    # One for each language
    assert_equal 2, MonthlyTeamStatistic.where(team: @tipline_team).count

    stats = MonthlyTeamStatistic.first
    assert_equal @start_of_month.to_i, stats.start_date.to_i
    assert_equal @current_date.to_i, stats.end_date.to_i
    assert_equal 'en', stats.language
    assert_equal 'whatsapp', stats.platform
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
  end

  test "generates statistics data for each month in tipline history when absent" do
    create_project_media(user: BotUser.smooch_user, claim: "Claim: previous month", team: @tipline_team, created_at: @current_date - 1.month)

    # Full month - past
    start_of_previous_month = (@current_date - 1.month).beginning_of_month
    end_of_previous_month = (@current_date - 1.month).end_of_month
    CheckStatistics.expects(:get_statistics).with(start_of_previous_month, end_of_previous_month, @tipline_team.id, :whatsapp, 'en').returns(
      {
        platform: :whatsapp,
        language: 'en',
        start_date: start_of_previous_month,
        end_date: end_of_previous_month,
      }
    )

    # Partial month - current
    CheckStatistics.expects(:get_statistics).with(@start_of_month, @current_date, @tipline_team.id, :whatsapp, 'en').returns(
      {
        platform: :whatsapp,
        language: 'en',
        start_date: @start_of_month,
        end_date: @current_date,
      }
    )

    travel_to @current_date

    assert_equal 0, MonthlyTeamStatistic.where(team: @tipline_team).count

    Rake::Task['check:data:statistics'].invoke
    Rake::Task['check:data:statistics'].reenable

    assert_equal 2, MonthlyTeamStatistic.where(team: @tipline_team).count
  end

  test "only regenerates the current month's statistics when past data is present and complete, and updates end_date" do
    # Create data for previous months
    create_project_media(user: BotUser.smooch_user, claim: "Claim: previous month", team: @tipline_team, created_at: @current_date - 1.month)
    create_monthly_team_statistic(team: @tipline_team,
                                  start_date: (@current_date - 1.month).beginning_of_month,
                                  end_date: (@current_date - 1.month).end_of_month,
                                  platform: 'whatsapp',
                                  language: 'en')

    # Create data for current month, to be updated  by task
    current_statistics = create_monthly_team_statistic(team: @tipline_team,
                                                       start_date: @current_date.beginning_of_month,
                                                       end_date: @current_date - 1.day,
                                                       platform: 'whatsapp',
                                                       language: 'en',
                                                       conversations: 1)

    CheckStatistics.expects(:get_statistics).with(@start_of_month, @current_date, @tipline_team.id, :whatsapp, 'en').returns(
      {
        platform: :whatsapp,
        language: 'en',
        start_date: @start_of_month,
        end_date: @current_date,
        conversations: 2,
      }
    )

    travel_to @current_date

    assert_equal 2, MonthlyTeamStatistic.where(team: @tipline_team).count
    assert_equal current_statistics.end_date, @current_date - 1.day
    assert_equal 1, current_statistics.conversations

    Rake::Task['check:data:statistics'].invoke
    Rake::Task['check:data:statistics'].reenable

    current_statistics.reload
    assert_equal 2, MonthlyTeamStatistic.where(team: @tipline_team).count
    assert_equal current_statistics.end_date, @current_date
    assert_equal 2, current_statistics.conversations
  end
end
