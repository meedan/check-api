require_relative '../test_helper'

class WorkspacesControllerTest < ActionController::TestCase
  def setup
    @controller = Api::V2::WorkspacesController.new
    super
    @t1 = create_team
    @u = create_user
    create_team_user team: @t1, user: @u
    @t2 = create_team
    @a = create_api_key
  end

  test "should return all workspaces" do
    authenticate_with_token @a
    get :index
    assert_response :success
    assert_equal 2, json_response['data'].size
  end

  test "should return some workspaces" do
    authenticate_with_user @u
    get :index
    assert_response :success
    assert_equal 1, json_response['data'].size
  end

  test "should return no workspaces" do
    get :index
    assert_response 401
  end
end
