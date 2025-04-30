require_relative '../test_helper'

class BotUser2Test < ActiveSupport::TestCase
  test "should get events" do
    assert_kind_of String, BotUser.new.bot_events
  end

  test "should be a bot" do
    assert BotUser.new.is_bot
  end

  test "should have settings as JSON schema" do
    t = create_team
    b = create_bot_user team: t
    b.set_settings = [{ type: 'object', name: 'foo_bar' }, { name: 'smooch_template_locales' }, { name: 'smooch_workflows', type: 'array', items: { properties: { smooch_message_smooch_bot_tos: { properties: {} } } } }]
    b.save!
    assert_kind_of String, b.settings_as_json_schema(false, t.slug)
    assert_kind_of String, b.settings_ui_schema
  end

  test "should get users" do
    assert_nothing_raised do
      BotUser.alegre_user
      BotUser.fetch_user
      BotUser.keep_user
      BotUser.smooch_user
      BotUser.check_bot_user
    end
  end

  test "should not change role when change team bot settings" do
    team = create_team
    team_bot = create_team_bot team_author_id: team.id
    tbi = TeamBotInstallation.where(team_id: team.id, user_id: team_bot.id).last
    tbi.role = 'admin'
    tbi.save
    assert_equal 'admin', TeamBotInstallation.find(tbi.id).role
    team_bot.set_headers = { 'X-Header' => 'ABCDEFG' }
    team_bot.save
    assert_equal 'admin', TeamBotInstallation.find(tbi.id).role
  end

  test "should get team author" do
    team = create_team
    team_bot = create_team_bot team_author_id: team.id
    assert_equal team, team_bot.team_author
  end

  test "should uninstall bot" do
    b = create_team_bot set_approved: true
    t = create_team
    assert_difference 'TeamBotInstallation.count', 1 do
      b.install_to!(t)
    end
    assert_nothing_raised do
      b.installed
      b.installation
    end
    assert_equal 2, b.installations_count
    assert_difference 'TeamBotInstallation.count', -1 do
      b.uninstall_from!(t)
    end
    assert_nothing_raised do
      b.installed
      b.installation
    end
    assert_equal 1, b.installations_count
  end

  test "should get GraphQL result" do
    t = create_team
    b = create_team_bot team: t
    pm = create_project_media team: t
    j = b.graphql_result('id, dbid', pm, t)
    assert_equal pm.id, j['dbid']
  end

  test "should not get GraphQL result" do
    t = create_team
    b = create_team_bot team: t
    pm = create_project_media team: t
    RelayOnRailsSchema.stubs(:execute).raises(StandardError.new)
    j = b.graphql_result('id, dbid', pm, t)
    assert j.has_key?('error')
    RelayOnRailsSchema.unstub(:execute)
  end

  test "should notify bot and get response" do
    url = random_url
    WebMock.stub_request(:post, url).to_return(body: { success: true, foo: 'bar' }.to_json)
    team = create_team
    team_bot = create_team_bot team_author_id: team.id, set_events: [{ event: 'create_project_media', graphql: nil }], set_request_url: url

    data = {
      event: 'create_project_media',
      team: team,
      time: Time.now,
      data: nil,
      user_id: team_bot.id,
    }

    assert_equal 'bar', JSON.parse(team_bot.call(data).body)['foo']
  end

  test "should notify Sentry when bot raises exception on notification" do
    CheckSentry.expects(:notify).once
    BotUser.any_instance.stubs(:notify_about_event).raises(StandardError)
    t = create_team
    pm = create_project_media team: t
    b = create_team_bot team_author_id: t.id, set_approved: true, set_events: [{ event: 'create_project_media', graphql: nil }]
    BotUser.notify_bots('create_project_media', t.id, 'ProjectMedia', pm.id, b)
  end

  test "should not ignore requests by default" do
    b = create_team_bot
    assert !b.should_ignore_request?
  end

  test "should notify Sentry when external bot URL can't be called" do
    CheckSentry.expects(:notify).once
    url = random_url
    WebMock.stub_request(:post, url).to_timeout
    t = create_team
    pm = create_project_media team: t
    b = create_team_bot team_author_id: t.id, set_approved: true, set_events: [{ event: 'create_project_media', graphql: nil }], set_request_url: url
    assert_nothing_raised do
      b.call({})
    end
  end

  test "should capture error if bot can't be called" do
    Bot::Alegre.stubs(:run).raises(StandardError)
    b = create_bot_user login: 'alegre'
    assert_nothing_raised do
      b.call({})
    end
  end

  test "should raise validation error is events is empty" do
    b = create_bot_user
    b.set_events = []
    assert !b.valid?
  end
end
