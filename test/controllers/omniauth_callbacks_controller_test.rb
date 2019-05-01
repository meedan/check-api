require_relative '../test_helper'

class OmniauthCallbacksControllerTest < ActionController::TestCase
  def setup
    super
    @controller = Api::V1::OmniauthCallbacksController.new
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:twitter] = OmniAuth::AuthHash.new({
      provider: 'twitter',
      uid: '654321',
      info: {
        name: 'Test',
        image: 'http://twitter.com/test/image.png',
        nickname: 'test'
      },
      credentials: {
        token: '123456',
        secret: 'top_secret'
      }
    })
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
    OmniAuth.config.mock_auth[:slack] = OmniAuth::AuthHash.new({
      provider: 'slack',
      uid: '654321',
      info: {
        nickname: "melsawy",
        team: "Meedan",
        user: "melsawy",
        team_id: "T02528QUL",
        user_id: "U02528YJJ",
        name: "Mohamed El-Sawy",
        email: "sawy@meedan.com",
        first_name: "Mohamed",
        last_name: "El-Sawy",
        description: nil,
        image_24: "https://avatars.slack-edge.com/2014-02-12/2172593075_24.jpg",
        image_48: "https://avatars.slack-edge.com/2014-02-12/2172593075_48.jpg",
        image: "https://avatars.slack-edge.com/2014-02-12/2172593075_192.jpg",
        team_domain: "meedan",
        is_admin: false,
        is_owner: false,
        time_zone: "Africa/Cairo"
      },
      extra: {
        raw_info: {
          url: 'https://meedan.slack.com/',
          user: 'melsawy'
        }
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
    request.env['devise.mapping'] = Devise.mappings[:api_user]
    ['https://twitter.com/test', 'https://facebook.com/654321', 'https://www.googleapis.com/plus/v1/people/654321'].each do |url|
      WebMock.stub_request(:get, CONFIG['pender_url_private'] + '/api/medias').with({ query: { url: url } }).to_return(body: '{"type":"media","data":{"type":"profile"}}')
    end
    User.current = nil
  end

  def teardown
    super
    User.current = nil
  end

  test "should redirect to root after Twitter authentication" do
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:twitter]
    get :twitter
    assert_redirected_to '/api'
  end

  test "should set information in session after Twitter authentication" do
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:twitter]
    assert_nil session['checkdesk.user']
    get :twitter
    assert_not_nil session['checkdesk.current_user_id']
  end

  test "should redirect to destination after Twitter authentication" do
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:twitter]
    get :twitter, destination: '/close.html'
    assert_redirected_to '/close.html'
  end

  test "should set information in session after Facebook authentication" do
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:facebook]
    assert_nil session['checkdesk.user']
    get :facebook
    assert_not_nil session['checkdesk.current_user_id']
  end

  test "should redirect to API page after Facebook authentication" do
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:facebook]
    get :facebook
    assert_redirected_to '/api'
  end

  test "should redirect to destination after Facebook authentication" do
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:facebook]
    request.env['omniauth.params'] = { 'destination' => '/close.html' }
    get :facebook
    assert_redirected_to '/close.html'
  end

  test "should redirect to root after Slack authentication" do
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:slack]
    get :slack
    assert_redirected_to '/api'
  end

  test "should set information in session after Slack authentication" do
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:slack]
    assert_nil session['checkdesk.user']
    get :slack
    assert_not_nil session['checkdesk.current_user_id']
  end

  test "should redirect to destination after Slack authentication" do
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:slack]
    request.env['omniauth.params'] = { 'destination' => '/close.html' }
    get :slack
    assert_redirected_to '/close.html'
  end

  test "should logout" do
    u = create_user
    assert_nil request.env['warden'].user
    authenticate_with_user(u)
    assert_equal u, request.env['warden'].user
    get :logout, destination: '/api'
    assert_redirected_to '/api'
    assert_nil request.env['warden'].user
  end

  test "should not store error if there is no error from provider" do
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:facebook]
    get :facebook
    assert_nil session['check.error']
    assert_nil session['check.warning']
  end

  test "should store error if there is error from provider" do
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:facebook]
    User.stubs(:from_omniauth).raises(ActiveRecord::RecordInvalid)
    get :facebook
    assert_not_nil session['check.error']
    User.unstub(:from_omniauth)
  end

  test "should store warning if there is warning from provider" do
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:facebook]
    User.stubs(:from_omniauth).raises(RuntimeError)
    get :facebook
    assert_not_nil session['check.warning']
    User.unstub(:from_omniauth)
  end

  test "should get URL for Slack" do
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    WebMock.stub_request(:get, pender_url).with({ query: { url: 'https://meedan.slack.com/team/melsawy' } }).to_return(body: '{"type":"media","data":{"url":"https://meedan.slack.com/?redir=/team/melsawy","type":"profile"}}')
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:slack]
    get :slack
    assert_equal 'https://meedan.slack.com/team/melsawy', Account.last.url
  end

  test "should connect when current user set" do
    u = create_user login: 'test', password: '12345678', password_confirmation: '12345678', email: 'test@test.com'
    u.confirm
    authenticate_with_user(u)
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:twitter]
    get :twitter
    u = User.find(u.id)
    assert_equal 1, u.source.accounts.count
  end

  test "should redirect to root after Google authentication" do
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:google_oauth2]
    get :google_oauth2
    assert_redirected_to '/api'
  end

  test "should set information in session after Google authentication" do
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:google_oauth2]
    assert_nil session['checkdesk.user']
    get :google_oauth2
    assert_not_nil session['checkdesk.current_user_id']
  end

  test "should redirect to destination after Google authentication" do
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:google_oauth2]
    get :google_oauth2, destination: '/close.html'
    assert_redirected_to '/close.html'
  end

  def teardown
    OmniAuth.config.test_mode = false
  end
end
