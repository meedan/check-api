require_relative '../test_helper'

class AdminControllerTest < ActionController::TestCase
  def setup
    super
    @controller = Api::V1::AdminController.new
    @request.env["devise.mapping"] = Devise.mappings[:api_user]
    sign_out('user')
    User.current = nil
    Project.delete_all
  end

  test "should return error if project does not exist" do
    assert_raises ActiveRecord::RecordNotFound do
      get :add_publisher_to_project, id: 1, provider: 'twitter', token: '123456'
    end
  end

  test "should return error if token is not valid" do
    p = create_project
    get :add_publisher_to_project, id: p.id, provider: 'twitter', token: '123456'
    assert_response 401
  end

  test "should save oauth information if token is valid" do
    p = create_project
    session['check.twitter.authdata'] = { 'token' => '123456', 'secret' => '654321' }
    get :add_publisher_to_project, id: p.id, provider: 'twitter', token: p.token
    assert_response :success
    p = Project.find(p.id)
    assert_equal '123456', p.get_social_publishing['twitter']['token']
    assert_equal '654321', p.get_social_publishing['twitter']['secret']
  end

  test "should find Slack user by UID" do
    u = create_user provider: 'slack', uuid: 'U123'
    slack_account =u.get_social_accounts_for_login('slack')
    a = create_api_key
    authenticate_with_token(a)
    get :slack_user, uid: 'U123'
    assert_equal slack_account.token, JSON.parse(@response.body)['data']['token']
  end

  test "should not find Slack user by UID if UID doesn't exist" do
    u = create_user provider: 'slack', uuid: 'U123'
    a = create_api_key
    authenticate_with_token(a)
    get :slack_user, uid: 'U124'
    assert_nil JSON.parse(@response.body)['data']
  end

  test "should not find Slack user by UID if API key is not global" do
    u = create_user provider: 'slack', uuid: 'U123'
    a = create_api_key
    create_bot_user api_key_id: a.id
    authenticate_with_token(a)
    get :slack_user, uid: 'U123'
    assert_nil JSON.parse(@response.body)['data']
  end

  test "should not find Slack user by UID if API key is not provided" do
    u = create_user provider: 'slack', uuid: 'U123'
    a = create_api_key
    get :slack_user, uid: 'U123'
    assert_response 401
  end
end
