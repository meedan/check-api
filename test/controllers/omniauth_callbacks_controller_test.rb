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
        image: 'http://twitter.com/test/image.png'
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

  def teardown
    OmniAuth.config.test_mode = false
  end
end
