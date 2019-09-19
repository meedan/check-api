require_relative '../test_helper'

class SecurityMailerTest < ActionMailer::TestCase
  test "should send security notification" do
    user = create_user
    la = create_login_activity user: user, success: true
    email = SecurityMailer.notify(user, 'ip', la)
    assert_emails 1 do
      email.deliver_now
    end
    email = SecurityMailer.notify(user, 'device', la)
    assert_emails 1 do
      email.deliver_now
    end
    email = SecurityMailer.notify(user, 'failed', la)
    assert_emails 1 do
      email.deliver_now
    end
    Geocoder.stubs(:search).returns([OpenStruct.new(data: { 'loc' => OpenStruct.new({ city: 'Cairo', country: 'Egypt' }) })])
    la = create_login_activity user: user, success: true
    email = SecurityMailer.notify(user, 'ip', la)
    assert_emails 1 do
      email.deliver_now
    end
    Geocoder.unstub(:search)
    # should not notify if email empty
    user.update_columns(email: '')
    email = SecurityMailer.notify(user, 'ip', la)
    assert_emails 0 do
      email.deliver_now
    end
    user.update_columns(email: nil)
    email = SecurityMailer.notify(user, 'ip', la)
    assert_emails 0 do
      email.deliver_now
    end
  end
end
