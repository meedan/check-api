require_relative '../test_helper'

class GraphqlControllerTest < ActionController::TestCase
  def setup
    @controller = Api::V1::GraphqlController.new
    @url = 'https://www.youtube.com/user/MeedanTube'
    require 'sidekiq/testing'
    Sidekiq::Testing.inline!
    super
    MediaSearch.delete_index
    MediaSearch.create_index
    sleep 1
    User.unstub(:current)
    Team.unstub(:current)
    User.current = nil
  end

  test "should access GraphQL query if not authenticated" do
    post :create, query: 'query Query { about { name, version } }'
    assert_response 200
  end

  test "should not access GraphQL mutation if not authenticated" do
    post :create, query: 'mutation Test { }'
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

  test "should create account" do
    PenderClient::Mock.mock_medias_returns_parsed_data(CONFIG['pender_url_private']) do
      WebMock.disable_net_connect! allow: [CONFIG['elasticsearch_host'].to_s + ':' + CONFIG['elasticsearch_port'].to_s]
      assert_graphql_create('account', { url: @url })
    end
  end

  test "should read accounts" do
    assert_graphql_read('account', 'url')
    assert_graphql_read('account', 'embed')
  end

  test "should create comment" do
    p = create_project team: @team
    pm = create_project_media project: p
    assert_graphql_create('comment', { text: 'test', annotated_type: 'ProjectMedia', annotated_id: pm.id.to_s })
  end

  test "should read comments" do
    assert_graphql_read('comment', 'text')
  end

  test "should update comment" do
    assert_graphql_update('comment', 'text', 'foo', 'bar')
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
    assert_graphql_create('project_media', { project_id: p.id, url: url })
    # create claim report
    assert_graphql_create('project_media', { project_id: p.id, quote: 'media quote' })
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
    create_comment annotated: pm, annotator: u
    create_tag annotated: pm
    query = "query GetById { project_media(ids: \"#{pm.id},#{p.id}\") { published, language, language_code, last_status_obj {dbid}, annotations(annotation_type: \"comment,tag\") { edges { node { dbid, annotator { user { name } } } } } } }"
    post :create, query: query, team: @team.slug
    assert_response :success
    assert_not_empty JSON.parse(@response.body)['data']['project_media']['published']
    assert_not_empty JSON.parse(@response.body)['data']['project_media']['last_status_obj']['dbid']
    assert JSON.parse(@response.body)['data']['project_media'].has_key?('language')
    assert JSON.parse(@response.body)['data']['project_media'].has_key?('language_code')
    assert_equal 2, JSON.parse(@response.body)['data']['project_media']['annotations']['edges'].size
    users = JSON.parse(@response.body)['data']['project_media']['annotations']['edges'].collect{ |e| e['node']['annotator']['user']['name'] }
    assert users.include?('The Annotator')
  end

  test "should read project medias with team_id as argument" do
    authenticate_with_token
    p = create_project team: @team
    pm = create_project_media project: p
    query = "query GetById { project_media(ids: \"#{pm.id},#{p.id},#{@team.id}\") { published, language, last_status_obj {dbid}, annotations_count(annotation_type: \"translation\"), log_count } }"
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
  end

  test "should read project media embed" do
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
    pm1.embed = info
    # Update media title and description with context p2
    info = {title: 'Title B', description: 'Desc B'}.to_json
    pm2.embed= info
    query = "query GetById { project_media(ids: \"#{pm1.id},#{p.id}\") { embed } }"
    post :create, query: query, team: @team.slug
    assert_response :success
    embed = JSON.parse(@response.body)['data']['project_media']['embed']
    assert_equal 'Title A', JSON.parse(embed)['title']
    query = "query GetById { project_media(ids: \"#{pm2.id},#{p2.id}\") { embed } }"
    post :create, query: query, team: @team.slug
    assert_response :success
    embed = JSON.parse(@response.body)['data']['project_media']['embed']
    assert_equal 'Title B', JSON.parse(embed)['title']
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
    pm.embed = info
    query = "query GetById { project_media(ids: \"#{pm.id},#{p.id}\") { overridden } }"
    post :create, query: query, team: @team.slug
    assert_response :success
    overridden = JSON.parse(@response.body)['data']['project_media']['overridden']
    overridden = JSON.parse(overridden)
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
    ps = create_project_source project: p, user: create_user
    create_comment annotated: ps
    create_tag annotated: ps
    query = "query GetById { project_source(ids: \"#{ps.id},#{p.id}\") { published, user{id}, team{id}, tags { edges { node { dbid } } },annotations_count(annotation_type: \"comment,tag\"), annotations(annotation_type: \"comment,tag\") { edges { node { dbid } } } } }"
    post :create, query: query, team: @team.slug
    assert_response :success
    data = JSON.parse(@response.body)['data']['project_source']
    assert_not_empty data['published']
    assert_not_empty data['user']['id']
    assert_not_empty data['team']['id']
    assert_equal 2, data['annotations']['edges'].size
    assert_equal 2, data['annotations_count']
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
    assert_graphql_destroy('user')
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
     'annotations' => 'content', 'medias' => 'media_id', 'collaborators' => 'name',
     'tags'=> 'tag', 'comments' => 'text' }, 'DESC')
  end

  test "should read collection from project" do
    assert_graphql_read_collection('project', { 'sources' => 'name', 'project_medias' => 'media_id', 'project_sources' => 'source_id' })
  end

  test "should read object from media" do
    assert_graphql_read_object('media', { 'account' => 'url' })
  end

  test "should read collection from team" do
    assert_graphql_read_collection('team', { 'team_users' => 'user_id', 'users' => 'name', 'contacts' =>  'location', 'projects' => 'title' })
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

  test "should create status" do
    s = create_source
    p = create_project team: @team
    ps = create_project_source project: p, source: s
    assert_graphql_create('status', { status: 'credible', annotated_type: 'ProjectSource', annotated_id: ps.id.to_s })
  end

  test "should read statuses" do
    assert_graphql_read('status', 'status')
  end

  test "should destroy status" do
    assert_graphql_destroy('status')
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

  test "should read versions" do
    u = create_user
    create_team_user user: u
    assert_graphql_read('version', 'dbid')
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

  test "should return validation error" do
    authenticate_with_user
    url = 'https://www.youtube.com/user/MeedanTube'

    PenderClient::Mock.mock_medias_returns_parsed_data(CONFIG['pender_url_private']) do
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
    Team.stubs(:current).returns(nil)
    t = create_team slug: 'context', name: 'Context Team'
    post :create, query: 'query Team { team { name } }', team: 'test'
    assert_response 404
    Team.unstub(:current)
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
    query = "query GetById { project_media(ids: \"#{pm.id},#{p.id}\") { last_status, domain, pusher_channel, account { url }, dbid, annotations_count(annotation_type: \"translation,comment\"), user { name }, tags(first: 1) { edges { node { tag } } }, projects { edges { node { title } } }, log(first: 1000) { edges { node { event_type, object_after, created_at, meta, object_changes_json, user { name }, annotation { id }, projects(first: 2) { edges { node { title } } }, task { id } } } } } }"
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

  test "should search media" do
    u = create_user
    p = create_project team: @team
    m1 = create_valid_media
    pm1 = create_project_media project: p, media: m1, disable_es_callbacks: false
    authenticate_with_user(u)
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "title_a", "description":"search_desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m2 = create_media(account: create_valid_account, url: url)
    pm2 = create_project_media project: p, media: m2, disable_es_callbacks: false
    sleep 10
    query = 'query Search { search(query: "{\"keyword\":\"title_a\",\"projects\":[' + p.id.to_s + ']}") { number_of_results, medias(first: 10) { edges { node { dbid } } } } }'
    post :create, query: query
    assert_response :success
    ids = []
    JSON.parse(@response.body)['data']['search']['medias']['edges'].each do |id|
      ids << id["node"]["dbid"]
    end
    assert_equal [pm2.id], ids
    create_comment text: 'title_a', annotated: pm1, disable_es_callbacks: false
    sleep 15
    query = 'query Search { search(query: "{\"keyword\":\"title_a\",\"sort\":\"recent_activity\",\"projects\":[' + p.id.to_s + ']}") { medias(first: 10) { edges { node { dbid, project_id } } } } }'
    post :create, query: query
    assert_response :success
    ids = []
    JSON.parse(@response.body)['data']['search']['medias']['edges'].each do |id|
      ids << id["node"]["dbid"]
    end
    assert_equal [pm1.id, pm2.id], ids.sort
  end

  test "should search media with multiple projects" do
    u = create_user
    p = create_project team: @team
    p2 = create_project team: @team
    authenticate_with_user(u)
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "title_a", "description":"search_desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m = create_media(account: create_valid_account, url: url)
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    pm2 = create_project_media project: p2, media: m,  disable_es_callbacks:  false
    sleep 10
    query = 'query Search { search(query: "{\"keyword\":\"title_a\",\"projects\":[' + p.id.to_s + ',' + p2.id.to_s + ']}") { medias(first: 10) { edges { node { dbid, project_id } } } } }'
    post :create, query: query
    assert_response :success
    p_ids = []
    m_ids = []
    JSON.parse(@response.body)['data']['search']['medias']['edges'].each do |id|
      m_ids << id["node"]["dbid"]
      p_ids << id["node"]["project_id"]
    end
    assert_equal [pm.id, pm2.id], m_ids.sort
    assert_equal [p.id, p2.id], p_ids.sort
    pm2.embed= {description: 'new_description'}.to_json
    sleep 10
    query = 'query Search { search(query: "{\"keyword\":\"title_a\",\"projects\":[' + p.id.to_s + ',' + p2.id.to_s + ']}") { medias(first: 10) { edges { node { dbid, project_id, embed } } } } }'
    post :create, query: query
    assert_response :success
    result = {}
    JSON.parse(@response.body)['data']['search']['medias']['edges'].each do |id|
      result[id["node"]["project_id"]] = JSON.parse(id["node"]["embed"])
    end
    assert_equal 'new_description', result[p2.id]["description"]
    assert_equal 'search_desc', result[p.id]["description"]
  end

  test "should return 404 if public team does not exist" do
    authenticate_with_user
    Team.stubs(:current).returns(nil)
    post :create, query: 'query PublicTeam { public_team { name } }', team: 'foo'
    assert_response 404
    Team.unstub(:current)
  end

  test "should run few queries to get project data" do
    n = 17 # Number of media items to be created
    m = 3 # Number of annotations per media
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

    assert_queries (5 * n + n * m + 16) do
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
    query = 'mutation create { createProjectMedia(input: { url: "", quote: "", clientMutationId: "1", project_id: ' + p.id.to_s + ' }) { project_media { id } } }'
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
    @request.headers['Accept-Language'] = 'es-LA'
    post :create, query: 'query Query { me { name } }'
    assert_equal :en, I18n.locale
  end

  test "should get closest language" do
    authenticate_with_user
    @request.headers['Accept-Language'] = 'es-LA, fr-FR'
    post :create, query: 'query Query { me { name } }'
    assert_equal :fr, I18n.locale
  end

  test "should search by dynamic annotation" do
    u = create_user
    p = create_project team: @team
    m1 = create_valid_media
    pm1 = create_project_media project: p, media: m1, disable_es_callbacks: false
    authenticate_with_user(u)
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "title_a", "description":"search_desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m2 = create_media(account: create_valid_account, url: url)
    pm2 = create_project_media project: p, media: m2, disable_es_callbacks: false

    at = create_annotation_type annotation_type: 'task_response_free_text', label: 'Task Response Free Text', description: 'Free text response that can added to a task'
    ft = create_field_type field_type: 'text_field', label: 'Text Field', description: 'A text field'
    fi1 = create_field_instance name: 'response', label: 'Response', description: 'The response to a task', field_type_object: ft, optional: false, settings: {}
    fi2 = create_field_instance name: 'note', label: 'Note', description: 'A note that explains a response to a task', field_type_object: ft, optional: true, settings: {}
    a = create_dynamic_annotation annotation_type: 'task_response_free_text', annotated: pm1, disable_es_callbacks: false
    f1 = create_field annotation_id: a.id, field_name: 'response', value: 'There is dynamic response here'
    f2 = create_field annotation_id: a.id, field_name: 'note', value: 'This is a dynamic note'
    a.save!
    sleep 15
    query = 'query Search { search(query: "{\"keyword\":\"dynamic response\",\"projects\":[' + p.id.to_s + ']}") { number_of_results, medias(first: 10) { edges { node { dbid } } } } }'
    post :create, query: query
    assert_response :success
    ids = []
    JSON.parse(@response.body)['data']['search']['medias']['edges'].each do |id|
      ids << id["node"]["dbid"]
    end
    assert_equal [pm1.id], ids
    query = 'query Search { search(query: "{\"keyword\":\"dynamic note\",\"projects\":[' + p.id.to_s + ']}") { number_of_results, medias(first: 10) { edges { node { dbid } } } } }'
    post :create, query: query
    assert_response :success
    ids = []
    JSON.parse(@response.body)['data']['search']['medias']['edges'].each do |id|
      ids << id["node"]["dbid"]
    end
    assert_equal [pm1.id], ids
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

  test "should read first response from task" do
    u = create_user
    p = create_project team: @team
    create_team_user user: u, team: @team
    m = create_valid_media
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    authenticate_with_user(u)
    t = create_task annotated: pm
    at = create_annotation_type annotation_type: 'response'
    ft1 = create_field_type field_type: 'task_reference'
    ft2 = create_field_type field_type: 'text'
    create_field_instance annotation_type_object: at, field_type_object: ft1, name: 'task'
    create_field_instance annotation_type_object: at, field_type_object: ft2, name: 'response'
    t.response = { annotation_type: 'response', set_fields: { response: 'Test', task: t.id.to_s }.to_json }.to_json
    t.save!
    query = "query { project_media(ids: \"#{pm.id},#{p.id}\") { tasks { edges { node { jsonoptions, first_response { content } } } } } }"
    post :create, query: query, team: @team.slug
    assert_response :success
    fields = JSON.parse(@response.body)['data']['project_media']['tasks']['edges'][0]['node']['first_response']['content']
    assert_equal 'Test', JSON.parse(fields).select{ |f| f['field_type'] == 'text' }.first['value']
  end

  test "should move report to other projects" do
    u = create_user
    p = create_project team: @team
    p2 = create_project team: @team
    create_team_user user: u, team: @team, role: 'owner'
    m = create_valid_media
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    authenticate_with_user(u)
    id = Base64.encode64("ProjectMedia/#{pm.id}")
    query = "mutation update { updateProjectMedia( input: { clientMutationId: \"1\", id: \"#{id}\", project_id: #{p2.id} }) { project_media { project_id }, project { id } } }"
    post :create, query: query, team: @team.slug
    assert_response :success
    assert_equal p2.id, JSON.parse(@response.body)['data']['updateProjectMedia']['project_media']['project_id']
    last_version = pm.versions.last
    assert_equal [p.id, p2.id], JSON.parse(last_version.object_changes)['project_id']
    assert_equal u.id.to_s, last_version.whodunnit
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
    data = JSON.parse(Annotation.last.content)
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

  test "should avoid n+1 queries problem" do
    n = 5 * (rand(10) + 1) # Number of media items to be created
    m = rand(10) + 1       # Number of annotations per media
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

    query = "query { search(query: \"{}\") { medias(first: 10000) { edges { node { dbid, media { dbid } } } } } }"

    # This number should be always CONSTANT regardless the number of medias and annotations above
    assert_queries (10) do
      post :create, query: query, team: 'team'
    end

    assert_response :success
  end

  test "should change password if token is found and passwords are present and match" do
    u = create_user provider: ''
    t = u.send_reset_password_instructions
    query = "mutation changePassword { changePassword(input: { clientMutationId: \"1\", reset_password_token: \"#{t}\", password: \"123456789\", password_confirmation: \"123456789\" }) { success } }"
    post :create, query: query
    sleep 1
    assert_response :success
    assert !JSON.parse(@response.body).has_key?('errors')
  end

  test "should not change password if token is not found and passwords are present and match" do
    u = create_user provider: ''
    t = u.send_reset_password_instructions
    query = "mutation changePassword { changePassword(input: { clientMutationId: \"1\", reset_password_token: \"#{t}x\", password: \"123456789\", password_confirmation: \"123456789\" }) { success } }"
    post :create, query: query
    sleep 1
    assert_response 400
  end

  test "should not change password if token is found but passwords are not present" do
    u = create_user provider: ''
    t = u.send_reset_password_instructions
    query = "mutation changePassword { changePassword(input: { clientMutationId: \"1\", reset_password_token: \"#{t}\", password: \"123456789\" }) { success } }"
    post :create, query: query
    sleep 1
    assert_response :success
    assert JSON.parse(@response.body).has_key?('errors')
  end

  test "should not change password if token is found but passwords do not match" do
    u = create_user provider: ''
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

  test "should get translation statuses" do
    t = create_team
    create_field_instance name: 'translation_status_status', settings: { statuses: [{ id: 'pending', label: 'Pending' }] }
    authenticate_with_user
    post :create, query: 'query { team { translation_statuses } }', team: t.slug
    assert_response :success
    statuses = JSON.parse(JSON.parse(@response.body)['data']['team']['translation_statuses'])
    assert_equal 'Pending', statuses['statuses'][0]['label']
  end

  test "should get field value and dynamic annotation(s)" do
    [DynamicAnnotation::FieldType, DynamicAnnotation::AnnotationType, DynamicAnnotation::FieldInstance].each { |klass| klass.delete_all }
    ft1 = create_field_type(field_type: 'select', label: 'Select')
    ft2 = create_field_type(field_type: 'text', label: 'Text')
    at = create_annotation_type annotation_type: 'translation_status', label: 'Translation Status'
    create_field_instance annotation_type_object: at, name: 'translation_status_status', label: 'Translation Status', field_type_object: ft1, optional: false, settings: { options_and_roles: { pending: 'contributor', in_progress: 'contributor', translated: 'contributor', ready: 'editor', error: 'editor' } }
    create_field_instance annotation_type_object: at, name: 'translation_status_note', label: 'Translation Status Note', field_type_object: ft2, optional: true

    authenticate_with_user
    p = create_project team: @team
    pm = create_project_media project: p
    a = create_dynamic_annotation annotation_type: 'translation_status', annotated: pm, set_fields: { translation_status_status: 'translated' }.to_json
    query = "query GetById { project_media(ids: \"#{pm.id},#{p.id}\") { annotation(annotation_type: \"translation_status\") { dbid }, field_value(annotation_type_field_name: \"translation_status:translation_status_status\"), annotations(annotation_type: \"translation_status\") { edges { node { dbid } } } } }"
    post :create, query: query, team: @team.slug
    assert_response :success
    data = JSON.parse(@response.body)['data']['project_media']
    assert_equal a.id, data['annotation']['dbid'].to_i
    assert_equal a.id, data['annotations']['edges'][0]['node']['dbid'].to_i
    assert_equal 'translated', data['field_value']
  end

  test "should create media with custom field" do
    authenticate_with_user
    create_annotation_type_and_fields('Syrian Archive Data', { 'Id' => ['Id', false] })
    p = create_project team: @team
    fields = '{\"annotation_type\":\"syrian_archive_data\",\"set_fields\":\"{\\\"syrian_archive_data_id\\\":\\\"123456\\\"}\"}'
    query = 'mutation create { createProjectMedia(input: { url: "", quote: "Test", clientMutationId: "1", set_annotation: "' + fields + '", project_id: ' + p.id.to_s + ' }) { project_media { id } } }'
    post :create, query: query, team: @team.slug
    assert_response :success
    assert_equal '123456', ProjectMedia.last.get_annotations('syrian_archive_data').last.load.get_field_value('syrian_archive_data_id')
  end

  test "should manage auto tasks of a team" do
    u = create_user
    t = create_team
    t.set_checklist([{ label: 'A', type: 'free_text', description: '', projects: [], options: '[]' }])
    t.save!
    id = NodeIdentification.to_global_id('Team', t.id)
    create_team_user user: u, team: t, role: 'owner'
    authenticate_with_user(u)
    assert_equal ['A'], t.get_checklist.collect{ |t| t[:label] }
    task = '{\"label\":\"B\",\"type\":\"free_text\",\"description\":\"\",\"projects\":[],\"options\":\"[]\"}'
    query = 'mutation { updateTeam(input: { clientMutationId: "1", id: "' + id + '", remove_auto_task: "A", add_auto_task: "' + task + '" }) { team { id } } }'
    post :create, query: query, team: t.slug
    assert_response :success
    assert_equal ['B'], t.reload.get_checklist.collect{ |t| t[:label] || t['label'] }
  end
end
