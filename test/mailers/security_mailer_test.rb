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

  end
end
