require_relative '../../../test_helper'

class TiplineMessageStatisticsTest < ActiveSupport::TestCase
  def before_all; end
  def after_all; end

  def setup
    @team_1 = create_team
    @time = DateTime.new(2023,5,20)
    Check::TiplineMessageStatistics.reset_conversation_caches
  end

  def teardown
    Check::TiplineMessageStatistics.reset_conversation_caches
  end

  test ".monthly_conversations calculates total interactions with a tipline in a 24-hour period for a given month, determined by a unique user id" do
    create_tipline_message(team_id: @team_1.id, uid: '12345', platform: "Telegram", language: "en", sent_at: @time - 2.hours) # 1
    create_tipline_message(team_id: @team_1.id, uid: '12345', platform: "Telegram", language: "en", sent_at: @time) # skipped, same day
    create_tipline_message(team_id: @team_1.id, uid: '12345', platform: "Telegram", language: "en", sent_at: @time - 1.week) # 2, different day
    create_tipline_message(team_id: @team_1.id, uid: 'abcdef', platform: "Telegram", language: "en", sent_at: @time) # 3, different uid

    convo_count = Check::TiplineMessageStatistics.new(@team_1.id).monthly_conversations("Telegram", "en", @time.beginning_of_month, @time.end_of_month)
    assert_equal 3, convo_count
  end

  test ".monthly_conversations returns monthly conversations for given team, time period, platform and language" do
    team_2 = create_team

    create_tipline_message(team_id: @team_1.id, uid: '12345', platform: "Telegram", language: "en", sent_at: @time)

    create_tipline_message(team_id: @team_1.id, uid: '12345', platform: "Telegram", language: "en", sent_at: @time - 2.months) # wrong timeframe
    create_tipline_message(team_id: @team_1.id, platform: "WhatsApp", language: "en", sent_at: @time - 1.hour) # wrong platform
    create_tipline_message(team_id: @team_1.id, uid: '12345', platform: "Telegram", language: "pt", sent_at: @time) # wrong language
    create_tipline_message(team_id: team_2.id, uid: '12345', platform: "Telegram", language: "en", sent_at: @time) # wrong team

    convo_count = Check::TiplineMessageStatistics.new(@team_1.id).monthly_conversations("Telegram", "en", @time.beginning_of_month, @time.end_of_month)
    assert_equal 1, convo_count
  end

  test ".monthly_conversations caches a conversation index for language, platform, and uid when finished calculating for a full month" do
    recent_convo_1 = create_tipline_message(team_id: @team_1.id, uid: '12345', platform: "Telegram", language: "en", sent_at: @time) # 1
    recent_convo_2 = create_tipline_message(team_id: @team_1.id, uid: 'abcdef', platform: "Telegram", language: "en", sent_at: @time) # 3, different uid

    Check::TiplineMessageStatistics.new(@team_1.id).monthly_conversations("Telegram", "en", @time.beginning_of_month, @time.end_of_month)
    assert_equal recent_convo_1.sent_at, Check::TiplineMessageStatistics.cache_read("12345", "en", "Telegram")
    assert_equal recent_convo_2.sent_at, Check::TiplineMessageStatistics.cache_read("abcdef", "en", "Telegram")
  end

  test ".monthly_conversations does not cache a conversation index when only calculating for a partial month" do
    recent_convo_1 = create_tipline_message(team_id: @team_1.id, uid: '12345', platform: "Telegram", language: "en", sent_at: @time) # 1
    recent_convo_2 = create_tipline_message(team_id: @team_1.id, uid: 'abcdef', platform: "Telegram", language: "en", sent_at: @time) # 3, different uid

    Check::TiplineMessageStatistics.new(@team_1.id).monthly_conversations("Telegram", "en", @time.beginning_of_month, (@time.end_of_month - 1.day))
    assert_nil Check::TiplineMessageStatistics.cache_read("12345", "en", "Telegram")
    assert_nil Check::TiplineMessageStatistics.cache_read("abcdef", "en", "Telegram")
  end

  test ".monthly_conversations uses the cached conversation index as the starting point for calcluations when present" do
    month_boundary = DateTime.new(2023,5,1,12)
    create_tipline_message(team_id: @team_1.id, uid: '12345', platform: "Telegram", language: "en", sent_at: month_boundary - 13.hours) # 1, april
    create_tipline_message(team_id: @team_1.id, uid: '12345', platform: "Telegram", language: "en", sent_at: month_boundary + 1.hour) # skipped, same day
    create_tipline_message(team_id: @team_1.id, uid: '12345', platform: "Telegram", language: "en", sent_at: month_boundary + 1.week) # 1, may

    assert_equal 1, Check::TiplineMessageStatistics.new(@team_1.id).monthly_conversations("Telegram", "en", (month_boundary - 1.month).beginning_of_month, (month_boundary - 1.month).end_of_month) # April
    # For the test below, we send in a May 1st cutoff so that it would not be able to re-calculate the conversation index from scratch,
    # and instead we can be sure that it is relying from the cached version set in the line above
    assert_equal 1, Check::TiplineMessageStatistics.new(@team_1.id).monthly_conversations("Telegram", "en", month_boundary.beginning_of_month, month_boundary.end_of_month, month_boundary) # May
  end

  test ".monthly_conversations returns 0 if there are no UIDs who have sent messages that month" do
    assert_equal 0, Check::TiplineMessageStatistics.new(@team_1.id).monthly_conversations("Telegram", "en", @time.beginning_of_month, @time.end_of_month)
  end

  test "standardizes time-like classes into the same hash key" do
    activesupport_date = Team.last.created_at
    datetime_date = activesupport_date.to_datetime
    time_date = activesupport_date.to_time

    assert_equal Check::TiplineMessageStatistics.date_to_string(datetime_date), Check::TiplineMessageStatistics.date_to_string(activesupport_date)
    assert_equal Check::TiplineMessageStatistics.date_to_string(time_date), Check::TiplineMessageStatistics.date_to_string(activesupport_date)
  end
end
