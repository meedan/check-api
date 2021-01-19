require_relative '../test_helper'

class ErrorNotificationTest < ActiveSupport::TestCase

  test "should notify error when airbrake is configured" do
    Airbrake.stubs(:configured?).returns(true)
    Airbrake.stubs(:notify).returns('Notify airbrake')

    assert_equal 'Notify airbrake', Team.notify_error(StandardError.new('Invalid team'))

    Airbrake.unstub(:configured?)
    Airbrake.unstub(:notify)
  end

end
