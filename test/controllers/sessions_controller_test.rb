require_relative '../test_helper'

class SessionsControllerTest < ActionController::TestCase
  def setup
    super
    @controller = Api::V1::SessionsController.new
    @request.env["devise.mapping"] = Devise.mappings[:api_user]
    sign_out('user')
    User.current = nil
  end

  test "should login using email" do
    u = create_user login: 'test', password: '12345678', password_confirmation: '12345678', email: 'test@test.com'
    u.confirm
    post :create, params: { api_user: { email: 'test@test.com', password: '12345678' } }
    assert_response :success
    assert_not_nil @controller.current_api_user
    # test login activities creation
    assert_not_empty u.login_activities
    assert_equal [true], u.login_activities.map(&:success)
  end

  test "should require otp_attempt for login using email and 2FA" do
    u = create_user login: 'test', password: '12345678', password_confirmation: '12345678', email: 'test@test.com'
    u.confirm
    u.two_factor
    options = { otp_required: true, password: '12345678', qrcode: u.reload.current_otp }
    u.two_factor=(options)
    post :create, params: { api_user: { email: 'test@test.com', password: '12345678' } }
    assert_response 400
    assert_nil @controller.current_api_user
  end

  test "should not login if password is wrong" do
    u = create_user login: 'test', password: '12345678', password_confirmation: '12345678', email: 'test@test.com'
    post :create, params: { api_user: { email: 'test@test.com', password: '12345679' } }
    assert_response 401
    assert_nil @controller.current_api_user
  end

  test "should logout" do
    u = create_user login: 'test', password: '12345678', password_confirmation: '12345678', email: 'test@test.com'
    authenticate_with_user(u)
    delete :destroy, params: {}
    assert_response :success
    assert_nil @controller.current_api_user
  end

  test "should logout and redirect to destination" do
    u = create_user login: 'test', password: '12345678', password_confirmation: '12345678', email: 'test@test.com'
    authenticate_with_user(u)
    delete :destroy, params: { destination: '/' }
    assert_redirected_to '/'
    assert_nil @controller.current_api_user
  end

  test "should login and redirect to destination" do
    u = create_user login: 'test', password: '12345678', password_confirmation: '12345678', email: 'test@test.com'
    u.confirm
    post :create, params: { api_user: { email: 'test@test.com', password: '12345678' }, destination: '/admin' }
    assert_redirected_to '/admin'
    assert_not_nil @controller.current_api_user
  end

  test "should display error if cannot sign out" do
    u = create_user login: 'test', password: '12345678', password_confirmation: '12345678', email: 'test@test.com'
    authenticate_with_user(u)
    @controller.expects(:sign_out).returns(false)
    delete :destroy, params: {}
    assert_response 400
    assert_not_nil @controller.current_api_user
  end

  # test "should lock user after excessive login requests" do
  #   u = create_user login: 'test', password: '12345678', password_confirmation: '12345678', email: 'test@test.com'
  #   Devise.maximum_attempts = 2

  #   2.times do
  #     post :create, params: { api_user: { email: 'test@test.com', password: '12345679' } }
  #   end

  #   u.reload
  #   assert u.access_locked?
  #   assert_not_nil u.locked_at
  # end

  # test "should unlock locked user accounts after specified time" do
  #   travel_to Time.zone.local(2023, 12, 12, 01, 04, 44)
  #   u = create_user login: 'test', password: '12345678', password_confirmation: '12345678', email: 'test@test.com'
  #   Devise.unlock_in = 10.minutes
    

  #   u.lock_access!

  #   travel 30.minutes
  #   post :create, params: { api_user: { email: 'test@test.com', password: '12345678' } }

  #   u.reload
  #   assert !u.access_locked?
  #   assert_nil u.locked_at
  # end
end
