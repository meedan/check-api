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
end
