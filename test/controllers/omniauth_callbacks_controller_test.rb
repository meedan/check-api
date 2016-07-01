require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

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
        image: 'http://facebook.com/test/image.png'
      },
      credentials: {
        token: '123456',
        secret: 'top_secret'
      }
    })
    request.env['devise.mapping'] = Devise.mappings[:api_user]
    ['https://twitter.com/test', 'https://facebook.com/654321'].each do |url|
      WebMock.stub_request(:get, CONFIG['pender_host'] + '/api/medias').with({ query: { url: url } }).to_return(body: '{"type":"media","data":{}}')
    end
  end

  test "should redirect to root after Twitter authentication" do
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:twitter]
    get :twitter
    assert_redirected_to '/'
  end

  test "should set information in session after Twitter authentication" do
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:twitter]
    assert_nil session['checkdesk.user']
    get :twitter
    assert_not_nil session['checkdesk.user']
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
    assert_not_nil session['checkdesk.user']
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

  test "should logout" do
    u = create_user
    assert_nil request.env['warden'].user
    authenticate_with_user(u)
    assert_equal u, request.env['warden'].user
    get :logout, destination: '/api'
    assert_redirected_to '/api'
    assert_nil request.env['warden'].user
  end

  def teardown
    OmniAuth.config.test_mode = false
  end
end
