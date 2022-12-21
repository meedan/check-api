require_relative '../../test_helper'

class StatisticsTest < ActiveSupport::TestCase
  # override default test setup
  def before_all; end
  def after_all; end
  def setup
    Check::Application.load_tasks
  end
  def teardown; end

  test "check:data:statistics fails gracefully with bad input" do
    out, err = capture_io do
      Rake::Task['check:data:statistics'].invoke('fake-team')
    end
    # I think this should report to error instead; not sure why we suppress logging
    assert_match /Please provide a list of workspace slugs/, out
  end

  test "check:data:statistics caches statistics data for currently-enabled tiplines current month" do
    team = create_team(slug: 'test-team')
    create_team_bot_installation(team_id: team.id, user_id: BotUser.smooch_user.id)
    create_tipline_subscription(team_id: team.id, platform: 'WhatsApp', language: 'en')
    create_tipline_subscription(team_id: team.id, platform: 'Telegram', language: 'es')

    fake_current_date = DateTime.new(2022,5,15)
    3.times{|i| create_project_media(user: BotUser.smooch_user, claim: "Claim: correct team #{i}", team: team, created_at: fake_current_date) }
    3.times{|i| create_project_media(user: BotUser.smooch_user, claim: "Claim: other team #{i}", created_at: fake_current_date) }

    start_of_month = DateTime.new(2022,5,1,0,0,0).beginning_of_month
    end_of_month = DateTime.new(2022,5,31,23,59,59).end_of_month

    TeamBotInstallation.any_instance.stubs(:smooch_enabled_integrations).returns({whatsapp: 'foo'})
    CheckStatistics.expects(:get_statistics).with(start_of_month, end_of_month, 'test-team', :whatsapp, 'en').returns(['id-1234'])

    assert_nil Rails.cache.read("data:report:#{team.id}")

    travel_to fake_current_date
    Rake::Task['check:data:statistics'].invoke(team.slug)

    assert_not_nil Rails.cache.read("data:report:#{team.id}")
  ensure
    travel_back
  end
end
