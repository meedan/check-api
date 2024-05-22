require_relative '../test_helper'

class SecurityMailerTest < ActionMailer::TestCase
  def setup
    WebMock.stub_request(:get, /ipinfo\.io/).to_return(body: { country: 'US', city: 'San Francisco' }.to_json, status: 200)
  end

  def teardown
  end

  test "should send security notification" do
    user = create_user
    la = create_login_activity user: user, success: true
    email = SecurityMailer.notify(user.id, 'ip', la.id)
    assert_emails 1 do
      email.deliver_now
    end
    email = SecurityMailer.notify(user.id, 'device', la.id)
    assert_emails 1 do
      email.deliver_now
    end
    email = SecurityMailer.notify(user.id, 'failed', la.id)
    assert_emails 1 do
      email.deliver_now
    end
    Geocoder.stubs(:search).returns([OpenStruct.new(data: { 'loc' => OpenStruct.new({ city: 'Cairo', country: 'Egypt' }) })])
    la = create_login_activity user: user, success: true
    email = SecurityMailer.notify(user.id, 'ip', la.id)
    assert_emails 1 do
      email.deliver_now
    end
    Geocoder.unstub(:search)
    # should not notify if email empty
    user.update_columns(email: '')
    email = SecurityMailer.notify(user.id, 'ip', la.id)
    assert_emails 0 do
      email.deliver_now
    end
    user.update_columns(email: nil)
    email = SecurityMailer.notify(user.id, 'ip', la.id)
    assert_emails 0 do
      email.deliver_now
    end
  end

  test "should send custom notification" do
    user = create_user
    subject = 'email subject'
    email = SecurityMailer.custom_notification(user.id, subject)
    assert_emails 1 do
      email.deliver_now
    end
  end
end
