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
    post :create, api_user: { email: 'test@test.com', password: '12345678' }
    assert_response :success
    assert_not_nil @controller.current_api_user
  end

  test "should not login if password is wrong" do
    u = create_user login: 'test', password: '12345678', password_confirmation: '12345678', email: 'test@test.com'
    post :create, api_user: { email: 'test@test.com', password: '12345679' }
    assert_response 401
    assert_nil @controller.current_api_user
  end

  test "should logout" do
    u = create_user login: 'test', password: '12345678', password_confirmation: '12345678', email: 'test@test.com'
    authenticate_with_user(u)
    delete :destroy
    assert_response :success
    assert_nil @controller.current_api_user
  end

  test "should logout and redirect to destination" do
    u = create_user login: 'test', password: '12345678', password_confirmation: '12345678', email: 'test@test.com'
    authenticate_with_user(u)
    delete :destroy, destination: '/'
    assert_redirected_to '/'
    assert_nil @controller.current_api_user
  end

  test "should login and redirect to destination" do
    u = create_user login: 'test', password: '12345678', password_confirmation: '12345678', email: 'test@test.com'
    u.confirm
    post :create, api_user: { email: 'test@test.com', password: '12345678' }, destination: '/admin'
    assert_redirected_to '/admin'
    assert_not_nil @controller.current_api_user
  end

  test "should display error if cannot sign out" do
    u = create_user login: 'test', password: '12345678', password_confirmation: '12345678', email: 'test@test.com'
    authenticate_with_user(u)
    @controller.expects(:sign_out).returns(false)
    delete :destroy
    assert_response 400
    assert_not_nil @controller.current_api_user
    assert_equal 'error', JSON.parse(@response.body)['type']
  end


end
