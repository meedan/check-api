require_relative '../test_helper'

class OmniauthCallbacksControllerTest < ActionController::TestCase
  def setup
    super
    @controller = Api::V1::OmniauthCallbacksController.new
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:facebook] = OmniAuth::AuthHash.new({
      provider: 'facebook',
      uid: '654321',
      info: {
        name: 'Test',
        email: 'test@test.com',
        image: 'http://facebook.com/test/image.png'
      },
      credentials: {
        token: '123456',
        secret: 'top_secret'
      }
    })
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
      provider: 'google_oauth2',
      uid: '654321',
      info: {
        name: 'Test',
        email: 'test@test.com',
        image: 'http://google.com/test/image.png',
      },
      credentials: {
        token: '123456',
        secret: 'top_secret'
      }
    })
    [{email: 'test@test.com', name: 'Test'}, {email: 'sawy@meedan.com', name: 'Mohamed El-Sawy'}].each do |info|
      invite_new_user info
    end
    request.env['devise.mapping'] = Devise.mappings[:api_user]
    ['https://facebook.com/654321', 'https://www.googleapis.com/plus/v1/people/654321'].each do |url|
      WebMock.stub_request(:get, CheckConfig.get('pender_url_private') + '/api/medias').with({ query: { url: url } }).to_return(body: '{"type":"media","data":{"type":"profile"}}')
    end
    User.current = nil
  end

  def teardown
    super
    User.current = nil
  end

  test "should set information in session after Facebook authentication" do
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:facebook]
    assert_nil session['checkdesk.user']
    get :facebook, params: {}
    assert_not_nil session['checkdesk.current_user_id']
  end

  test "should redirect to API page after Facebook authentication" do
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:facebook]
    get :facebook, params: {}
    assert_redirected_to '/close.html'
  end

  test "should redirect to destination after Facebook authentication" do
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:facebook]
    request.env['omniauth.params'] = { 'destination' => '/close.html' }
    get :facebook, params: {}
    assert_redirected_to '/close.html'
  end

  test "should logout" do
    u = create_user
    assert_nil request.env['warden'].user
    authenticate_with_user(u)
    assert_equal u, request.env['warden'].user
    get :logout, params: { destination: '/api' }
    assert_redirected_to '/api'
    assert_nil request.env['warden'].user
  end

  test "should not store error if there is no error from provider" do
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:facebook]
    get :facebook, params: {}
    assert_nil session['check.error']
    assert_nil session['check.warning']
  end

  test "should store error if there is error from provider" do
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:facebook]
    User.stubs(:from_omniauth).raises(ActiveRecord::RecordInvalid)
    get :facebook, params: {}
    assert_not_nil session['check.error']
    User.unstub(:from_omniauth)
  end

  test "should store warning if there is warning from provider" do
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:facebook]
    User.stubs(:from_omniauth).raises(RuntimeError)
    get :facebook, params: {}
    assert_not_nil session['check.warning']
    User.unstub(:from_omniauth)
  end

  test "should connect when current user set" do
    u = User.where(email: 'test@test.com').first
    u.confirm
    authenticate_with_user(u)
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:facebook]
    get :facebook, params: {}
    u = User.find(u.id)
    assert_equal 1, u.source.accounts.count
  end

  test "should redirect to root after Google authentication" do
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:google_oauth2]
    get :google_oauth2, params: {}
    assert_redirected_to '/close.html'
  end

  test "should set information in session after Google authentication" do
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:google_oauth2]
    assert_nil session['checkdesk.user']
    get :google_oauth2, params: {}
    assert_not_nil session['checkdesk.current_user_id']
  end

  test "should redirect to destination after Google authentication" do
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:google_oauth2]
    get :google_oauth2, params: { destination: '/close.html' }
    assert_redirected_to '/close.html'
  end

  test "should setup Facebook authentication" do
    request.env['omniauth.strategy'] = OmniAuth::Strategies::Facebook.new({})
    get :setup, params: {}
    assert_response 404
  end

  def teardown
    OmniAuth.config.test_mode = false
  end
end
