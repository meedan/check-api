require_relative '../test_helper'

class CheckNotificationTest < ActiveSupport::TestCase
  test "should call pusher with message and code" do
    Sidekiq::Testing.fake! do
      notifications = 0
      assert_equal notifications, CheckPusher::Worker.jobs.size
      CheckNotification::InfoCodes::ALL.each do |error|
        CheckNotification::InfoMessages.send(error.downcase)
        notifications += 1
      end
      assert_operator notifications, :>, 0
      assert_equal notifications, CheckPusher::Worker.jobs.size
    end
  end

  test "should notify airbrake and not call Pusher when send notification with undefined info" do
    Airbrake.stubs(:configured?).returns(true)
    Airbrake.stubs(:notify).returns('notified airbrake')
    Sidekiq::Testing.fake! do
      assert_equal 0, CheckPusher::Worker.jobs.size
      assert_equal 'notified airbrake', CheckNotification::InfoMessages.send('unexistent_info_code')
      assert_equal 0, CheckPusher::Worker.jobs.size
    end
    Airbrake.unstub(:configured?)
    Airbrake.unstub(:notify)
  end
end
