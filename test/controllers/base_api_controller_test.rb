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
    get :ping, params: { empty: '', notempty: 'Something' }
    assert !@controller.params.keys.include?('empty')
    assert @controller.params.keys.include?('notempty')
  end

  test "should remove empty headers" do
    @request.headers['X-Empty'] = ''
    @request.headers['X-Not-Empty'] = 'Something'
    get :ping, params: {}
    assert @request.headers['X-Empty'].nil?
    assert !@request.headers['X-Not-Empty'].nil?
  end

  test "should return build as a custom header" do
    get :ping, params: {}
    assert_not_nil @response.headers['X-Build']
  end

  test "should return default api version as a custom header" do
    get :ping, params: {}
    assert_match /v1$/, @response.headers['Accept']
  end

  test "should get version" do
    authenticate_with_token
    get :version, params: {}
    assert_response :success
  end

  test "should get current user from session" do
    u = create_omniauth_user email: 'test@local.com', info: {name: 'Test User'}
    authenticate_with_user(u)
    get :me, params: {}
    assert_response :success
    response = JSON.parse(@response.body)
    assert_equal 'test@local.com', response['data']['email']
    assert_equal 'session', response['data']['source']
  end

  test "should get current user from token" do
    u = create_omniauth_user email: 'test@local.com', info: { name: 'Test User', email: 'test@local.com' }
    header = CheckConfig.get('authorization_header') || 'X-Token'
    @request.headers.merge!({ header => u.token })
    get :me, params: {}
    assert_response :success
    response = JSON.parse(@response.body)
    assert_equal 'test@local.com', response['data']['email']
    assert_equal 'token', response['data']['source']
  end

  test "should not get current user" do
    u = create_omniauth_user info: {name: 'Test User'}
    get :me, params: {}
    assert_response :success
    response = JSON.parse(@response.body)
    assert_equal({ 'type' => 'user' }, response)
  end

  test "should get options" do
    process :options, params: {}
    assert_response :success
  end

  test "should return error from session" do
    u = create_omniauth_user info: {name: 'Test User'}
    header = CheckConfig.get('authorization_header') || 'X-Token'
    @request.headers.merge!({ header => u.token })
    @request.session['check.error'] = 'Error message'
    get :me, params: {}
    assert_response 400
    response = JSON.parse(@response.body)
    error_info = response['errors'].first
    assert_equal 'Error message', error_info['message']
  end

  test "should return warning from session" do
    u = create_omniauth_user info: {name: 'Test User'}
    header = CheckConfig.get('authorization_header') || 'X-Token'
    @request.headers.merge!({ header => u.token })
    @request.session['check.warning'] = 'Warning message'
    get :me, params: {}
    assert_response 400
    response = JSON.parse(@response.body)
    error_info = response['errors'].first
    assert_equal 'Warning message', error_info['message']
  end

  test "should not return error from session" do
    u = create_omniauth_user info: {name: 'Test User'}
    header = CheckConfig.get('authorization_header') || 'X-Token'
    @request.headers.merge!({ header => u.token })
    @request.session['check.error'] = nil
    get :me, params: {}
    assert_response :success
  end

  test "should send logs" do
    authenticate_with_user_token
    post :log, params: { foo: 'bar' }
    assert_response :success
  end

  test "should not send logs if not logged in" do
    post :log, params: { foo: 'bar' }
    assert_response 401
  end

  test "should ping" do
    get :ping, params: {}
    assert_response :success
  end

  test "should set user information in Sentry for authenticated user" do
    team = create_team
    user = create_user name: 'Test User'
    create_team_user user: user, team: team
    user.current_team_id = team.id
    user.save!

    authenticate_with_user(user)

    CheckSentry.expects(:set_user_info).with(user.id, team_id: team.id, api_key_id: nil)

    get :me, params: {}
  end

  test "should set API key information in Sentry for token-authenticated call" do
    api_key = create_api_key
    ApiKey.current = api_key

    authenticate_with_token(api_key)

    CheckSentry.expects(:set_user_info).with(nil, team_id: nil, api_key_id: api_key.id)

    get :version, params: {}
  end

  test "should send basic tracing information for authenticated user" do
    team = create_team
    user = create_user name: 'Test User'
    create_team_user user: user, team: team
    user.current_team_id = team.id
    user.save!

    authenticate_with_user(user)

    TracingService.expects(:add_attributes_to_current_span).with(
      'app.user.id' => user.id,
      'app.user.team_id' => team.id,
      'app.api_key_id' => nil
    )

    get :me, params: {}
  end

  test "should send basic tracing information for api key" do
    api_key = create_api_key
    ApiKey.current = api_key

    authenticate_with_token(api_key)

    TracingService.expects(:add_attributes_to_current_span).with(
      'app.user.id' => nil,
      'app.user.team_id' => nil,
      'app.api_key_id' => api_key.id
    )

    get :version, params: {}
  end
end
