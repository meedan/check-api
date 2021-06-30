require_relative '../test_helper'

class WorkspacesControllerTest < ActionController::TestCase
  def setup
    @controller = Api::V2::WorkspacesController.new
    super
    @t1 = create_team name: 'Test 1'
    @u = create_user
    create_team_user team: @t1, user: @u
    @t2 = create_team name: 'Test 2'
    @a = create_api_key
    @t3 = create_team name: 'Test 3'
    create_team_user team: @t3, user: @u
  end

  test "should return all workspaces" do
    authenticate_with_token @a
    get :index, params: {}
    assert_response :success
    assert_equal 3, json_response['data'].size
  end

  test "should return some workspaces" do
    authenticate_with_user @u
    get :index, params: {}
    assert_response :success
    assert_equal 2, json_response['data'].size
  end

  test "should return no workspaces" do
    get :index, params: {}
    assert_response 401
  end

  test "should filter by whether it has a tipline installed" do
    authenticate_with_user @u
    b = create_team_bot name: 'Smooch', login: 'smooch', set_approved: true, set_settings: nil, set_events: [], set_request_url: "#{CheckConfig.get('checkdesk_base_url_private')}/api/bots/smooch"
    create_team_bot_installation user_id: b.id, settings: nil, team_id: @t1.id

    get :index, params: {}
    assert_response :success
    assert_equal 2, json_response['data'].size

    get :index, params: { filter: { is_tipline_installed: true } }
    assert_response :success
    assert_equal 1, json_response['data'].size
    assert_equal 'Test 1', json_response['data'][0]['attributes']['name']

    get :index, params: { filter: { is_tipline_installed: false } }
    assert_response :success
    assert_equal 1, json_response['data'].size
    assert_equal 'Test 3', json_response['data'][0]['attributes']['name']
  end

  test "should filter by whether it has Alegre bot installed" do
    authenticate_with_user @u
    b = create_team_bot name: 'Alegre', login: 'alegre', set_approved: true, set_settings: nil, set_events: [], set_request_url: "#{CheckConfig.get('checkdesk_base_url_private')}/api/bots/alegre"
    create_team_bot_installation user_id: b.id, settings: nil, team_id: @t1.id

    get :index, params: {}
    assert_response :success
    assert_equal 2, json_response['data'].size

    get :index, params: { filter: { is_similarity_feature_enabled: true } }
    assert_response :success
    assert_equal 1, json_response['data'].size
    assert_equal 'Test 1', json_response['data'][0]['attributes']['name']

    get :index, params: { filter: { is_similarity_feature_enabled: false } }
    assert_response :success
    assert_equal 1, json_response['data'].size
    assert_equal 'Test 3', json_response['data'][0]['attributes']['name']
  end
end
