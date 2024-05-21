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
    p1 = random_complex_password
    u = create_user login: 'test', password: p1, password_confirmation: p1, email: 'test@test.com'
    u.confirm
    post :create, params: { api_user: { email: 'test@test.com', password: p1 } }
    assert_response :success
    assert_not_nil @controller.current_api_user
    # test login activities creation
    assert_not_empty u.login_activities
    assert_equal [true], u.login_activities.map(&:success)
  end

  test "should require otp_attempt for login using email and 2FA" do
    p1 = random_complex_password
    u = create_user login: 'test', password: p1, password_confirmation: p1, email: 'test@test.com'
    u.confirm
    u.two_factor
    options = { otp_required: true, password: p1, qrcode: u.reload.current_otp }
    u.two_factor=(options)
    post :create, params: { api_user: { email: 'test@test.com', password: p1 } }
    assert_response 400
    assert_nil @controller.current_api_user
  end

  test "should not login if password is wrong" do
    p1 = random_complex_password
    u = create_user login: 'test', password: p1, password_confirmation: p1, email: 'test@test.com'
    post :create, params: { api_user: { email: 'test@test.com', password: random_complex_password } }
    assert_response 401
    assert_nil @controller.current_api_user
  end

  test "should logout" do
    p1 = random_complex_password
    u = create_user login: 'test', password: p1, password_confirmation: p1, email: 'test@test.com'
    authenticate_with_user(u)
    delete :destroy, params: {}
    assert_response :success
    assert_nil @controller.current_api_user
  end

  test "should logout and redirect to destination" do
    p1 = random_complex_password
    u = create_user login: 'test', password: p1, password_confirmation: p1, email: 'test@test.com'
    authenticate_with_user(u)
    delete :destroy, params: { destination: '/' }
    assert_redirected_to '/'
    assert_nil @controller.current_api_user
  end

  test "should login and redirect to destination" do
    p1 = random_complex_password
    u = create_user login: 'test', password: p1, password_confirmation: p1, email: 'test@test.com'
    u.confirm
    post :create, params: { api_user: { email: 'test@test.com', password: p1 }, destination: '/admin' }
    assert_redirected_to '/admin'
    assert_not_nil @controller.current_api_user
  end

  test "should display error if cannot sign out" do
    p1 = random_complex_password
    u = create_user login: 'test', password: p1, password_confirmation: p1, email: 'test@test.com'
    authenticate_with_user(u)
    @controller.expects(:sign_out).returns(false)
    delete :destroy, params: {}
    assert_response 400
    assert_not_nil @controller.current_api_user
  end
end
