require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class GraphqlControllerTest < ActionController::TestCase
  def setup
    super
    @controller = Api::V1::GraphqlController.new
    @url = 'https://www.youtube.com/user/MeedanTube'
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

  # Test CRUD operations for each model

  test "should create account" do
    authenticate_with_token
    assert_difference 'Account.count' do
      post :create, query: 'mutation create { createAccount(input: { clientMutationId: "1", url: "' + @url + '" }) { account { id } } }'
    end
    assert_response :success
  end

  test "should read accounts" do
    authenticate_with_token
    x1 = create_valid_account
    x2 = create_valid_account
    post :create, query: 'query read { root { accounts { edges { node { url, id } } } } }'
    edges = JSON.parse(@response.body)['data']['root']['accounts']['edges']
    assert_equal 2, edges.size
    assert_equal x1.url, edges[0]['node']['url']
    assert_equal x2.url, edges[0]['node']['url']
  end

  test "should update account" do
    authenticate_with_token
    u1 = create_user
    u2 = create_user
    a = create_valid_account user: u1
    assert_equal u1, a.user
    id = NodeIdentification.to_global_id(a.class.name, a.id)
    post :create, query: 'mutation update { updateAccount(input: { clientMutationId: "1", id: "' + id.to_s + '", user_id: ' + u2.id.to_s + ' }) { account { user_id } } }'
    assert_response :success
    assert_equal u2, a.reload.user
  end

  test "should destroy account" do
    authenticate_with_token
    a = create_valid_account
    id = NodeIdentification.to_global_id(a.class.name, a.id)
    assert_difference 'Account.count', -1 do
      post :create, query: 'mutation destroy { destroyAccount(input: { clientMutationId: "1", id: "' + id.to_s + '" }) { deletedId } }'
    end
    assert_response :success
  end
end
