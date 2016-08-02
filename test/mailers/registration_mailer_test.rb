require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class RegistrationMailerTest < ActionMailer::TestCase

  test "should send welcome email" do
    u = create_user email: 'test@localhost', password: '12345678'
    email = RegistrationMailer.welcome_email(u)
    
    assert_emails 1 do
      email.deliver_now
    end
    
    assert_equal [CONFIG['default_mail']], email.from
    assert_equal ['test@localhost'], email.to
    assert_match /12345678/, email.body.parts.first.to_s
  end
end
