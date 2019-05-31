require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class GreendayUsersControllerTest < ActionController::TestCase
  def setup
    super
    @controller = Ah::Api::Greenday::V1::BaseController.new
    @request.env['devise.mapping'] = Devise.mappings[:api_user]
    sign_out('user')
    User.current = nil
  end

  test "should set current user" do
    u = create_user
    header = CONFIG['authorization_header'] || 'X-Token'
    @request.headers.merge!({ header => u.token })
    get :ping
    assert_equal u, User.current
  end

  test "should set current team" do
    u = create_user
    t = create_team
    header = CONFIG['authorization_header'] || 'X-Token'
    @request.headers.merge!({ header => u.token })
    get :ping, team: t.slug
    assert_equal t, Team.current
  end

  test "should load ability" do
    u = create_user
    t = create_team
    header = CONFIG['authorization_header'] || 'X-Token'
    @request.headers.merge!({ header => u.token })
    get :ping, team: t.slug
    assert_kind_of Ability, assigns(:ability)
  end

  test "should return true for options requests" do
    process :ping, 'OPTIONS'
    assert_response :success
  end
end 
