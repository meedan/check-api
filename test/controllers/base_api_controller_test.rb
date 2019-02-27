require_relative '../test_helper'

class BaseApiControllerTest < ActionController::TestCase
  def setup
    super
    @controller = Api::V1::BaseApiController.new
  end

  test "should respond to json" do
    assert_equal [:json], @controller.mimes_for_respond_to.keys
  end

  test "should remove empty parameters" do
    get :ping, empty: '', notempty: 'Something'
    assert !@controller.params.keys.include?('empty')
    assert @controller.params.keys.include?('notempty')
  end

  test "should remove empty headers" do
    @request.headers['X-Empty'] = ''
    @request.headers['X-Not-Empty'] = 'Something'
    get :ping
    assert @request.headers['X-Empty'].nil?
    assert !@request.headers['X-Not-Empty'].nil?
  end

  test "should return build as a custom header" do
    get :ping
    assert_not_nil @response.headers['X-Build']
  end

  test "should return default api version as a custom header" do
    get :ping
    assert_match /v1$/, @response.headers['Accept']
  end

  test "should get version" do
    authenticate_with_token
    get :version
    assert_response :success
  end

  test "should get current user from session" do
    u = create_omniauth_user info: {name: 'Test User'}
    authenticate_with_user(u)
    get :me
    assert_response :success
    response = JSON.parse(@response.body)
    assert_equal 'Test User', response['data']['name']
    assert_equal 'session', response['data']['source']
  end

  test "should get current user from token" do
    u = create_omniauth_user info: {name: 'Test User'}
    header = CONFIG['authorization_header'] || 'X-Token'
    @request.headers.merge!({ header => u.token })
    get :me
    assert_response :success
    response = JSON.parse(@response.body)
    assert_equal 'Test User', response['data']['name']
    assert_equal 'token', response['data']['source']
  end

  test "should not get current user" do
    u = create_omniauth_user info: {name: 'Test User'}
    get :me
    assert_response :success
    response = JSON.parse(@response.body)
    assert_equal({ 'type' => 'user' }, response)
  end

  test "should get options" do
    process :options, 'OPTIONS'
    assert_response :success
  end

  test "should return error from session" do
    u = create_omniauth_user info: {name: 'Test User'}
    header = CONFIG['authorization_header'] || 'X-Token'
    @request.headers.merge!({ header => u.token })
    @request.session['check.error'] = 'Error message'
    get :me
    assert_response 400
    response = JSON.parse(@response.body)
    assert_equal 'Error message', response['data']['message']
  end

  test "should return warning from session" do
    u = create_omniauth_user info: {name: 'Test User'}
    header = CONFIG['authorization_header'] || 'X-Token'
    @request.headers.merge!({ header => u.token })
    @request.session['check.warning'] = 'Warning message'
    get :me
    assert_response 400
    response = JSON.parse(@response.body)
    assert_equal 'Warning message', response['data']['message']
  end

  test "should not return error from session" do
    u = create_omniauth_user info: {name: 'Test User'}
    header = CONFIG['authorization_header'] || 'X-Token'
    @request.headers.merge!({ header => u.token })
    @request.session['check.error'] = nil
    get :me
    assert_response :success
  end

  test "should send logs" do
    authenticate_with_user_token
    post :log, foo: 'bar'
    assert_response :success
  end

  test "should not send logs if not logged in" do
    post :log, foo: 'bar'
    assert_response 401
  end

  test "should ping" do
    get :ping
    assert_response :success
  end
end
