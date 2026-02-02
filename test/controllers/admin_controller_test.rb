require_relative '../test_helper'

class AdminControllerTest < ActionController::TestCase
  def setup
    super
    @controller = Api::V1::AdminController.new
    @request.env["devise.mapping"] = Devise.mappings[:api_user]
    sign_out('user')
    User.current = nil
  end

  test "should find Slack user by UID" do
    a = create_api_key
    u = create_omniauth_user provider: 'slack', uid: 'U123'
    slack_account = u.get_social_accounts_for_login({provider: 'slack', uid: 'U123'}).first
    authenticate_with_token(a)
    get :slack_user, params: { uid: 'U123' }
    assert_equal slack_account.token, JSON.parse(@response.body)['data']['token']
  end

  test "should not find Slack user by UID if UID doesn't exist" do
    a = create_api_key
    u = create_omniauth_user provider: 'slack', uid: 'U123'
    authenticate_with_token(a)
    get :slack_user, params: { uid: 'U124' }
    assert_nil JSON.parse(@response.body)['data']
  end

  test "should not find Slack user by UID if API key is not global" do
    a = create_api_key
    create_bot_user api_key_id: a.id
    u = create_omniauth_user provider: 'slack', uid: 'U123'
    authenticate_with_token(a)
    get :slack_user, params: { uid: 'U123' }
    assert_nil JSON.parse(@response.body)['data']
  end

  test "should not find Slack user by UID if API key is not provided" do
    a = create_api_key
    u = create_omniauth_user provider: 'slack', uid: 'U123'
    get :slack_user, params: { uid: 'U123' }
    assert_response 401
  end

  test "should not connect Facebook page to Smooch bot if token is invalid" do
    b = create_team_bot login: 'smooch'
    tbi = create_team_bot_installation
    session['check.facebook.authdata'] = { 'token' => '123456', 'secret' => '654321' }
    get :save_messenger_credentials_for_smooch_bot, params: { id: tbi.id, token: random_string }
    assert_response 401
  end

  test "should not connect Facebook page to Smooch bot if auth is nil" do
    b = create_team_bot login: 'smooch'
    tbi = create_team_bot_installation
    session['check.facebook.authdata'] = nil
    get :save_messenger_credentials_for_smooch_bot, params: { id: tbi.id, token: random_string }
    assert_response 400
  end

  test "should not connect Facebook page to Smooch bot if not exactly one page was selected" do
    Bot::Smooch.stubs(:smooch_api_client).returns(nil)
    SmoochApi::IntegrationApi.any_instance.expects(:create_integration).once
    WebMock.stub_request(:get, /graph\.facebook\.com\/me\/accounts/).to_return(body: { data: [] }.to_json, status: 200)
    b = create_team_bot login: 'smooch'
    t = random_string
    tbi = create_team_bot_installation
    tbi = TeamBotInstallation.find(tbi.id)
    tbi.set_smooch_authorization_token = t
    tbi.save!
    session['check.facebook.authdata'] = { 'token' => '123456', 'secret' => '654321' }
    get :save_messenger_credentials_for_smooch_bot, params: { id: tbi.id, token: t }
    assert_response 400
    Bot::Smooch.unstub(:smooch_api_client)
    SmoochApi::IntegrationApi.any_instance.unstub(:create_integration)
  end

  test "should connect Facebook page to Smooch bot if exactly one page was selected" do
    Bot::Smooch.stubs(:smooch_api_client).returns(nil)
    SmoochApi::IntegrationApi.any_instance.expects(:create_integration).once
    WebMock.stub_request(:get, /graph\.facebook\.com\/me\/accounts/).to_return(body: { data: [{ access_token: random_string }] }.to_json, status: 200)
    b = create_team_bot login: 'smooch'
    t = random_string
    tbi = create_team_bot_installation
    tbi = TeamBotInstallation.find(tbi.id)
    tbi.set_smooch_authorization_token = t
    tbi.save!
    session['check.facebook.authdata'] = { 'token' => '123456', 'secret' => '654321' }
    get :save_messenger_credentials_for_smooch_bot, params: { id: tbi.id, token: t }
    assert_response :success
    Bot::Smooch.unstub(:smooch_api_client)
    SmoochApi::IntegrationApi.any_instance.unstub(:create_integration)
  end

  test "should connect Instagram profile to Smooch bot" do
    Bot::Smooch.stubs(:smooch_api_client).returns(nil)
    SmoochApi::IntegrationApi.any_instance.expects(:create_integration).once
    WebMock.stub_request(:get, /graph\.facebook\.com\/me\/accounts/).to_return(body: { data: [{ access_token: random_string }] }.to_json, status: 200)
    b = create_team_bot login: 'smooch'
    t = random_string
    tbi = create_team_bot_installation
    tbi = TeamBotInstallation.find(tbi.id)
    tbi.set_smooch_authorization_token = t
    tbi.save!
    session['check.facebook.authdata'] = { 'token' => '123456', 'secret' => '654321' }
    get :save_instagram_credentials_for_smooch_bot, params: { id: tbi.id, token: t }
    assert_response :success
    Bot::Smooch.unstub(:smooch_api_client)
    SmoochApi::IntegrationApi.any_instance.unstub(:create_integration)
  end
end
