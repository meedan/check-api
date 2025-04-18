require_relative '../../test_helper'
require 'rake'

class StatisticsTest < ActiveSupport::TestCase
  # override default test setup
  def before_all; end
  def after_all; end

  def setup
    Rake.application.rake_require("tasks/data/statistics")
    Rake::Task.define_task(:environment)
    Rake::Task['check:data:statistics'].reenable
    Rake::Task['check:data:regenerate_statistics'].reenable

    MonthlyTeamStatistic.delete_all
    Team.delete_all
    TeamBotInstallation.delete_all
    ProjectMedia.delete_all

    @current_date = DateTime.new(2023,5,15,5,30,00)
    @start_of_month =  DateTime.new(2023,5,1,0,0,0).beginning_of_month
    @end_of_month = DateTime.new(2023,5,31,23,59,59).end_of_month

    # Create data for tipline team
    create_metadata_stuff
    smooch_bot = create_smooch_bot
    @tipline_team = create_team(slug: 'test-team')
    create_team_bot_installation(team_id: @tipline_team.id, user_id: smooch_bot.id)
    3.times{|i| create_project_media(user: smooch_bot, claim: "Claim: correct team #{i}", team: @tipline_team, created_at: @current_date) }

    TeamBotInstallation.any_instance.stubs(:smooch_enabled_integrations).returns({'whatsapp' => 'foo'})
  end

  def teardown
    travel_back
  end

  test "check:data:statistics generates statistics data for teams with no tipline" do
    TeamBotInstallation.delete_all
    Team.current = nil

    bot_user = create_bot_user
    bot_user.approve!

    non_tipline_team = create_team(slug: 'other-team')

    create_team_bot_installation(team_id: non_tipline_team.id, user_id: bot_user.id)
    3.times{|i| create_project_media(user: bot_user, claim: "Claim: other team #{i}", team: non_tipline_team, created_at: @current_date) }

    assert_equal 0, MonthlyTeamStatistic.where(team: non_tipline_team).count

    travel_to @current_date

    out, err = capture_io do
      Rake::Task['check:data:statistics'].invoke
    end
    Rake::Task['check:data:statistics'].reenable

    assert err.blank?

    assert_equal 7, MonthlyTeamStatistic.where(team: non_tipline_team).count
  end

  test "check:data:statistics generates statistics data for every platform and language of tipline teams" do
    @tipline_team.set_languages(['en', 'es'])
    @tipline_team.save!

    non_tipline_team = create_team(slug: 'other-team')
    non_tipline_team_user = create_user(team: non_tipline_team)
    3.times{|i| create_project_media(user: non_tipline_team_user, claim: "Claim: other team #{i}", team: non_tipline_team, created_at: @current_date) }
    3.times{|i| create_tipline_message(team_id: @tipline_team.id, platform: 'WhatsApp', language: 'en', sent_at: @current_date - 1.day)}

    CheckStatistics.expects(:get_statistics).with(@start_of_month, @current_date, @tipline_team.id, 'whatsapp', 'en').returns(
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
    CheckStatistics.expects(:get_statistics).with(@start_of_month, @current_date, @tipline_team.id, 'whatsapp', 'es').returns({
      platform: 'whatsapp',
      language: 'es',
      start_date: @start_of_month,
      end_date: @current_date,
      conversations: 200,
    })
    travel_to @current_date

    assert_equal 0, MonthlyTeamStatistic.where(team: @tipline_team).count

    out, err = capture_io do
      Rake::Task['check:data:statistics'].invoke
    end
    Rake::Task['check:data:statistics'].reenable

    assert err.blank?
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
    assert_equal 3, stats.conversations_24hr

    assert_equal MonthlyTeamStatistic.last.conversations, 200
  end

  test "check:data:statistics generates statistics data for each month in tipline history when absent" do
    create_project_media(user: BotUser.smooch_user, claim: "Claim: previous month", team: @tipline_team, created_at: @current_date - (1.month - 2.weeks))

    # Full month - past
    start_of_previous_month = (@current_date - 1.month).beginning_of_month
    end_of_previous_month = (@current_date - 1.month).end_of_month
    CheckStatistics.expects(:get_statistics).with(start_of_previous_month, end_of_previous_month, @tipline_team.id, 'whatsapp', 'en').returns(
      {
        platform: 'whatsapp',
        language: 'en',
        start_date: start_of_previous_month,
        end_date: end_of_previous_month,
      }
    )

    # Partial month - current
    CheckStatistics.expects(:get_statistics).with(@start_of_month, @current_date, @tipline_team.id, 'whatsapp', 'en').returns(
      {
        platform: 'whatsapp',
        language: 'en',
        start_date: @start_of_month,
        end_date: @current_date,
      }
    )

    travel_to @current_date

    assert_equal 0, MonthlyTeamStatistic.where(team: @tipline_team).count

    out, err = capture_io do
      Rake::Task['check:data:statistics'].invoke
    end
    Rake::Task['check:data:statistics'].reenable

    assert err.blank?
    assert_equal 2, MonthlyTeamStatistic.where(team: @tipline_team).count
  end

  test "check:data:statistics only regenerates the current month's statistics when past data is present and complete, and updates end_date" do
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

    CheckStatistics.expects(:get_statistics).with(@start_of_month, @current_date, @tipline_team.id, 'whatsapp', 'en').returns(
      {
        platform: 'whatsapp',
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

    out, err = capture_io do
      Rake::Task['check:data:statistics'].invoke
    end
    Rake::Task['check:data:statistics'].reenable

    assert err.blank?

    current_statistics.reload
    assert_equal 2, MonthlyTeamStatistic.where(team: @tipline_team).count
    assert_equal current_statistics.end_date, @current_date
    assert_equal 2, current_statistics.conversations
  end

  test "check:data:statistics skips generating statistics for teams without languages configured" do
    @tipline_team.set_languages(nil)
    @tipline_team.save!

    CheckStatistics.expects(:get_statistics).never

    travel_to @current_date

    out, err = capture_io do
      Rake::Task['check:data:statistics'].invoke
    end
    Rake::Task['check:data:statistics'].reenable

    assert err.blank?
    assert_equal 0, MonthlyTeamStatistic.where(team: @tipline_team).count
  end

  test "check:data:statistics skips generating statistics with zero values" do
    # Setup
    team = @tipline_team
    bot_user = BotUser.smooch_user

    CheckStatistics.stubs(:get_statistics).returns(
      conversations_24hr: 0,
      another_stat: 0
    )
  
    assert_equal 0, MonthlyTeamStatistic.where(team: team).count
  
    travel_to @current_date

    out, err = capture_io do
      Rake::Task['check:data:statistics'].invoke
    end
  
    Rake::Task['check:data:statistics'].reenable
  
    assert err.blank?, "Expected no errors, but got: #{err}"
    assert_equal 0, MonthlyTeamStatistic.where(team: team).count, "Expected no statistics to be created"
  end  

  test "check:data:statistics skips generating statistics for teams without a team bot installation" do
    TeamBotInstallation.delete_all

    CheckStatistics.expects(:get_statistics).never

    travel_to @current_date

    out, err = capture_io do
      Rake::Task['check:data:statistics'].invoke
    end
    Rake::Task['check:data:statistics'].reenable

    assert err.blank?
    assert_equal 0, MonthlyTeamStatistic.where(team: @tipline_team).count
  end

  test "check:data:statistics skips generating conversations for months before april 1 2023" do
    date = DateTime.new(2023,01,01)

    create_project_media(user: BotUser.smooch_user, team: @tipline_team, created_at: date + 2.weeks)

    CheckStatistics.stubs(:get_statistics).returns(
      {
        platform: 'whatsapp',
        language: 'en',
        start_date: date,
        end_date: date,
      }
    )

    travel_to DateTime.new(2023,01,01)

    out, err = capture_io do
      Rake::Task['check:data:statistics'].invoke
    end
    Rake::Task['check:data:statistics'].reenable

    conversations = MonthlyTeamStatistic.where(team: @tipline_team).pluck(:conversations_24hr).uniq
    assert_equal 1, conversations.count
    assert_nil conversations.first
  end

  test "check:data:statistics logs errors and reports to sentry, but continues calculating" do
    create_project_media(user: BotUser.smooch_user, claim: "Claim: correct team", team: @tipline_team, created_at: @current_date - 2.months)

    # Month 1
    CheckStatistics.stubs(:get_statistics).raises(StandardError.new('test error 1'))
    # Month 2
    CheckStatistics.stubs(:get_statistics).raises(StandardError.new('test error 2'))
    # Month 3
    CheckStatistics.expects(:get_statistics).with(@start_of_month, @current_date, @tipline_team.id, 'whatsapp', 'en').returns(
      {
        platform: 'whatsapp',
        language: 'en',
        start_date: @start_of_month,
        end_date: @current_date,
      }
    )

    CheckSentry.expects(:notify).twice

    travel_to @current_date

    assert_equal 0, MonthlyTeamStatistic.where(team: @tipline_team).count

    assert_raises Check::Statistics::IncompleteRunError do
      out, err = capture_io do
        Rake::Task['check:data:statistics'].invoke
      end
    end
    Rake::Task['check:data:statistics'].reenable

    assert_equal 1, MonthlyTeamStatistic.where(team: @tipline_team).count
  end

  test "check:data:statistics allows generating conversations for months before april 1 2023, with argument" do
    date = DateTime.new(2023,01,01)
    create_project_media(user: BotUser.smooch_user, team: @tipline_team, created_at: date + 2.weeks)
    CheckStatistics.stubs(:get_statistics).returns(
      {
        platform: 'whatsapp',
        language: 'en',
        start_date: date,
        end_date: date,
      }
    )
  
    travel_to DateTime.new(2023,01,01)
    out, err = capture_io do
      # pass in ignore_convo_cutoff: true
      Rake::Task['check:data:statistics'].invoke(true)
    end
    Rake::Task['check:data:statistics'].reenable
  
    conversations = MonthlyTeamStatistic.where(team: @tipline_team).pluck(:conversations_24hr).uniq
    assert_equal 1, conversations.count
    assert !conversations.first.nil?
  end
  
  test "check:data:regenerate_statistics errors if start_date argument is invalid" do
    out, err = capture_io do
      assert_raises(Check::Statistics::ArgumentError) do
        Rake::Task['check:data:regenerate_statistics'].invoke("invalid_date")
      end
    end
    Rake::Task['check:data:regenerate_statistics'].reenable
  
    assert_match /Invalid or missing start_date argument/, err
  end
  
  test "check:data:regenerate_statistics regenerates stats from the provided start date" do
    start_date = "2023-04-01"
    previous_month_start =  DateTime.new(2023,4,1,0,0,0)
    previous_month_end = DateTime.new(2023,4,30,23,59,59)
  
    other_workspace_with_stats = create_team
  
    team_stat_one = create_monthly_team_statistic(team: @tipline_team, language: 'en', start_date: previous_month_start, end_date: previous_month_end)
    team_stat_two = create_monthly_team_statistic(team: @tipline_team, language: 'es', start_date: @start_of_month, end_date: @current_date)
    team_stat_three = create_monthly_team_statistic(team: other_workspace_with_stats, language: 'en', start_date: @start_of_month, end_date: @current_date)
  
    CheckStatistics.stubs(:number_of_newsletters_sent).with(@tipline_team.id, team_stat_one.start_date, team_stat_one.end_date, 'en').returns(100)
    CheckStatistics.expects(:number_of_newsletters_sent).with(@tipline_team.id, team_stat_two.start_date, team_stat_two.end_date, 'es').returns(300)
    CheckStatistics.expects(:number_of_newsletters_sent).with(other_workspace_with_stats.id, team_stat_three.start_date, team_stat_three.end_date, 'en').returns(400)
    travel_to @current_date
  
    out, err = capture_io do
      Rake::Task['check:data:regenerate_statistics'].invoke(start_date)
    end
    Rake::Task['check:data:regenerate_statistics'].reenable
  
    assert err.blank?
  
    # en, previous month
    stats_one = MonthlyTeamStatistic.find_by(team: @tipline_team, language: 'en', start_date: previous_month_start)
    assert_equal @tipline_team.id, stats_one.team_id
    assert_equal previous_month_start.to_i, stats_one.start_date.to_i
    assert_equal previous_month_end.to_i, stats_one.end_date.to_i
    assert_equal 'en', stats_one.language
    assert_equal 100, stats_one.unique_newsletters_sent
  
    # es, current month
    stats_two = MonthlyTeamStatistic.find_by(team: @tipline_team, language: 'es', start_date: @start_of_month)
    assert_equal @tipline_team.id, stats_two.team_id
    assert_equal @start_of_month.to_i, stats_two.start_date.to_i
    assert_equal @current_date.to_i, stats_two.end_date.to_i
    assert_equal 'es', stats_two.language
    assert_equal 300, stats_two.unique_newsletters_sent
  
    # second workspace - en, current month
    stats_three = MonthlyTeamStatistic.find_by(team: other_workspace_with_stats, language: 'en', start_date: @start_of_month)
    assert_equal other_workspace_with_stats.id, stats_three.team_id
    assert_equal @start_of_month.to_i, stats_three.start_date.to_i
    assert_equal @current_date.to_i, stats_three.end_date.to_i
    assert_equal 'en', stats_three.language
    assert_equal 400, stats_three.unique_newsletters_sent
  end
  
  test "check:data:regenerate_statistics doesn't explode if tipline has been disabled, and sets newsletters to nil" do
    start_date = "2023-04-01"
    random_team = create_team
    create_monthly_team_statistic(team: random_team, language: 'es', start_date: @start_of_month, end_date: @current_date)
  
    travel_to @current_date
  
    out, err = capture_io do
      Rake::Task['check:data:regenerate_statistics'].invoke(start_date)
    end
    Rake::Task['check:data:regenerate_statistics'].reenable
  
    assert err.blank?
  
    stats_one = MonthlyTeamStatistic.first
    assert_nil stats_one.unique_newsletters_sent
  end  
end
