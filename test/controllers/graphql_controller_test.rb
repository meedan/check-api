require_relative '../test_helper'

class GraphqlControllerTest < ActionController::TestCase
  def setup
    @controller = Api::V1::GraphqlController.new
    @url = 'https://www.youtube.com/user/MeedanTube'
    require 'sidekiq/testing'
    Sidekiq::Testing.inline!
    super
    User.unstub(:current)
    Team.unstub(:current)
    User.current = nil
    Team.current = nil
    create_verification_status_stuff
    @team = create_team
  end

  test "should access GraphQL query if not authenticated" do
    post :create, query: 'query Query { about { name, version } }'
    assert_response 200
  end

  test "should not access GraphQL mutation if not authenticated" do
    post :create, query: 'mutation Test'
    assert_response 401
  end

  test "should access About if not authenticated" do
    post :create, query: 'query About { about { name, version } }'
    assert_response :success
  end

  test "should access GraphQL if authenticated" do
    authenticate_with_user
    post :create, query: 'query Query { about { name, version, upload_max_size, upload_extensions, upload_max_dimensions, upload_min_dimensions } }', variables: '{"foo":"bar"}'
    assert_response :success
    data = JSON.parse(@response.body)['data']['about']
    assert_kind_of String, data['name']
    assert_kind_of String, data['version']
  end

  test "should not access GraphQL if authenticated as a bot" do
    authenticate_with_user(create_bot_user)
    post :create, query: 'query Query { about { name, version, upload_max_size, upload_extensions, upload_max_dimensions, upload_min_dimensions } }', variables: '{"foo":"bar"}'
    assert_response 401
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
    post :create, query: 'query Query { me { source_id, token, is_admin, current_project { id }, name, bot { id } } }'
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
    post :create, query: 'query GetById { project_media(ids: "99999,99999") { id } }'
    assert_response 404
  end

  test "should set context team" do
    authenticate_with_user
    t = create_team slug: 'context'
    post :create, query: 'query Query { about { name, version } }', team: 'context'
    assert_equal t, assigns(:context_team)
  end

  # Test CRUD operations for each model

  test "should read accounts" do
    assert_graphql_read('account', 'url')
    assert_graphql_read('account', 'metadata')
  end

  test "should read account sources" do
    assert_graphql_read('account_source', 'source_id')
  end

  test "should create account source" do
    a = create_valid_account
    s = create_source
    assert_graphql_create('account_source', { account_id: a.id, source_id: s.id })
    url = random_url
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: '{"type":"media","data":{"url":"' + url + '","type":"profile"}}')
    assert_graphql_create('account_source', { source_id: s.id, url: url })
  end

  test "should create comment" do
    p = create_project team: @team
    pm = create_project_media project: p
    assert_graphql_create('comment', { text: 'test', annotated_type: 'ProjectMedia', annotated_id: pm.id.to_s })
  end

  test "should read comments" do
    assert_graphql_read('comment', 'text')
  end

  test "should destroy comment" do
    assert_graphql_destroy('comment')
  end

  test "should create media" do
    p = create_project team: @team
    url = random_url
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    assert_graphql_create('project_media', { project_id: p.id, url: url, media_type: 'Link' })
    # create claim report
    assert_graphql_create('project_media', { project_id: p.id, media_type: 'Claim', quote: 'media quote', quote_attributions: {name: 'source name'}.to_json })
  end

  test "should create project media" do
    p = create_project team: @team
    m = create_valid_media
    assert_graphql_create('project_media', { media_id: m.id, project_id: p.id })
  end

  test "should read project medias" do
    assert_graphql_read('project_media', 'last_status')
    authenticate_with_user
    p = create_project team: @team
    pm = create_project_media project: p
    u = create_user name: 'The Annotator'
    create_team_user user: u, team: @team
    c = create_comment annotated: pm, annotator: u
    c.assign_user(u.id)
    tg = create_tag annotated: pm
    tg.assign_user(u.id)
    query = "query GetById { project_media(ids: \"#{pm.id},#{p.id}\") { tasks_count, published, language, language_code, last_status_obj {dbid}, project_source {dbid, project_id}, annotations(annotation_type: \"comment,tag\") { edges { node { dbid, assignments { edges { node { name } } }, annotator { user { name } } } } } } }"
    post :create, query: query, team: @team.slug
    assert_response :success
    data = JSON.parse(@response.body)['data']['project_media']
    assert_not_empty data['published']
    assert_not_empty data['last_status_obj']['dbid']
    assert_not_nil data['project_source']['dbid']
    assert_not_nil data['project_source']['project_id']
    assert data.has_key?('language')
    assert data.has_key?('language_code')
    assert_equal 2, data['annotations']['edges'].size
    users = data['annotations']['edges'].collect{ |e| e['node']['annotator']['user']['name'] }
    assert users.include?('The Annotator')
    users = data['annotations']['edges'].collect{ |e| e['node']['assignments']['edges'][0]['node']['name'] }
    assert users.include?('The Annotator')
  end

  test "should read project medias with team_id as argument" do
    authenticate_with_token
    p = create_project team: @team
    pm = create_project_media project: p
    query = "query GetById { project_media(ids: \"#{pm.id},#{p.id},#{@team.id}\") { published, language, last_status_obj {dbid}, log_count } }"
    post :create, query: query
    assert_response :success
    assert_not_empty JSON.parse(@response.body)['data']['project_media']['published']
    assert_not_empty JSON.parse(@response.body)['data']['project_media']['last_status_obj']['dbid']
    assert JSON.parse(@response.body)['data']['project_media'].has_key?('language')
  end

  test "should read project media and fallback to media" do
    authenticate_with_user
    p = create_project team: @team
    p2 = create_project team: @team
    m = create_valid_media
    pm = create_project_media project: p, media: m
    pm2 = create_project_media project: p2, media: m
    m2 = create_valid_media
    pm3 = create_project_media project: p, media: m2

    query = "query GetById { project_media(ids: \"#{pm3.id},#{p.id}\") { dbid } }"
    post :create, query: query, team: @team.slug
    assert_response :success
    assert_equal pm3.id, JSON.parse(@response.body)['data']['project_media']['dbid']

    query = "query GetById { project_media(ids: \"#{m2.id},#{p.id}\") { dbid } }"
    post :create, query: query, team: @team.slug
    assert_response :success
    assert_equal pm3.id, JSON.parse(@response.body)['data']['project_media']['dbid']

    query = "query GetById { project_media(ids: \"#{pm3.id},0,#{@team.id}\") { dbid } }"
    post :create, query: query, team: @team.slug
    assert_response :success
    assert_equal pm3.id, JSON.parse(@response.body)['data']['project_media']['dbid']
  end

  test "should read project media metadata" do
    authenticate_with_user
    p = create_project team: @team
    p2 = create_project team: @team
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "test media", "description":"add desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m = create_media(account: create_valid_account, url: url)
    pm1 = create_project_media project: p, media: m
    pm2 = create_project_media project: p2, media: m
    # Update media title and description with context p
    info = {title: 'Title A', description: 'Desc A'}.to_json
    pm1.metadata = info
    # Update media title and description with context p2
    info = {title: 'Title B', description: 'Desc B'}.to_json
    pm2.metadata = info
    query = "query GetById { project_media(ids: \"#{pm1.id},#{p.id}\") { metadata } }"
    post :create, query: query, team: @team.slug
    assert_response :success
    metadata = JSON.parse(@response.body)['data']['project_media']['metadata']
    assert_equal 'Title A', metadata['title']
    query = "query GetById { project_media(ids: \"#{pm2.id},#{p2.id}\") { metadata, media { metadata } } }"
    post :create, query: query, team: @team.slug
    assert_response :success
    data = JSON.parse(@response.body)['data']['project_media']
    assert_equal 'Title B', data['metadata']['title']
    # original metadata
    assert_equal 'test media', data['media']['metadata']['title']
  end

  test "should read project media overridden" do
    authenticate_with_user
    p = create_project team: @team
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "test media", "description":"add desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m = create_media(account: create_valid_account, url: url)
    pm = create_project_media project: p, media: m
    # Update media title and description
    info = {title: 'Title A', description: 'Desc A'}.to_json
    pm.metadata = info
    query = "query GetById { project_media(ids: \"#{pm.id},#{p.id}\") { overridden } }"
    post :create, query: query, team: @team.slug
    assert_response :success
    overridden = JSON.parse(@response.body)['data']['project_media']['overridden']
    assert overridden['title']
    assert overridden['description']
    assert_not overridden['username']
  end

  test "should read project media versions to find previous project" do
    authenticate_with_user
    p = create_project team: @team
    p2 = create_project team: @team
    pm = create_project_media project: p
    query = "query GetById { project_media(ids: \"#{pm.id},#{p.id}\") { dbid } }"
    post :create, query: query, team: @team.slug
    assert_response :success
    assert_equal pm.id, JSON.parse(@response.body)['data']['project_media']['dbid']
    assert_equal pm.id, JSON.parse(@response.body)['data']['project_media']['dbid']
    pm.project = p2
    pm.save!
    query = "query GetById { project_media(ids: \"#{pm.id},#{p.id}\") { dbid } }"
    post :create, query: query, team: @team.slug
    assert_response :success
    assert_equal pm.id, JSON.parse(@response.body)['data']['project_media']['dbid']
  end

  test "should create project source" do
    s = create_source
    p = create_project team: @team
    assert_graphql_create('project_source', { source_id: s.id, project_id: p.id })
    assert_graphql_create('project_source', { name: 'New source', project_id: p.id })
  end

  test "should read project sources" do
    assert_graphql_read('project_source', 'source_id')
    authenticate_with_user
    p = create_project team: @team
    p2 = create_project team: @team
    u = create_user
    ps = create_project_source project: p, user: u
    ps2 = create_project_source project: p2, source: ps.source, user: u
    create_comment annotated: ps
    create_tag annotated: ps
    create_comment annotated: ps2
    create_tag annotated: ps2
    query = "query GetById { project_source(ids: \"#{ps.id},#{p.id}\") { published, source { overridden, log(first: 1000) { edges { node { event_type } } }, log_count, tags { edges { node { dbid } } }, annotations_count(annotation_type: \"comment,tag\"), annotations(annotation_type: \"comment,tag\") { edges { node { dbid } } } }, user{id}, team{id} } }"
    post :create, query: query, team: @team.slug
    assert_response :success
    data = JSON.parse(@response.body)['data']['project_source']
    assert_not_empty data['user']['id']
    assert_not_empty data['team']['id']
    assert_equal 4, data['source']['annotations']['edges'].size
    assert_equal 4, data['source']['annotations_count']
    assert_not_empty data['published']
    assert_equal 4, data['source']['log']['edges'].size
    assert_equal 4, data['source']['log_count']
  end

  test "should read project sources with team_id as argument" do
    authenticate_with_token
    p = create_project team: @team
    ps = create_project_source project: p
    query = "query GetById { project_source(ids: \"#{ps.id},#{p.id},#{@team.id}\") { dbid } }"
    post :create, query: query
    assert_response :success
    assert_equal ps.id, JSON.parse(@response.body)['data']['project_source']['dbid']
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

  test "should read project with team_id as argument" do
    authenticate_with_token
    p = create_project team: @team
    pm = create_project_media project: p
    query = "query GetById { project(ids: \"#{p.id},#{@team.id}\") { title, description} }"
    post :create, query: query
    assert_response :success
    assert_equal p.title, JSON.parse(@response.body)['data']['project']['title']
    assert_equal p.description, JSON.parse(@response.body)['data']['project']['description']
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
    User.delete_all
    assert_graphql_read('source', 'image')
  end

  test "should update source" do
    assert_graphql_update('source', :name, 'foo', 'bar')
  end

  test "should create team" do
    assert_graphql_create('team', { name: 'test', description: 'test', slug: 'test' })
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
    # TODO test this one with a super admin user
    # assert_graphql_destroy('user')
  end

  test "should read object from project" do
    assert_graphql_read_object('project', { 'team' => 'name' })
  end

  test "should read object from account" do
    assert_graphql_read_object('account', { 'user' => 'name' })
  end

  test "should read object from project media" do
    assert_graphql_read_object('project_media', { 'project' => 'title', 'media' => 'url'})
  end

  test "should read object from project source" do
    assert_graphql_read_object('project_source', { 'project' => 'title', 'source' => 'name' })
  end

  test "should read object from team user" do
    assert_graphql_read_object('team_user', { 'team' => 'name', 'user' => 'name' })
  end

  test "should read collection from source" do
    User.delete_all
    assert_graphql_read_collection('source', { 'projects' => 'title', 'accounts' => 'url', 'project_sources' => 'project_id',
      'medias' => 'media_id', 'collaborators' => 'name' }, 'DESC')
  end

  test "should read collection from project" do
    assert_graphql_read_collection('project', { 'sources' => 'name', 'project_medias' => 'media_id', 'project_sources' => 'source_id' })
  end

  test "should read object from media" do
    assert_graphql_read_object('media', { 'account' => 'url' })
  end

  test "should read collection from team" do
    assert_graphql_read_collection('team', { 'team_users' => 'user_id', 'join_requests' => 'user_id', 'users' => 'name', 'contacts' =>  'location', 'projects' => 'title', 'sources' => 'name' })
  end

  test "should read collection from account" do
    assert_graphql_read_collection('account', { 'medias' => 'url' })
  end

  test "should read object from annotation" do
    assert_graphql_read_object('annotation', { 'annotator' => 'name', 'project_media' => 'dbid' })
  end

  test "should read object from user" do
    User.any_instance.stubs(:current_team).returns(create_team)
    assert_graphql_read_object('user', { 'source' => 'name', 'current_team' => 'name' })
    User.any_instance.unstub(:current_team)
  end

  test "should read collection from user" do
    assert_graphql_read_collection('user', { 'teams' => 'name', 'team_users' => 'role', 'annotations' => 'content' }, 'DESC')
  end

  test "should create tag" do
    p = create_project team: @team
    pm = create_project_media project: p
    assert_graphql_create('tag', { tag: 'egypt', annotated_type: 'ProjectMedia', annotated_id: pm.id.to_s })
  end

  test "should read tags" do
    assert_graphql_read('tag', 'tag')
  end

  test "should destroy tag" do
    assert_graphql_destroy('tag')
  end

  test "should read annotations" do
    assert_graphql_read('annotation', 'annotated_id')
  end

  test "should destroy annotation" do
    assert_graphql_destroy('annotation')
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

  test "should refresh account" do
    u = create_user
    authenticate_with_user(u)
    url = "http://twitter.com/example#{Time.now.to_i}"
    pender_url = CONFIG['pender_url_private'] + '/api/medias?url=' + url
    pender_refresh_url = CONFIG['pender_url_private'] + '/api/medias?refresh=1&url=' + url + '/'
    ret = { body: '{"type":"media","data":{"url":"' + url + '/","type":"profile"}}' }
    WebMock.stub_request(:get, pender_url).to_return(ret)
    WebMock.stub_request(:get, pender_refresh_url).to_return(ret)
    a = create_account user: u, url: url
    PenderClient::Mock.mock_medias_returns_parsed_data(CONFIG['pender_url_private']) do
      WebMock.disable_net_connect!
      id = a.graphql_id
      query = 'mutation update { updateAccount(input: { clientMutationId: "1", id: "' + id.to_s + '", refresh_account: 1 }) { account { id } } }'
      post :create, query: query
      assert_response :success
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
    t = create_team slug: 'context', name: 'Context Team'
    post :create, query: 'query Team { team { name } }', team: 'context'
    assert_response :success
    assert_equal 'Context Team', JSON.parse(@response.body)['data']['team']['name']
  end

  test "should get public team by context" do
    authenticate_with_user
    t1 = create_team slug: 'team1', name: 'Team 1'
    t2 = create_team slug: 'team2', name: 'Team 2'
    post :create, query: 'query PublicTeam { public_team { name } }', team: 'team1'
    assert_response :success
    assert_equal 'Team 1', JSON.parse(@response.body)['data']['public_team']['name']
  end

  test "should get public team by slug" do
    authenticate_with_user
    t1 = create_team slug: 'team1', name: 'Team 1'
    t2 = create_team slug: 'team2', name: 'Team 2'
    post :create, query: 'query PublicTeam { public_team(slug: "team2") { name } }', team: 'team1'
    assert_response :success
    assert_equal 'Team 2', JSON.parse(@response.body)['data']['public_team']['name']
  end

  test "should not get team by context" do
    authenticate_with_user
    Team.delete_all
    post :create, query: 'query Team { team { name } }', team: 'test'
    assert_response 404
  end

  test "should not get teams marked as deleted" do
    u = create_user
    t = create_team slug: 'team-to-be-deleted'
    create_team_user user: u, team: t, role: 'editor'

    authenticate_with_user(u)
    post :create, query: 'query Team { team { name } }', team: 'team-to-be-deleted'
    assert_response :success
    t.inactive = true; t.save
    post :create, query: 'query Team { team { name } }', team: 'team-to-be-deleted'
    assert_response 404
  end

  test "should not get projects from teams marked as deleted" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'editor'
    p = create_project team: t

    authenticate_with_user(u)
    query = "query GetById { project(id: \"#{p.id},#{t.id}\") { title } }"
    post :create, query: query
    assert_response :success
    assert_equal p.title, JSON.parse(@response.body)['data']['project']['title']

    t.inactive = true; t.save
    query = "query GetById { project(id: \"#{p.id},#{t.id}\") { title } }"
    post :create, query: query
    assert_response 404
  end

  test "should not get project medias from teams marked as deleted" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'editor'
    p = create_project team: t
    pm = create_project_media project: p

    authenticate_with_user(u)
    query = "query GetById { project_media(ids: \"#{pm.id},#{p.id}\") { dbid } }"
    post :create, query: query
    assert_response :success
    assert_equal pm.id, JSON.parse(@response.body)['data']['project_media']['dbid']

    t.inactive = true; t.save
    query = "query GetById { project_media(ids: \"#{pm.id},#{p.id}\") { dbid } }"
    post :create, query: query
    assert_response 404
  end

  test "should update current team based on context team" do
    u = create_user

    t1 = create_team slug: 'team1'
    create_team_user user: u, team: t1
    t2 = create_team slug: 'team2'
    t3 = create_team slug: 'team3'
    create_team_user user: u, team: t3

    u.current_team_id = t1.id
    u.save!

    assert_equal t1, u.reload.current_team

    authenticate_with_user(u)

    post :create, query: 'query Query { me { name } }', team: 'team1'
    assert_response :success
    assert_equal t1, u.reload.current_team

    post :create, query: 'query Query { me { name } }', team: 'team2'
    assert_response :success
    assert_equal t1, u.reload.current_team

    post :create, query: 'query Query { me { name } }', team: 'team3'
    assert_response :success
    assert_equal t3, u.reload.current_team
  end

  test "should get project media annotations" do
    u = create_user
    authenticate_with_user(u)
    t = create_team slug: 'team'
    create_team_user user: u, team: t
    p = create_project team: t
    m = create_media
    create_annotation_type annotation_type: 'test'
    pm = nil
    with_current_user_and_team(u, t) do
      pm = create_project_media project: p, media: m
      create_comment annotated: pm, annotator: u
      create_dynamic_annotation annotated: pm, annotator: u, annotation_type: 'test'
    end
    query = "query GetById { project_media(ids: \"#{pm.id},#{p.id}\") { last_status, domain, pusher_channel, account { url }, dbid, annotations_count(annotation_type: \"comment\"), user { name }, tags(first: 1) { edges { node { tag } } }, projects { edges { node { title } } }, log(first: 1000) { edges { node { event_type, object_after, updated_at, created_at, meta, object_changes_json, user { name }, annotation { id, created_at, updated_at }, projects(first: 2) { edges { node { title } } }, task { id }, tag { id }, teams(first: 2) { edges { node { slug } } } } } } } }"
    post :create, query: query, team: 'team'
    assert_response :success
    assert_not_equal 0, JSON.parse(@response.body)['data']['project_media']['log']['edges'].size
  end

  test "should get permissions for child objects" do
    u = create_user
    authenticate_with_user(u)
    t = create_team slug: 'team'
    create_team_user user: u, team: t
    p = create_project team: t
    pm = create_project_media project: p
    create_comment annotated: pm, annotator: u
    query = "query GetById { project(id: \"#{p.id}\") { medias_count, project_medias(first: 1) { edges { node { permissions } } } } }"
    post :create, query: query, team: 'team'
    assert_response :success
    assert_not_equal '{}', JSON.parse(@response.body)['data']['project']['project_medias']['edges'][0]['node']['permissions']
  end

  test "should get team with statuses" do
    u = create_user
    authenticate_with_user(u)
    t = create_team slug: 'team'
    create_team_user user: u, team: t, role: 'owner'
    query = "query GetById { team(id: \"#{t.id}\") { media_verification_statuses, source_verification_statuses } }"
    post :create, query: query, team: 'team'
    assert_response :success
  end

  test "should get media statuses" do
    u = create_user
    authenticate_with_user(u)
    t = create_team slug: 'team'
    create_team_user user: u, team: t
    p = create_project team: t
    m = create_media project_id: p.id
    query = "query GetById { media(ids: \"#{m.id},#{p.id}\") { verification_statuses } }"
    post :create, query: query, team: 'team'
    assert_response :success
  end

  test "should get project media team" do
    u = create_user
    authenticate_with_user(u)
    t = create_team slug: 'team'
    create_team_user user: u, team: t
    p = create_project team: t
    pm = create_project_media project: p
    query = "query GetById { project_media(ids: \"#{pm.id},#{p.id}\") { team { name } } }"
    post :create, query: query, team: 'team'
    assert_response :success
    assert_equal t.name, JSON.parse(@response.body)['data']['project_media']['team']['name']
  end

  test "should get source statuses" do
    u = create_user
    authenticate_with_user(u)
    t = create_team slug: 'team'
    create_team_user user: u, team: t
    s = create_source team: t
    query = "query GetById { source(id: \"#{s.id}\") { verification_statuses } }"
    post :create, query: query, team: 'team'
    assert_response :success
  end

  test "should return 404 if public team does not exist" do
    authenticate_with_user
    Team.delete_all
    post :create, query: 'query PublicTeam { public_team { name } }', team: 'foo'
    assert_response 404
  end

  test "should return null if public team is not found" do
    authenticate_with_user
    Team.delete_all
    post :create, query: 'query FindPublicTeam { find_public_team(slug: "foo") { name } }', team: 'foo'
    assert_response :success
    assert_nil JSON.parse(@response.body)['data']['find_public_team']
  end

  test "should run few queries to get project data" do
    n = 18 # Number of media items to be created
    m = 5 # Number of annotations per media
    u = create_user
    authenticate_with_user(u)
    t = create_team slug: 'team'
    create_team_user user: u, team: t
    p = create_project team: t
    with_current_user_and_team(u, t) do
      n.times do
        pm = create_project_media project: p
        m.times { create_comment annotated: pm, annotator: u }
      end
    end

    query = "query { project(id: \"#{p.id}\") { project_medias(first: 10000) { edges { node { permissions, log(first: 10000) { edges { node { permissions, annotation { permissions, medias { edges { node { id } } } } } }  } } } } } }"

    assert_queries 380, '<' do
      post :create, query: query, team: 'team'
    end

    assert_response :success
    assert_equal n, JSON.parse(@response.body)['data']['project']['project_medias']['edges'].size
  end

  test "should get node from global id for search" do
   authenticate_with_user
   options = {"keyword"=>"foo", "sort"=>"recent_added", "sort_type"=>"DESC"}.to_json
   id = Base64.encode64("CheckSearch/#{options}")
   post :create, query: "query Query { node(id: \"#{id}\") { id } }"
   assert_equal id, JSON.parse(@response.body)['data']['node']['id']
 end

  test "should create project media with image" do
    ft = create_field_type field_type: 'image_path', label: 'Image Path'
    at = create_annotation_type annotation_type: 'reverse_image', label: 'Reverse Image'
    create_field_instance annotation_type_object: at, name: 'reverse_image_path', label: 'Reverse Image', field_type_object: ft, optional: false
    create_bot name: 'Check Bot'
    u = create_user
    t = create_team
    create_team_user team: t, user: u
    p = create_project team: t
    authenticate_with_user(u)
    path = File.join(Rails.root, 'test', 'data', 'rails.png')
    file = Rack::Test::UploadedFile.new(path, 'image/png')
    query = 'mutation create { createProjectMedia(input: { media_type: "UploadedImage", url: "", quote: "", clientMutationId: "1", project_id: ' + p.id.to_s + ' }) { project_media { id } } }'
    assert_difference 'UploadedImage.count' do
      post :create, query: query, file: file
    end
    assert_response :success
  end

  test "should get team by slug" do
    authenticate_with_user
    t = create_team slug: 'context', name: 'Context Team'
    post :create, query: 'query Team { team(slug: "context") { name } }'
    assert_response :success
    assert_equal 'Context Team', JSON.parse(@response.body)['data']['team']['name']
  end

  test "should get ordered medias" do
    u = create_user
    authenticate_with_user(u)
    t = create_team slug: 'team'
    create_team_user user: u, team: t
    p = create_project team: t
    pms = []
    5.times do
      pms << create_project_media(project: p)
    end
    query = "query { project(id: \"#{p.id}\") { project_medias(first: 4) { edges { node { dbid } } } } }"

    post :create, query: query, team: 'team'

    assert_response :success
    assert_equal pms.last.dbid, JSON.parse(@response.body)['data']['project']['project_medias']['edges'].first['node']['dbid']
  end

  test "should get language from header" do
    authenticate_with_user
    @request.headers['Accept-Language'] = 'pt-BR'
    post :create, query: 'query Query { me { name } }'
    assert_equal :pt, I18n.locale
  end

  test "should get default if language is not supported" do
    authenticate_with_user
    @request.headers['Accept-Language'] = 'mk-MK'
    post :create, query: 'query Query { me { name } }'
    assert_equal :en, I18n.locale
  end

  test "should get closest language" do
    authenticate_with_user
    @request.headers['Accept-Language'] = 'mk-MK, fr-FR'
    post :create, query: 'query Query { me { name } }'
    assert_equal :fr, I18n.locale
  end

  test "should create dynamic annotation" do
    p = create_project team: @team
    pm = create_project_media project: p
    at = create_annotation_type annotation_type: 'location', label: 'Location', description: 'Where this media happened'
    ft1 = create_field_type field_type: 'text_field', label: 'Text Field', description: 'A text field'
    ft2 = create_field_type field_type: 'location', label: 'Location', description: 'A pair of coordinates (lat, lon)'
    fi1 = create_field_instance name: 'location_position', label: 'Location position', description: 'Where this happened', field_type_object: ft2, optional: false, settings: { view_mode: 'map' }
    fi2 = create_field_instance name: 'location_name', label: 'Location name', description: 'Name of the location', field_type_object: ft1, optional: false, settings: {}
    fields = { location_name: 'Salvador', location_position: '3,-51' }.to_json
    assert_graphql_create('dynamic', { set_fields: fields, annotated_type: 'ProjectMedia', annotated_id: pm.id.to_s, annotation_type: 'location' })
  end

  test "should create task" do
    p = create_project team: @team
    pm = create_project_media project: p
    assert_graphql_create('task', { label: 'test', type: 'yes_no', annotated_type: 'ProjectMedia', annotated_id: pm.id.to_s })
  end

  test "should destroy task" do
    assert_graphql_destroy('task')
  end

  test "should create comment with image" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u
    p = create_project team: t
    pm = create_project_media project: p
    authenticate_with_user(u)
    path = File.join(Rails.root, 'test', 'data', 'rails.png')
    file = Rack::Test::UploadedFile.new(path, 'image/png')
    query = 'mutation create { createComment(input: { text: "Comment with image", clientMutationId: "1", annotated_type: "ProjectMedia", annotated_id: "' + pm.id.to_s + '" }) { comment { id } } }'
    assert_difference 'Comment.count' do
      post :create, query: query, file: file
    end
    assert_response :success
    data = JSON.parse(Annotation.where(annotation_type: 'comment').last.content)
    assert_match /\.png$/, data['embed']
    assert_match /\.png$/, data['thumbnail']
  end

  test "should not query invalid type" do
    u = create_user
    p = create_project team: @team
    create_team_user user: u, team: @team, role: 'owner'
    authenticate_with_user(u)
    id = Base64.encode64("InvalidType/#{p.id}")
    query = "mutation destroy { destroyProject(input: { clientMutationId: \"1\", id: \"#{id}\" }) { deletedId } }"
    post :create, query: query, team: @team.slug
    assert_response 400
  end

  test "should reset password if email is found" do
    u = create_user email: 'foo@bar.com'
    p = create_project team: @team
    create_team_user user: u, team: @team, role: 'owner'
    query = "mutation resetPassword { resetPassword(input: { clientMutationId: \"1\", email: \"foo@bar.com\" }) { success } }"
    post :create, query: query, team: @team.slug
    assert_response :success
  end

  test "should not reset password if email is not found" do
    u = create_user email: 'test@bar.com'
    p = create_project team: @team
    create_team_user user: u, team: @team, role: 'owner'
    query = "mutation resetPassword { resetPassword(input: { clientMutationId: \"1\", email: \"foo@bar.com\" }) { success } }"
    post :create, query: query, team: @team.slug
    assert_response 404
  end

  test "should resend confirmation" do
    u = create_user
    # Query with valid id
    query = "mutation resendConfirmation { resendConfirmation(input: { clientMutationId: \"1\", id: #{u.id} }) { success } }"
    post :create, query: query, team: @team.slug
    assert_response :success
    # Query with non existing ID
    id = rand(6 ** 6)
    query = "mutation resendConfirmation { resendConfirmation(input: { clientMutationId: \"1\", id: #{id} }) { success } }"
    post :create, query: query, team: @team.slug
    assert_response 404
  end

  test "should handle user invitations" do
    u = create_user
    authenticate_with_user(u)
    # send invitation
    members = '[{\"role\":\"contributor\",\"email\":\"test1@local.com, test2@local.com\"},{\"role\":\"journalist\",\"email\":\"test3@local.com\"}]'
    query = 'mutation userInvitation { userInvitation(input: { clientMutationId: "1", members: "'+ members +'" }) { success } }'
    post :create, query: query, team: @team.slug
    assert_response :success
    # resend/cancel invitation
    query = 'mutation resendCancelInvitation { resendCancelInvitation(input: { clientMutationId: "1", email: "notexist@local.com", action: "resend" }) { success } }'
    post :create, query: query, team: @team.slug
    assert_response 404
    query = 'mutation resendCancelInvitation { resendCancelInvitation(input: { clientMutationId: "1", email: "test1@local.com", action: "resend" }) { success } }'
    post :create, query: query, team: @team.slug
    assert_response :success
    query = 'mutation resendCancelInvitation { resendCancelInvitation(input: { clientMutationId: "1", email: "test1@local.com", action: "cancel" }) { success } }'
    post :create, query: query, team: @team.slug
    assert_response :success
  end

  test "should handle delete user" do
    u = create_user
    authenticate_with_user(u)
    query = 'mutation deleteCheckUser { deleteCheckUser(input: { clientMutationId: "1", id: 111 }) { success } }'
    post :create, query: query, team: @team.slug
    assert_response 404
    query = "mutation deleteCheckUser { deleteCheckUser(input: { clientMutationId: \"1\", id: #{u.id} }) { success } }"
    post :create, query: query, team: @team.slug
    assert_response :success
  end

  test "should disconnect user login account" do
    u = create_user
    s = u.source
    omniauth_info = {"info"=> { "name" => "test" } }
    a = create_account source: s, user: u, provider: 'slack', uid: '123456', omniauth_info: omniauth_info
    authenticate_with_user(u)
    query = "mutation userDisconnectLoginAccount { userDisconnectLoginAccount(input: { clientMutationId: \"1\", provider: \"#{a.provider}\", uid: \"#{a.uid}\" }) { success } }"
    post :create, query: query, team: @team.slug
    assert_response :success
    User.stubs(:current).returns(nil)
    query = "mutation userDisconnectLoginAccount { userDisconnectLoginAccount(input: { clientMutationId: \"1\", provider: \"#{a.provider}\", uid: \"#{a.uid}\" }) { success } }"
    post :create, query: query, team: @team.slug
    assert_response 404
    User.unstub(:current)
  end

  test "should change password if token is found and passwords are present and match" do
    u = create_user
    t = u.send_reset_password_instructions
    query = "mutation changePassword { changePassword(input: { clientMutationId: \"1\", reset_password_token: \"#{t}\", password: \"123456789\", password_confirmation: \"123456789\" }) { success } }"
    post :create, query: query
    sleep 1
    assert_response :success
    assert !JSON.parse(@response.body).has_key?('errors')
  end

  test "should not change password if token is not found and passwords are present and match" do
    u = create_user
    t = u.send_reset_password_instructions
    query = "mutation changePassword { changePassword(input: { clientMutationId: \"1\", reset_password_token: \"#{t}x\", password: \"123456789\", password_confirmation: \"123456789\" }) { success } }"
    post :create, query: query
    sleep 1
    assert_response 400
  end

  test "should not change password if token is found but passwords are not present" do
    u = create_user
    t = u.send_reset_password_instructions
    query = "mutation changePassword { changePassword(input: { clientMutationId: \"1\", reset_password_token: \"#{t}\", password: \"123456789\" }) { success } }"
    post :create, query: query
    sleep 1
    assert_response :success
    assert JSON.parse(@response.body).has_key?('errors')
  end

  test "should not change password if token is found but passwords do not match" do
    u = create_user
    t = u.send_reset_password_instructions
    query = "mutation changePassword { changePassword(input: { clientMutationId: \"1\", reset_password_token: \"#{t}\", password: \"123456789\", password_confirmation: \"12345678\" }) { success } }"
    post :create, query: query
    sleep 1
    assert_response 400
  end

  test "should access GraphQL if authenticated with API key" do
    authenticate_with_token
    assert_nil ApiKey.current
    post :create, query: 'query Query { about { name, version } }'
    assert_response :success
    assert_not_nil ApiKey.current
  end

  test "should get supported languages" do
    authenticate_with_user
    @request.headers['Accept-Language'] = 'pt-BR'
    post :create, query: 'query Query { about { languages_supported } }'
    assert_equal :pt, I18n.locale
    assert_response :success
    languages = JSON.parse(JSON.parse(@response.body)['data']['about']['languages_supported'])
    assert_equal 'Francês', languages['fr']
  end

  test "should get field value and dynamic annotation(s)" do
    [DynamicAnnotation::FieldType, DynamicAnnotation::AnnotationType, DynamicAnnotation::FieldInstance].each { |klass| klass.delete_all }
    create_annotation_type_and_fields('Metadata', { 'Value' => ['JSON', false] })
    ft1 = create_field_type(field_type: 'select', label: 'Select')
    ft2 = create_field_type(field_type: 'text', label: 'Text')
    at = create_annotation_type annotation_type: 'verification_status', label: 'Verification Status'
    create_field_instance annotation_type_object: at, name: 'verification_status_status', label: 'Verification Status', field_type_object: ft1, optional: false
    create_field_instance annotation_type_object: at, name: 'verification_status_note', label: 'Verification Status Note', field_type_object: ft2, optional: true

    authenticate_with_user
    p = create_project team: @team
    pm = create_project_media project: p
    a = create_dynamic_annotation annotation_type: 'verification_status', annotated: pm, set_fields: { verification_status_status: 'verified' }.to_json
    query = "query GetById { project_media(ids: \"#{pm.id},#{p.id}\") { annotation(annotation_type: \"verification_status\") { dbid }, field_value(annotation_type_field_name: \"verification_status:verification_status_status\"), annotations(annotation_type: \"verification_status\") { edges { node { dbid } } } } }"
    post :create, query: query, team: @team.slug
    assert_response :success
    data = JSON.parse(@response.body)['data']['project_media']
    assert_equal a.id, data['annotation']['dbid'].to_i
    assert_equal a.id, data['annotations']['edges'][0]['node']['dbid'].to_i
    assert_equal 'verified', data['field_value']
  end

  test "should create media with custom field" do
    authenticate_with_user
    create_annotation_type_and_fields('Syrian Archive Data', { 'Id' => ['Id', false] })
    p = create_project team: @team
    fields = '{\"annotation_type\":\"syrian_archive_data\",\"set_fields\":\"{\\\"syrian_archive_data_id\\\":\\\"123456\\\"}\"}'
    query = 'mutation create { createProjectMedia(input: { url: "", media_type: "Claim", quote: "Test", clientMutationId: "1", set_annotation: "' + fields + '", project_id: ' + p.id.to_s + ' }) { project_media { id } } }'
    post :create, query: query, team: @team.slug
    assert_response :success
    assert_equal '123456', ProjectMedia.last.get_annotations('syrian_archive_data').last.load.get_field_value('syrian_archive_data_id')
  end

  test "should manage auto tasks of a team" do
    u = create_user
    t = create_team
    create_team_task label: 'A', team_id: t.id
    id = t.graphql_id
    create_team_user user: u, team: t, role: 'owner'
    authenticate_with_user(u)
    assert_equal ['A'], t.team_tasks.map(&:label)
    task = '{\"label\":\"B\",\"task_type\":\"free_text\",\"description\":\"\",\"projects\":[],\"options\":[]}'
    query = 'mutation { updateTeam(input: { clientMutationId: "1", id: "' + id + '", remove_auto_task: "A", add_auto_task: "' + task + '" }) { team { id } } }'
    post :create, query: query, team: t.slug
    assert_response :success
    assert_equal ['B'], t.reload.team_tasks.map(&:label)
  end

  test "should manage admin ui settings" do
    u = create_user
    t = create_team
    id = t.graphql_id
    create_team_user user: u, team: t, role: 'owner'
    authenticate_with_user(u)
    # media verification status
    statuses = '{\"label\":\"Verification Status\",\"default\":\"1\",\"active\":\"2\",\"statuses\":[{\"id\":\"1\",\"label\":\"1\",\"description\":\"\",\"completed\":\"\",\"style\":{\"color\":\"#f71f40\",\"backgroundColor\":\"#f71f40\",\"borderColor\":\"#f71f40\"}},{\"id\":\"2\",\"label\":\"2\",\"description\":\"\",\"completed\":\"\",\"style\":{\"color\":\"#e3dc1c\",\"backgroundColor\":\"#e3dc1c\",\"borderColor\":\"#e3dc1c\"}},{\"id\":\"3\",\"label\":\"3\",\"description\":\"\",\"completed\":\"1\",\"style\":{\"color\":\"#000000\",\"backgroundColor\":\"#000000\",\"borderColor\":\"#000000\"}}]}'
    query = 'mutation { updateTeam(input: { clientMutationId: "1", id: "' + id + '", add_media_verification_statuses: "' + statuses + '" }) { team { id } } }'
    post :create, query: query, team: t.slug
    assert_response :success
    assert_equal ["1", "2", "3"], t.reload.get_media_verification_statuses[:statuses].collect{ |t| t[:id] }.sort
    # add team tasks
    tasks = '[{\"label\":\"A?\",\"description\":\"\",\"required\":\"\",\"type\":\"free_text\",\"mapping\":{\"type\":\"text\",\"match\":\"\",\"prefix\":\"\"}},{\"label\":\"B?\",\"description\":\"\",\"required\":\"\",\"type\":\"single_choice\",\"options\":[{\"label\":\"A\"},{\"label\":\"B\"}],\"mapping\":{\"type\":\"text\",\"match\":\"\",\"prefix\":\"\"}}]'
    query = 'mutation { updateTeam(input: { clientMutationId: "1", id: "' + id + '", set_team_tasks: "' + tasks + '", disclaimer: "Test" }) { team { id } } }'
    post :create, query: query, team: t.slug
    assert_response :success
    assert_equal ['A?', 'B?'], t.reload.team_tasks.map(&:label).sort
    assert_equal 'Test', t.reload.get_disclaimer
  end

  test "should read account sources from source" do
    u = create_user
    authenticate_with_user(u)
    s = create_source user: u
    create_account_source source_id: s.id
    query = "query GetById { source(id: \"#{s.id}\") { account_sources { edges { node { source { id }, account { id } } } } } }"
    post :create, query: query
    assert_response :success
  end

  test "should search for archived items" do
    u = create_user
    authenticate_with_user(u)
    t = create_team slug: 'team'
    create_team_user user: u, team: t
    p = create_project team: t
    2.times do
      pm = create_project_media project: p, disable_es_callbacks: false
      pm.archived = true
      pm.save!
      sleep 1
    end

    query = 'query CheckSearch { search(query: "{\"archived\":1}") { id,medias(first:20){edges{node{id,dbid,url,quote,published,updated_at,metadata,log_count,verification_statuses,overridden,project_id,pusher_channel,domain,permissions,last_status,last_status_obj{id,dbid},project{id,dbid,title},project_source{dbid,id},media{url,quote,embed_path,thumbnail_path,id},user{name,source{dbid,accounts(first:10000){edges{node{url,id}}},id},id},team{slug,id},tags(first:10000){edges{node{tag,id}}}}}}}}'

    post :create, query: query, team: 'team'

    assert_response :success
    assert_equal 2, JSON.parse(@response.body)['data']['search']['medias']['edges'].size
  end

  test "should search for single item" do
    u = create_user
    authenticate_with_user(u)
    t = create_team slug: 'team'
    create_team_user user: u, team: t
    p = create_project team: t
    pm = create_project_media project: p, disable_es_callbacks: false
    sleep 1

    query = 'query CheckSearch { search(query: "{}") { id,medias(first:20){edges{node{id,dbid,url,quote,published,updated_at,metadata,log_count,verification_statuses,overridden,project_id,pusher_channel,domain,permissions,last_status,last_status_obj{id,dbid},project{id,dbid,title},project_source{dbid,id},media{url,quote,embed_path,thumbnail_path,id},user{name,source{dbid,accounts(first:10000){edges{node{url,id}}},id},id},team{slug,id},tags(first:10000){edges{node{tag,id}}}}}}}}'

    post :create, query: query, team: 'team'

    assert_response :success
    assert_equal 1, JSON.parse(@response.body)['data']['search']['medias']['edges'].size
  end

  # Please add new tests to test/controllers/graphql_controller_2_test.rb
end
