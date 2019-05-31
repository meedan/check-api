require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class GreendayUsersControllerTest < ActionController::TestCase
  def setup
    super
    @controller = Ah::Api::Greenday::V1::UsersController.new
    @request.env['devise.mapping'] = Devise.mappings[:api_user]
    sign_out('user')
    User.current = nil
  end

  test "should respond to json" do
    assert_equal [:json], @controller.mimes_for_respond_to.keys
  end

  test "should get current user from session" do
    u = create_omniauth_user info: { name: 'Test User' }
    authenticate_with_user(u)
    get :me
    assert_response :success
    response = JSON.parse(@response.body)
    assert_equal 'Test', response['first_name']
    assert_equal 'User', response['last_name']
  end

  test "should get current user from token" do
    u = create_omniauth_user info: { name: 'Test User' }
    header = CONFIG['authorization_header'] || 'X-Token'
    @request.headers.merge!({ header => u.token })
    get :me
    assert_response :success
    response = JSON.parse(@response.body)
    assert_equal 'Test', response['first_name']
    assert_equal 'User', response['last_name']
  end

  test "should not get current user" do
    u = create_omniauth_user info: { name: 'Test User' }
    get :me
    assert_response 401
  end

  test "should get user stats" do
    u = create_omniauth_user info: { name: 'Test User' }
    authenticate_with_user(u)
    get :stats
    assert_response :success
    response = JSON.parse(@response.body)
    assert_equal u.id, response['id']
  end

  test "should accept terms" do
    u = create_omniauth_user info: { name: 'Test User' }
    assert_nil u.reload.last_accepted_terms_at
    authenticate_with_user(u)
    post :nda
    assert_response :success
    assert_not_nil u.reload.last_accepted_terms_at
  end
end 
