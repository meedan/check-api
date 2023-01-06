require_relative '../../test_helper'

class StatisticsTest < ActiveSupport::TestCase
  # override default test setup
  def before_all; end
  def after_all; end
  def setup
    Check::Application.load_tasks
  end
  def teardown; end

  test "check:data:statistics caches statistics data for any workspaces with tipline data" do
    fake_current_date = DateTime.new(2022,5,15)

    other_team = create_team(slug: 'other-team')
    other_team_user = create_user(team: other_team)
    3.times{|i| create_project_media(user: other_team_user, claim: "Claim: other team #{i}", team: other_team, created_at: fake_current_date) }

    tipline_team = create_team(slug: 'test-team')
    create_team_bot_installation(team_id: tipline_team.id, user_id: BotUser.smooch_user.id)
    create_tipline_subscription(team_id: tipline_team.id, platform: 'WhatsApp', language: 'en')
    create_tipline_subscription(team_id: tipline_team.id, platform: 'Telegram', language: 'es')
    3.times{|i| create_project_media(user: BotUser.smooch_user, claim: "Claim: correct team #{i}", team: tipline_team, created_at: fake_current_date) }

    start_of_month = DateTime.new(2022,5,1,0,0,0).beginning_of_month
    end_of_month = DateTime.new(2022,5,31,23,59,59).end_of_month

    TeamBotInstallation.any_instance.stubs(:smooch_enabled_integrations).returns({whatsapp: 'foo'})
    CheckStatistics.expects(:get_statistics).with(start_of_month, end_of_month, 'test-team', :whatsapp, 'en').returns(['id-1234'])

    assert_nil Rails.cache.read("data:report:#{tipline_team.id}")

    travel_to fake_current_date
    Rake::Task['check:data:statistics'].invoke

    assert_nil Rails.cache.read("data:report:#{other_team.id}")
    assert_not_nil Rails.cache.read("data:report:#{tipline_team.id}")
  ensure
    travel_back
  end
end
