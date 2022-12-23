require_relative '../../test_helper'

class StatisticsTaskTest < ActiveSupport::TestCase
  # override default test setup
  def before_all
    Check::Application.load_tasks
  end

  def setup
    # Set up tipelines and add some data
    @current_date = DateTime.new(2022,5,15)
    @team = create_team(slug: 'test-team')
    create_team_bot_installation(team_id: @team.id, user_id: BotUser.smooch_user.id)
    create_tipline_subscription(team_id: @team.id, platform: 'WhatsApp', language: 'en')
    create_tipline_subscription(team_id: @team.id, platform: 'Telegram', language: 'es')
    TeamBotInstallation.any_instance.stubs(:smooch_enabled_integrations).returns({whatsapp: 'foo'})

    # Create current data for team we care about and another team we don't
    3.times{|i| create_project_media(user: BotUser.smooch_user, claim: "Claim: correct team #{i}", team: @team, created_at: @current_date) }
    3.times{|i| create_project_media(user: BotUser.smooch_user, claim: "Claim: other team #{i}", created_at: @current_date) }
  end

  def teardown
    travel_back
    Rails.cache.delete("data:report:#{@team.id}")
  end

  test "check:data:statistics regenerates all historic data for team if cache key missing" do
    april_date = @current_date - 1.month
    march_date = @current_date - 2.months
    february_date = @current_date - 3.month
    january_date = @current_date - 4.months

    # Create historic data
    create_project_media(user: BotUser.smooch_user, claim: "Claim: correct team from January", team: @team, created_at: january_date)

    CheckStatistics.expects(:generate_statistics_row).with(@current_date.beginning_of_month, @current_date.end_of_month, 'test-team', :whatsapp, 'en').returns(['id-may'])
    CheckStatistics.expects(:generate_statistics_row).with(april_date.beginning_of_month, april_date.end_of_month, 'test-team', :whatsapp, 'en').returns(['id-april'])
    CheckStatistics.expects(:generate_statistics_row).with(march_date.beginning_of_month, march_date.end_of_month, 'test-team', :whatsapp, 'en').returns(['id-march'])
    CheckStatistics.expects(:generate_statistics_row).with(february_date.beginning_of_month, february_date.end_of_month, 'test-team', :whatsapp, 'en').returns(['id-february'])
    CheckStatistics.expects(:generate_statistics_row).with(january_date.beginning_of_month, january_date.end_of_month, 'test-team', :whatsapp, 'en').returns(['id-january'])

    travel_to @current_date

    assert_nil Rails.cache.read("data:report:#{@team.id}")
    out, err = capture_io do
      Rake::Task['check:data:statistics'].invoke(@team.slug)
    end
    assert err.blank?

    report = Rails.cache.read("data:report:#{@team.id}")
    assert_equal 5, report.length # For each month Jan - May
    assert_equal "id-january", report.first["ID"] # Chronological sort
    assert_equal "id-may", report.last["ID"]
  end

  test "check:data:statistics only calculates data for current month and leaves historic months as-is, if cache key present" do
    CheckStatistics.expects(:generate_statistics_row).with(@current_date.beginning_of_month, @current_date.end_of_month, 'test-team', :whatsapp, 'en').returns(['id-may'])

    travel_to @current_date

    Rails.cache.write("data:report:#{@team.id}", [{"ID" => "id-january"}])
    out, err = capture_io do
      Rake::Task['check:data:statistics'].invoke(@team.slug)
    end
    assert err.blank?

    report = Rails.cache.read("data:report:#{@team.id}")
    assert_equal 2, report.length # New and old
    assert_equal "id-january", report.first["ID"] # Chronological sort
    assert_equal "id-may", report.last["ID"]
  end

  test "check:data:statistics re-calculates data for current month when present on cache" do
    current_month_id = CheckStatistics.get_id('test-team', :whatsapp, @current_date.beginning_of_month, @current_date.end_of_month, "en")

    CheckStatistics.expects(:generate_statistics_row).with(@current_date.beginning_of_month, @current_date.end_of_month, 'test-team', :whatsapp, 'en').returns([current_month_id, "Updated org name"])

    travel_to @current_date

    Rails.cache.write("data:report:#{@team.id}", [{"ID" => "id-january"}, {"ID" => current_month_id}])
    out, err = capture_io do
      Rake::Task['check:data:statistics'].invoke(@team.slug)
    end
    assert err.blank?

    report = Rails.cache.read("data:report:#{@team.id}")
    assert_equal 2, report.length # Update in-place
    assert_equal current_month_id, report.last["ID"]
    assert_equal "Updated org name", report.last["Org"]
  end
end
