require_relative '../test_helper'

class CheckSentryTest < ActiveSupport::TestCase
  test "should log error" do
    error = StandardError.new('test error')

    Rails.logger.expects(:error).with(error)

    CheckSentry.notify(error)
  end

  test "should notify sentry with passed application data" do
    error = StandardError.new('test error')

    scope_mock = mock('scope')
    scope_mock.expects(:set_context).with('application', {thing: 'one', other_thing: 'two'})

    Sentry.expects(:capture_exception).with(error)
    Sentry.stubs(:with_scope).yields(scope_mock).returns(true)

    CheckSentry.notify(error, thing: 'one', other_thing: 'two')
  end

  test ".set_user_info should set user ID and optionally set the team ID" do
    error = StandardError.new('test error')

    scope_mock = mock('scope')
    scope_mock.expects(:set_context).with('application', {'user.team_id' => 1, 'api_key_id' => nil})

    Sentry.expects(:set_user).with(id: 5)
    Sentry.stubs(:configure_scope).yields(scope_mock).returns(true)

    CheckSentry.set_user_info(5, team_id: 1)
  end

  test ".set_user_info should optionally send API key information" do
    error = StandardError.new('test error')

    scope_mock = mock('scope')
    scope_mock.expects(:set_context).with('application', {'user.team_id' => nil, 'api_key_id' => 3})

    Sentry.expects(:set_user).with(id: nil)
    Sentry.stubs(:configure_scope).yields(scope_mock).returns(true)

    CheckSentry.set_user_info(nil, api_key_id: 3)
  end
end
