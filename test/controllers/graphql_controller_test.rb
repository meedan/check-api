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
    authenticate_with_user
    post :create, query: 'query Query { about { name, version } }'
    assert_response :success
    data = JSON.parse(@response.body)['data']['about']
    assert_kind_of String, data['name']
    assert_kind_of String, data['version']
  end

  test "should get node from global id" do
    authenticate_with_user
    id = Base64.encode64('About/1')
    post :create, query: "query Query { node(id: \"#{id}\") { id } }"
    assert_equal id, JSON.parse(@response.body)['data']['node']['id']
  end

  test "should get current user" do
    u = create_user name: 'Test User'
    authenticate_with_user(u)
    post :create, query: 'query Query { me { name } }'
    assert_response :success
    data = JSON.parse(@response.body)['data']['me']
    assert_equal 'Test User', data['name']
  end

  test "should get current user if logged in with token" do
    u = create_user name: 'Test User'
    authenticate_with_user_token(u.token)
    post :create, query: 'query Query { me { name } }'
    assert_response :success
    data = JSON.parse(@response.body)['data']['me']
    assert_equal 'Test User', data['name']
  end

  test "should return 404 if object does not exist" do
    authenticate_with_user
    post :create, query: 'query GetById { media(id: "999999999999999999999999999") { id } }'
    assert_response 404
  end

  test "should set context team" do
    authenticate_with_user
    t = create_team subdomain: 'context'
    @request.headers.merge!({ 'origin': 'http://context.localhost:3333' })
    post :create, query: 'query Query { about { name, version } }'
    assert_equal t, assigns(:context_team)
  end

  # Test CRUD operations for each model

  test "should create account" do
    PenderClient::Mock.mock_medias_returns_parsed_data(CONFIG['pender_host']) do
      WebMock.disable_net_connect! allow: [CONFIG['elasticsearch_host'].to_s + ':' + CONFIG['elasticsearch_port'].to_s]
      assert_graphql_create('account', { url: @url })
    end
  end

  test "should read accounts" do
    assert_graphql_read('account', 'url')
  end

  test "should update account" do
    u1 = create_user
    u2 = create_user
    assert_graphql_update('account', :user_id, u1.id, u2.id)
  end

  test "should create comment" do
    p = create_project team: @team
    assert_graphql_create('comment', { text: 'test', annotated_type: 'Project', annotated_id: p.id.to_s }) { sleep 1 }
  end

  test "should read comments" do
    assert_graphql_read('comment', 'text') { sleep 1 }
  end

  test "should update comment" do
    assert_graphql_update('comment', 'text', 'foo', 'bar') { sleep 1 }
  end

  test "should destroy comment" do
    assert_graphql_destroy('comment') { sleep 1 }
  end

  test "should create media" do
    url = random_url
    pender_url = CONFIG['pender_host'] + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    assert_graphql_create('media', { url: url, project_id: @project.id })
  end

  test "should read medias" do
    assert_graphql_read('media', 'url')
    assert_graphql_read('media', 'jsondata')
    assert_graphql_read('media', 'published')
    assert_graphql_read('media', 'last_status')
  end

  test "should update media" do
    u1, u2 = create_user, create_user
    assert_graphql_update('media', :user_id, u1.id, u2.id)
  end

  test "should destroy media" do
    assert_graphql_destroy('media')
  end

  test "should create project source" do
    s = create_source
    p = create_project team: @team
    assert_graphql_create('project_source', { source_id: s.id, project_id: p.id })
  end

  test "should read project sources" do
    assert_graphql_read('project_source', 'source_id')
  end

  test "should update project source" do
    p1 = create_project team: @team
    p2 = create_project team: @team
    assert_graphql_update('project_source', :project_id, p1.id, p2.id)
  end

  test "should destroy project source" do
    assert_graphql_destroy('project_source')
  end

  test "should create project" do
    assert_graphql_create('project', { title: 'test', description: 'test' })
  end

  test "should read project" do
    assert_graphql_read('project', 'title')
  end

  test "should update project" do
    assert_graphql_update('project', :title, 'foo', 'bar')
  end

  test "should destroy project" do
    assert_graphql_destroy('project')
  end

  test "should create source" do
    assert_graphql_create('source', { name: 'test', slogan: 'test' })
  end

  test "should read source" do
    Source.delete_all
    assert_graphql_read('source', 'image')
  end

  test "should update source" do
    assert_graphql_update('source', :name, 'foo', 'bar')
  end

  test "should create team" do
    assert_graphql_create('team', { name: 'test', description: 'test', subdomain: 'test' })
  end

  test "should read team" do
    assert_graphql_read('team', 'name')
  end

  test "should update team" do
    assert_graphql_update('team', :name, 'foo', 'bar')
  end

  test "should destroy team" do
    assert_graphql_destroy('team')
  end

  test "should create team user" do
    u = create_user
    assert_graphql_create('team_user', { team_id: @team.id, user_id: u.id, status: 'member' })
  end

  test "should read team user" do
    assert_graphql_read('team_user', 'user_id')
  end

  test "should update team user" do
    t = create_team
    assert_graphql_update('team_user', :team_id, t.id, @team.id)
  end

  test "should read user" do
    assert_graphql_read('user', 'email')
  end

  test "should update user" do
    assert_graphql_update('user', :name, 'Foo', 'Bar')
  end

  test "should destroy user" do
    assert_graphql_destroy('user')
  end

  test "should read object from project" do
    assert_graphql_read_object('project', { 'team' => 'name' })
  end

  test "should read object from account" do
    assert_graphql_read_object('account', { 'user' => 'name', 'source' => 'name' })
  end

  test "should read object from media" do
    assert_graphql_read_object('media', { 'account' => 'url', 'user' => 'name' })
  end

  test "should read object from project source" do
    assert_graphql_read_object('project_source', { 'project' => 'title', 'source' => 'name' })
  end

  test "should read object from team user" do
    assert_graphql_read_object('team_user', { 'team' => 'name', 'user' => 'name' })
  end

  test "should read collection from source" do
    assert_graphql_read_collection('source', { 'projects' => 'title', 'accounts' => 'url', 'project_sources' => 'project_id',
                                               'annotations' => 'content', 'medias' => 'url', 'collaborators' => 'name',
                                               'tags'=> 'tag', 'comments' => 'text' }, 'DESC')
  end

  test "should read collection from media" do
    assert_graphql_read_collection('media', { 'projects' => 'title', 'annotations' => 'content', 'tags' => 'tag' }, 'DESC')
  end

  test "should read collection from project" do
    assert_graphql_read_collection('project', { 'sources' => 'name', 'medias' => 'url', 'annotations' => 'content' })
  end

  test "should read collection from team" do
    assert_graphql_read_collection('team', { 'team_users' => 'user_id', 'users' => 'name', 'contacts' =>  'location', 'projects' => 'title' })
  end

  test "should read collection from account" do
    assert_graphql_read_collection('account', { 'medias' => 'url' })
  end

  test "should read object from annotation" do
    assert_graphql_read_object('annotation', { 'annotator' => 'name' })
  end

  test "should read object from user" do
    User.any_instance.stubs(:current_team).returns(create_team)
    assert_graphql_read_object('user', { 'source' => 'name', 'current_team' => 'name' })
    User.any_instance.unstub(:current_team)
  end

  test "should read collection from user" do
    assert_graphql_read_collection('user', { 'teams' => 'name', 'team_users' => 'role' })
  end

  test "should create status" do
    s = create_source
    p = create_project team: @team
    create_project_source project: p, source: s
    assert_graphql_create('status', { status: 'Credible', annotated_type: 'Source', annotated_id: s.id.to_s }) { sleep 1 }
  end

  test "should read statuses" do
    assert_graphql_read('status', 'status') { sleep 1 }
  end

  test "should destroy status" do
    assert_graphql_destroy('status') { sleep 1 }
  end

  test "should create tag" do
    s = create_source
    assert_graphql_create('tag', { tag: 'egypt', annotated_type: 'Source', annotated_id: s.id.to_s }) { sleep 1 }
  end

  test "should read tags" do
    assert_graphql_read('tag', 'tag') { sleep 1 }
  end

  test "should destroy tag" do
    assert_graphql_destroy('tag') { sleep 1 }
  end

  test "should read annotations" do
    assert_graphql_read('annotation', 'context_id') { sleep 1 }
  end

  test "should destroy annotation" do
    assert_graphql_destroy('annotation') { sleep 1 }
  end

  test "should get source by id" do
    assert_graphql_get_by_id('source', 'name', 'Test')
  end

  test "should get user by id" do
    assert_graphql_get_by_id('user', 'name', 'Test')
  end

  test "should get team by id" do
    assert_graphql_get_by_id('team', 'name', 'Test')
  end

  test "should get media by id" do
    u = create_user
    assert_graphql_get_by_id('media', 'user_id', u.id)
  end

  test "should return validation error" do
    authenticate_with_user
    url = 'https://www.youtube.com/user/MeedanTube'

    PenderClient::Mock.mock_medias_returns_parsed_data(CONFIG['pender_host']) do
      WebMock.disable_net_connect! allow: [CONFIG['elasticsearch_host'].to_s + ':' + CONFIG['elasticsearch_port'].to_s]
      query = 'mutation create { createAccount(input: { clientMutationId: "1", url: "' + url + '" }) { account { id } } }'

      assert_difference 'Account.count' do
        post :create, query: query
      end
      assert_response :success

      assert_no_difference 'Account.count' do
        post :create, query: query
      end
      assert_response 400
    end
  end

  test "should create contact" do
    assert_graphql_create('contact', { location: 'my location', phone: '00201099998888', team_id: @team.id })
  end

  test "should read contact" do
    assert_graphql_read('contact', 'location')
  end

  test "should update contact" do
    assert_graphql_update('contact', :location, 'foo', 'bar')
  end

  test "should destroy contact" do
    assert_graphql_destroy('contact')
  end

  test "should read object from contact" do
    assert_graphql_read_object('contact', { 'team' => 'name' })
  end

  test "should get access denied on source by id" do
    authenticate_with_user
    s = create_source user: create_user
    query = "query GetById { source(id: \"#{s.id}\") { name } }"
    post :create, query: query
    assert_response 403
  end

  test "should get team by context" do
    authenticate_with_user
    t = create_team subdomain: 'context', name: 'Context Team'
    @request.headers.merge!({ 'origin': 'http://context.localhost:3333' })
    post :create, query: 'query Team { team { name } }'
    assert_response :success
    assert_equal 'Context Team', JSON.parse(@response.body)['data']['team']['name']
  end

  test "should not get team by context" do
    authenticate_with_user
    t = create_team subdomain: 'context', name: 'Context Team'
    @request.headers.merge!({ 'origin': 'http://test.localhost:3333' })
    post :create, query: 'query Team { team { name } }'
    assert_response 404
  end

  test "should update current team based on context team" do
    u = create_user

    t1 = create_team subdomain: 'team1'
    create_team_user user: u, team: t1
    t2 = create_team subdomain: 'team2'
    t3 = create_team subdomain: 'team3'
    create_team_user user: u, team: t3

    u.current_team_id = t1.id
    u.save!

    assert_equal t1, u.reload.current_team

    authenticate_with_user(u)

    @request.headers.merge!({ 'origin': 'http://team1.localhost:3333' })
    post :create, query: 'query Query { me { name } }'
    assert_response :success
    assert_equal t1, u.reload.current_team

    @request.headers.merge!({ 'origin': 'http://team2.localhost:3333' })
    post :create, query: 'query Query { me { name } }'
    assert_response :success
    assert_equal t1, u.reload.current_team

    @request.headers.merge!({ 'origin': 'http://team3.localhost:3333' })
    post :create, query: 'query Query { me { name } }'
    assert_response :success
    assert_equal t3, u.reload.current_team
  end
end
