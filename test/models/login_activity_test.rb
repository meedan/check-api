require_relative '../test_helper'

class LoginActivityTest < ActiveSupport::TestCase
  def setup
    super
    require 'sidekiq/testing'
    Sidekiq::Testing.inline!
  end
  
  test "should create login activity" do
    assert_difference 'LoginActivity.count' do
      create_login_activity
    end
  end

  test "should get user" do
    u = create_user
    la = create_login_activity user: u
    assert_equal la.user_id, u.id
    assert_equal la.get_user.id, u.id
    la = create_login_activity user: nil, identity: u.email
    assert_nil la.user_id
    assert_equal la.get_user.id, u.id
  end

  test "should notify" do
    u = create_user
    la = create_login_activity user: u
    assert la.should_notify?(u, 'success')
    assert la.should_notify?(u, 'failed')
    u.settings = {send_successful_login_notifications: false, send_failed_login_notifications: false}
    u.save!
    assert_not la.should_notify?(u, 'success')
    assert_not la.should_notify?(u, 'failed')
    u.settings = {send_successful_login_notifications: true, send_failed_login_notifications: true}
    u.save!
    assert la.should_notify?(u, 'success')
    assert la.should_notify?(u, 'failed')
    # should not notify unconfirmed user
    u.email = 'test@local.com';u.save!
    u = u.reload
    assert_not u.is_confirmed?
    assert_not la.should_notify?(u, 'success')
    assert_not la.should_notify?(u, 'failed')
  end

  test "should send security notification for device change" do
    user = create_user
    create_login_activity user_agent: 'test', user: user, success: true
    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      create_login_activity user: user, success: false
    end
    assert_difference 'ActionMailer::Base.deliveries.size', 1 do
      create_login_activity user: user, success: true
    end
    la = user.login_activities.last
    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      create_login_activity ip: la.ip, user_agent: la.user_agent, user: user, success: true
    end
  end

  test "should send security notification for ip change" do
    user = create_user
    create_login_activity user: user, success: true
    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      create_login_activity user: user, success: false
    end
    assert_difference 'ActionMailer::Base.deliveries.size', 1 do
      create_login_activity user: user, success: true
    end
    la = user.login_activities.last
    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      create_login_activity ip: la.ip, user_agent: la.user_agent, user: user, success: true
    end
  end

  test "should send one successfull email if both ip and device changed" do
    user = create_user
    create_login_activity user_agent: 'test', user: user, success: true
    assert_difference 'ActionMailer::Base.deliveries.size', 1 do
      create_login_activity user: user, success: true
    end
  end

  test "should send security notification for failed attempts" do
    user = create_user
    stub_configs({'failed_attempts' => 4, 'failed_attempts_period' => "1.hour"}) do
      3.times do
        create_login_activity user: user, success: false
      end
      assert_no_difference 'ActionMailer::Base.deliveries.size' do
        create_login_activity user: user, success: true
      end
      assert_difference 'ActionMailer::Base.deliveries.size', 1 do
        create_login_activity user: user, success: false
      end 
    end
  end

  
end
