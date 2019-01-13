require_relative '../test_helper'

class UserTest < ActiveSupport::TestCase
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
    b = create_bot_user password: '12345678'
    assert_nil b.password
  end

  test "should never be admin" do
    b = create_bot_user is_admin: true
    assert !b.is_admin
  end

  test "should have a unique API key" do
    a = create_api_key
    assert_raises ActiveRecord::RecordInvalid do
      create_bot_user api_key_id: nil
    end
    assert_nothing_raised do
      b = create_bot_user api_key_id: a.id
      assert_equal a, b.api_key
    end
    assert_raises ActiveRecord::RecordInvalid do
      create_bot_user api_key_id: a.id
    end
  end

  test "should have bot events" do
    bu = create_bot_user
    create_team_bot bot_user_id: bu.id, events: [{ event: 'create_project_media', graphql: nil }, { event: 'update_project_media', graphql: nil }]
    assert_equal 'create_project_media,update_project_media', bu.bot_events
  end

  test "should be a bot" do
    bu = create_bot_user
    assert bu.is_bot
  end
end
