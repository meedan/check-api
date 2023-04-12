require_relative '../test_helper'

class MonthlyTeamStatisticTest < ActiveSupport::TestCase
  # override default test setup
  def before_all; end
  def after_all; end

  def setup
    MonthlyTeamStatistic.delete_all
    Team.delete_all
  end

  def teardown; end

  test "is invalid without required fields" do
    stat = MonthlyTeamStatistic.new

    assert !stat.valid?

    team = create_team(name: "Fake team")
    stat = MonthlyTeamStatistic.new(team: team, start_date: DateTime.now, end_date: DateTime.now, platform: "telegram", language: "en")

    assert stat.valid?
  end

  test "is invalid if not unique for team, platform, language, and start_date" do
    team = create_team
    create_monthly_team_statistic(team: team, platform: 'whatsapp', language: 'en', start_date: DateTime.new(2022,1,2))

    stat = MonthlyTeamStatistic.new(team: team, platform: 'whatsapp', language: 'en', start_date: DateTime.new(2022,1,2), end_date: DateTime.new(2022,2,3))
    assert !stat.valid?

    stat.start_date = DateTime.new(2022,2,3)
    assert stat.valid?
  end

  test ".formatted_hash presents data with human-readable keys" do
    team = create_team(name: "Fake team")

    stat = MonthlyTeamStatistic.create(
      team: team,
      platform: "whatsapp",
      language: "en",
      start_date: DateTime.new(2020,4,1),
      end_date: DateTime.new(2020,4,15),
      conversations: 1, # deprecated, not included in .formatted_hash
      conversations_24hr: 23, # removed for now
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
    )

    hash = stat.formatted_hash

    assert_equal hash["ID"], stat.id
    assert_equal hash["Platform"], "WhatsApp"
    assert_equal hash["Language"], "en"
    assert_equal hash["Month"], "Apr 2020"
    assert_equal hash["Average messages per day"], 2
    assert_equal hash["Unique users"], 3
    assert_equal hash["Returning users"], 4
    assert_equal hash["Valid new requests"], 5
    assert_equal hash["Published native reports"], 6
    assert_equal hash["Published imported reports"], 7
    assert_equal hash["Requests answered with a report"], 8
    assert_equal hash["Reports sent to users"], 9
    assert_equal hash["Unique users who received a report"], 10
    assert_equal hash["Average (median) response time"], "less than a minute"
    assert_equal hash["Unique newsletters sent"], 12
    assert_equal hash["New newsletter subscriptions"], 13
    assert_equal hash["Newsletter cancellations"], 14
    assert_equal hash["Current subscribers"], 15
  end

  test ".formatted_median_response_time formats integer value" do
    stat = MonthlyTeamStatistic.new(median_response_time: 11)

    assert_equal "less than a minute", stat.formatted_median_response_time
  end

  test ".formatted_median_response_time does not choke when nil" do
    stat = MonthlyTeamStatistic.new(median_response_time: nil)

    assert_nil stat.formatted_median_response_time
  end

  test ".month formats the start date to MonthName Year" do
    stat = MonthlyTeamStatistic.new(start_date: DateTime.new(2020,04,15))

    assert_equal "Apr 2020", stat.month
  end

  test "sets default of - if value is not present" do
    team = create_team(name: "Fake team")
    stat = MonthlyTeamStatistic.create(team: team, unique_newsletters_sent: nil)

    assert_equal '-', stat.formatted_hash["Unique newsletters sent"]
  end

  test ".platform_name sets human-readable name for platform" do
    stat = MonthlyTeamStatistic.new(platform: 'whatsapp')

    assert_equal "WhatsApp", stat.platform_name
  end

  test "should handle cache" do
    team_id, uid, language, platform = 1, 'foo', 'en', 'whatsapp'
    Rails.cache.write(Check::TiplineMessageStatistics.cache_key(team_id, uid, language, platform), 'Bar')
    assert_equal 'Bar', Check::TiplineMessageStatistics.cache_read(team_id, uid, language, platform)
    Check::TiplineMessageStatistics.cache_reset(team_id, uid, language, platform)
    assert_nil Check::TiplineMessageStatistics.cache_read(team_id, uid, language, platform)
  end
end
