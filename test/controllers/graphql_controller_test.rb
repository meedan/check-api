require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class GraphqlControllerTest < ActionController::TestCase
  def setup
    super
    @controller = Api::V1::GraphqlController.new
  end

  test "should not access GraphQL if not authenticated" do
    post :create, query: 'query Query { about { name, version } }'
    assert_response 401
  end

  test "should access GraphQL if authenticated" do
    authenticate_with_token
    post :create, query: 'query Query { about { name, version } }'
    assert_response :success
    data = JSON.parse(@response.body)['data']['about']
    assert_kind_of String, data['name']
    assert_kind_of String, data['version']
  end

  test "should get node from global id" do
    authenticate_with_token
    id = Base64.encode64('About/1')
    post :create, query: "query Query { node(id: \"#{id}\") { id } }"
    assert_equal id, JSON.parse(@response.body)['data']['node']['id']
  end

  test "should get options" do
    process :options, 'OPTIONS'
    assert_response :success
  end
end
