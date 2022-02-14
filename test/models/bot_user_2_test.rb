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
end
