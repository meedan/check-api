require_relative '../test_helper'

class BotUserTest < ActiveSupport::TestCase
  def setup
    super
  end

  test "should have BotUser type" do
    assert_equal 'BotUser', BotUser.new.type
    assert_equal 'BotUser', create_bot_user.type
  end

  test "should not have email null" do
    b = create_bot_user email: 'bot@meedan.com'
    assert_nil b.email
  end

  test "should not have password null" do
    b = create_bot_user password: random_complex_password
    assert_nil b.password
  end

  test "should never be admin" do
    b = create_bot_user is_admin: true
    assert !b.is_admin
  end

  test "should lookup bots by helper functions" do
    b = create_bot_user login: "check_bot"
    assert_equal BotUser.check_bot_user.login, b.login
  end

  test "should have a unique API key" do
    a = create_api_key
    assert_nothing_raised do
      b = create_bot_user api_key_id: a.id
      assert_equal a, b.api_key
    end
    assert_raises ActiveRecord::RecordInvalid do
      create_bot_user api_key_id: a.id
    end
  end

  test "should have bot events" do
    bu = create_team_bot set_events: [{ event: 'create_project_media', graphql: nil }, { event: 'update_project_media', graphql: nil }]
    assert_equal 'create_project_media,update_project_media', bu.bot_events
  end

  test "should be a bot" do
    bu = create_bot_user
    assert bu.is_bot
  end

  test "should be core" do
    bu = BotUser.new
    bu.login = 'smooch'
    assert bu.core?
    bu.login = 'test'
    assert !bu.core?
    Module.stubs(:const_defined?).raises(StandardError.new)
    assert !bu.core?
    Module.unstub(:const_defined?)
  end

  test "should convert settings to JSON schema" do
    t = create_team
    b = create_bot_user
    s = [
      { name: 'foo', type: 'array', items: [] },
      { name: 'bar', type: 'object', properties: {} },
      { name: 'smooch_template_locales' },
      { name: 'smooch_workflows', type: 'array', items: { 'properties' => { 'smooch_message_smooch_bot_tos' => { 'properties' => {} } } } }
    ]
    b.set_settings(s)
    b.save!
    assert_match /items/, b.settings_as_json_schema(false, t.slug)
    assert_match /properties/, b.settings_as_json_schema(false, t.slug)
    assert_match /uniqueItems/, b.settings_as_json_schema(false, t.slug)
  end

  test "should not raise error if table doesn't exist yet" do
    connection = ApplicationRecord.connection
    connection.stubs(:data_source_exists?).raises(ActiveRecord::NoDatabaseError)
    assert_nothing_raised do
      load 'bot_user.rb'
      assert_equal 'BotUser', BotUser.new.type
    end
    connection.unstub(:data_source_exists?)
  end

  test "should notify about event including bot headers" do
    bot_request_url = 'http://bot'
    WebMock.stub_request(:post, bot_request_url).to_return(body: { "success": true }.to_json)
    team = create_team
    team_bot = create_team_bot team_author_id: team.id, set_events: [{ event: 'create_project_media', graphql: nil }], set_request_url: bot_request_url

    data = {
      event: 'create_project_media',
      team: team,
      time: Time.now,
      data: nil,
      user_id: team_bot.id,
    }

    team_bot.call(data)
    assert_not_requested :post, bot_request_url,
      headers: {'X-Header' => 'ABCDEFG'}, body: data.to_json,
      times: 1

    team_bot.set_headers = { 'X-Header' => 'ABCDEFG' }
    team_bot.save!
    team_bot.call(data)
    assert_requested :post, bot_request_url,
      headers: {'X-Header' => 'ABCDEFG'}, body: data.to_json,
      times: 1

    WebMock.reset!
  end

  test "should get events from bot" do
    team = create_team
    team_bot = create_team_bot team_author_id: team.id, set_events: [{ event: 'create_project_media', graphql: nil }, { event: 'publish_report', graphql: nil }]
    assert team_bot.is_bot
    assert_equal 'create_project_media,publish_report', team_bot.bot_events
  end

  test "should fail events validation if its events is an empty array, and the bot is not approved" do
    # We want to allow events to be an empty array only for our core bots (we can check for that by checking if they are approved)
    assert_raises ActiveRecord::RecordInvalid do
      create_team_bot set_events: [], set_approved: false
    end
  end
end
