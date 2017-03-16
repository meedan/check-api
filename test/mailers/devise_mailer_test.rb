require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class DeviseMailerTest < ActionMailer::TestCase

  test "should send confirmation e-mail" do
    u = create_user name: 'Test User', provider: '', email: 'test@mail.com'

    email = DeviseMailer.confirmation_instructions(u, '123456')

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [CONFIG['default_mail']], email.from
    assert_equal ['test@mail.com'], email.to
    assert_match "confirmation_token=#{u.confirmation_token}", email.body.parts.first.to_s
  end

  test "should send reset password instructions" do
    u = create_user name: 'Test User', provider: '', email: 'test@mail.com'
    email = DeviseMailer.reset_password_instructions(u, '12345')

    assert_emails 1 do
      email.deliver_now
    end
    assert_equal [CONFIG['default_mail']], email.from
    assert_equal ['test@mail.com'], email.to
    assert_match "reset_password_token=12345", email.body.to_s
  end

end
