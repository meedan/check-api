require_relative '../test_helper'

class RegistrationMailerTest < ActionMailer::TestCase

  test "should send welcome email" do
    u = create_user email: 'test@localhost', password: 'testA@12'
    email = RegistrationMailer.welcome_email(u)

    assert_emails 1 do
      email.deliver_now
    end

    assert_match email.from.first, CheckConfig.get('default_mail')
    assert_equal ['test@localhost'], email.to
    assert_match /testA@12/, email.body.parts.first.to_s
  end

  test "should send email for mail duplicate" do
    u = create_user email: 'test@localhost'
    email = RegistrationMailer.duplicate_email_detection(u, u)
    assert_emails 1 do
      email.deliver_now
    end
    assert_match email.from.first, CheckConfig.get('default_mail')
    assert_equal ['test@localhost'], email.to
  end

end
