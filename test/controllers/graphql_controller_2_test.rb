require_relative '../test_helper'
require 'error_codes'

class GraphqlController2Test < ActionController::TestCase
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
  end

  test "should have a different id for public team" do
    authenticate_with_user
    t = create_team slug: 'team', name: 'Team'
    post :create, query: 'query PublicTeam { public_team { id, trash_count, pusher_channel } }', team: 'team'
    assert_response :success
    assert_equal Base64.encode64("PublicTeam/#{t.id}"), JSON.parse(@response.body)['data']['public_team']['id']
  end

  test "should search as anonymous user" do
    t = create_team slug: 'team', private: false
    p = create_project team: t
    2.times do
      pm = create_project_media project: p, disable_es_callbacks: false
    end
    sleep 2

    query = 'query CheckSearch { search(query: "{}") { id,medias(first:20){edges{node{id,dbid,url,quote,published,updated_at,metadata,log_count,verification_statuses,overridden,project_id,pusher_channel,domain,permissions,last_status,last_status_obj{id,dbid},project{id,dbid,title},project_source{dbid,id},media{url,quote,embed_path,thumbnail_path,id},user{name,source{dbid,accounts(first:10000){edges{node{url,id}}},id},id},team{slug,id},tags(first:10000){edges{node{tag,id}}}}}}}}'

    post :create, query: query, team: 'team'
    assert_response :success
    assert_equal 2, JSON.parse(@response.body)['data']['search']['medias']['edges'].size
  end

  test "should read attribution" do
    t, p, pm = assert_task_response_attribution
    u = create_user is_admin: true
    authenticate_with_user(u)
    query = "query GetById { project_media(ids: \"#{pm.id},#{p.id}\") { relationship { id }, tasks { edges { node { first_response { attribution { edges { node { name } } } } } } } } }"
    post :create, query: query, team: t.slug
    assert_response :success
    data = JSON.parse(@response.body)['data']['project_media']
    users = data['tasks']['edges'][0]['node']['first_response']['attribution']['edges'].collect{ |u| u['node']['name'] }
    assert_equal ['User 1', 'User 3'].sort, users.sort
  end

  test "should create team and return user and team_userEdge" do
    authenticate_with_user
    query = 'mutation create { createTeam(input: { clientMutationId: "1", name: "Test", slug: "' + random_string + '") { user { id }, team_userEdge } }'
    post :create, query: query
    assert_response :success
  end

  test "should return 409 on conflict" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'owner'
    s = create_source user: u, team: t
    s.name = 'Changed'
    s.save!
    assert_equal 1, s.reload.lock_version
    authenticate_with_user(u)
    query = 'mutation update { updateSource(input: { clientMutationId: "1", name: "Changed again", lock_version: 0, id: "' + s.reload.graphql_id + '"}) { source { id } } }'
    post :create, query: query, team: t.slug
    assert_response 409
  end

  test "should parse JSON exception" do
    PenderClient::Mock.mock_medias_returns_parsed_data(CONFIG['pender_url_private']) do
      WebMock.disable_net_connect! allow: [CONFIG['elasticsearch_host'].to_s + ':' + CONFIG['elasticsearch_port'].to_s, CONFIG['storage']['endpoint']]
      WebMock.stub_request(:get, CONFIG['pender_url_private'] + '/api/medias?url=https://www.youtube.com/user/MeedanTube').to_return(body: '{"type":"media","data":{"url":"' + @url + '/","type":"profile"}}')

      u = create_user
      t = create_team
      create_team_user user: u, team: t, role: 'owner'
      s = create_source user: u, team: t
      authenticate_with_user(u)

      query = 'mutation { createAccountSource(input: { clientMutationId: "1", source_id: ' + s.id.to_s + ', url: "' + @url + '"}) { source { id } } }'
      post :create, query: query, team: t.slug
      assert_response :success

      post :create, query: query, team: t.slug
      assert_response 400
      ret = JSON.parse(@response.body)
      assert_includes ret.keys, 'errors'
      error_info = ret['errors'].first
      assert_equal error_info.keys.sort, ['code', 'data', 'message'].sort
      assert_equal ::LapisConstants::ErrorCodes::DUPLICATED, error_info['code']
      assert_kind_of Integer, error_info['data']['project_id']
      assert_kind_of Integer, error_info['data']['id']
      assert_equal 'source', error_info['data']['type']
    end
  end

  test "should get user confirmed" do
    u = create_user
    authenticate_with_user(u)
    post :create, query: "query GetById { user(id: \"#{u.id}\") { confirmed  } }"
    assert_response :success
    data = JSON.parse(@response.body)['data']['user']
    assert data['confirmed']
  end

  test "should get project media assignments" do
    u = create_user
    u2 = create_user
    t = create_team
    create_team_user user: u, team: t, status: 'member'
    create_team_user user: u2, team: t, status: 'member'
    p = create_project team: t
    pm1 = create_project_media project: p
    pm2 = create_project_media project: p
    pm3 = create_project_media project: p
    pm4 = create_project_media project: p
    s1 = create_status status: 'in_progress', annotated: pm1
    s2 = create_status status: 'in_progress', annotated: pm2
    s3 = create_status status: 'in_progress', annotated: pm3
    s4 = create_status status: 'verified', annotated: pm4
    t1 = create_task annotated: pm1
    t2 = create_task annotated: pm3
    s1.assign_user(u.id)
    s2.assign_user(u.id)
    s3.assign_user(u.id)
    s4.assign_user(u2.id)
    authenticate_with_user(u)
    post :create, query: "query GetById { user(id: \"#{u.id}\") { assignments(first: 10) { edges { node { dbid, assignments(first: 10, user_id: #{u.id}, annotation_type: \"task\") { edges { node { dbid } } } } } } } }"
    assert_response :success
    data = JSON.parse(@response.body)['data']['user']
    assert_equal [pm3.id, pm2.id, pm1.id], data['assignments']['edges'].collect{ |x| x['node']['dbid'] }
    assert_equal [t2.id], data['assignments']['edges'][0]['node']['assignments']['edges'].collect{ |x| x['node']['dbid'].to_i }
    assert_equal [], data['assignments']['edges'][1]['node']['assignments']['edges']
    assert_equal [t1.id], data['assignments']['edges'][2]['node']['assignments']['edges'].collect{ |x| x['node']['dbid'].to_i }
  end

  test "should not get private team by slug" do
    authenticate_with_user
    create_team slug: 'team', name: 'Team', private: true
    post :create, query: 'query Team { team(slug: "team") { name, public_team { id } } }'
    assert_response 403
    assert_equal "Sorry, you can't read this team", JSON.parse(@response.body)['errors'][0]['message']
  end

  test "should start Apollo if not running" do
    File.stubs(:exist?).returns(true)
    File.stubs(:read).returns({ frontends: [{ port: 9999 }] }.to_json)
    post :create, query: 'query Query { about { name, version } }'
    File.unstub(:exist?)
    File.unstub(:read)
    assert_response 200
    assert_equal true, assigns(:started_apollo)
  end

  test "should not start Apollo if already running" do
    require 'socket'
    apollo = TCPServer.new 9999
    File.stubs(:exist?).returns(true)
    File.stubs(:read).returns({ frontends: [{ port: 9999 }] }.to_json)
    post :create, query: 'query Query { about { name, version } }'
    File.unstub(:exist?)
    File.unstub(:read)
    apollo.close
    assert_response 200
    assert_equal false, assigns(:started_apollo)
  end

  test "should get team with arabic slug" do
    authenticate_with_user
    t = create_team slug: 'المصالحة', name: 'Arabic Team'
    post :create, query: 'query Query { about { name, version } }', team: '%D8%A7%D9%84%D9%85%D8%B5%D8%A7%D9%84%D8%AD%D8%A9'
    assert_response :success
    assert_equal t, assigns(:context_team)
  end

  test "should not create duplicated tag" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'owner'
    authenticate_with_user(u)
    p = create_project team: t
    pm = create_project_media project: p
    query = 'mutation create { createTag(input: { clientMutationId: "1", tag: "egypt", annotated_type: "ProjectMedia", annotated_id: "' + pm.id.to_s + '"}) { tag { id } } }'
    post :create, query: query
    assert_response :success
    post :create, query: query
    assert_response 400
    assert_match /Tag already exists/, @response.body
  end

  test "should not change status if contributor" do
    create_verification_status_stuff
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'contributor'
    create_team_user team: create_team, user: u, role: 'owner'
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m
    s = pm.last_verification_status_obj
    s = Dynamic.find(s.id)
    f = s.get_field('verification_status_status')
    assert_equal 'undetermined', f.reload.value
    authenticate_with_user(u)

    id = Base64.encode64("Dynamic/#{s.id}")
    query = 'mutation update { updateDynamic(input: { clientMutationId: "1", id: "' + id + '", set_fields: "{\"verification_status_status\":\"verified\"}" }) { project_media { id } } }'
    post :create, query: query, team: t.slug
    assert_match /No permission to update Dynamic/, @response.body
    assert_equal 'undetermined', f.reload.value
    assert_response 400
  end

  test "should not assign status if contributor" do
    create_verification_status_stuff
    u = create_user
    u2 = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'contributor'
    create_team_user team: t, user: u2, role: 'contributor'
    create_team_user team: create_team, user: u, role: 'owner'
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m
    s = pm.last_verification_status_obj
    s = Dynamic.find(s.id)
    f = s.get_field('verification_status_status')
    assert_equal 'undetermined', f.reload.value
    authenticate_with_user(u)

    id = Base64.encode64("Dynamic/#{s.id}")
    query = 'mutation update { updateDynamic(input: { clientMutationId: "1", id: "' + id + '", assigned_to_ids: "' + u2.id.to_s + '" }) { project_media { id } } }'
    post :create, query: query, team: t.slug
    assert_match /No permission to update Dynamic/, @response.body
    assert_equal 'undetermined', f.reload.value
    assert_response 400
  end

  test "should return relationship information" do
    t = create_team
    p = create_project team: t
    p2 = create_project team: t
    pm = create_project_media project: p
    pm2 = create_project_media project: p
    s1 = create_project_media project: p2
    r = create_relationship source_id: s1.id, target_id: pm.id, relationship_type: { source: 'parent', target: 'child' }
    create_relationship source_id: s1.id, relationship_type: { source: 'parent', target: 'child' }, target_id: create_project_media(project: p2).id
    create_relationship source_id: s1.id, relationship_type: { source: 'related', target: 'related' }, target_id: create_project_media(project: p2).id
    create_relationship source_id: s1.id, relationship_type: { source: 'related', target: 'related' }, target_id: create_project_media(project: p2).id
    s2 = create_project_media project: p2
    create_relationship source_id: s2.id, target_id: pm2.id, relationship_type: { source: 'duplicates', target: 'duplicate_of' }
    create_relationship source_id: s2.id, relationship_type: { source: 'duplicates', target: 'duplicate_of' }, target_id: create_project_media(project: p2).id
    create_relationship source_id: s2.id, relationship_type: { source: 'duplicates', target: 'duplicate_of' }, target_id: create_project_media(project: p2).id
    create_relationship source_id: s2.id, relationship_type: { source: 'duplicates', target: 'duplicate_of' }, target_id: create_project_media(project: p2).id
    3.times { create_relationship(relationship_type: { source: 'duplicates', target: 'duplicate_of' }) }
    2.times { create_relationship(relationship_type: { source: 'parent', target: 'child' }) }
    1.times { create_relationship(relationship_type: { source: 'related', target: 'related' }) }
    authenticate_with_user

    query = "query GetById { project_media(ids: \"#{pm.id},#{p.id}\") { relationships { id, targets_count, targets { edges { node { id, type, targets { edges { node { dbid } } } } } }, sources { edges { node { id, relationship_id, type, siblings { edges { node { dbid } } }, source { dbid } } } } } } }"
    post :create, query: query, team: t.slug

    assert_response :success
    data = JSON.parse(@response.body)['data']['project_media']['relationships']
    assert_equal 0, data['targets_count']
    sources = data['sources']['edges'].sort_by{ |x| x['node']['relationship_id'] }.collect{ |x| x['node'] }
    targets = data['targets']['edges'].sort_by{ |x| x['node']['type'] }.collect{ |x| x['node'] }

    assert_equal s1.id, sources[0]['source']['dbid']
    assert_equal({ source: 'parent', target: 'child' }.to_json, sources[0]['type'])
    assert_equal 2, sources[0]['siblings']['edges'].size

    assert_equal Base64.encode64("Relationships/#{pm.id}"), data['id']
    assert_equal Base64.encode64("RelationshipsSource/#{r.source_id}/#{{ source: 'parent', target: 'child' }.to_json}"), sources[0]['id']
  end

  test "should get relationship from global id" do
    authenticate_with_user
    pm = create_project_media
    id = Base64.encode64("Relationships/#{pm.id}")
    id2 = Base64.encode64("ProjectMedia/#{pm.id}")
    post :create, query: "query Query { node(id: \"#{id}\") { id } }"
    assert_equal id2, JSON.parse(@response.body)['data']['node']['id']
  end

  test "should create related report" do
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p
    u = create_user
    create_team_user user: u, team: t, role: 'contributor'
    authenticate_with_user(u)
    query = 'mutation create { createProjectMedia(input: { url: "", quote: "X", media_type: "Claim", clientMutationId: "1", project_id: ' + p.id.to_s + ', related_to_id: ' + pm.id.to_s + ' }) { check_search_team { number_of_results }, project_media { id } } }'
    assert_difference 'Relationship.count' do
      post :create, query: query, team: t
    end
    assert_response :success
  end

  test "should return permissions of sibling report" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'owner'
    p = create_project team: t
    pm = create_project_media project: p
    pm1 = create_project_media project: p, user: u
    create_relationship source_id: pm.id, target_id: pm1.id
    pm1.archived = true
    pm1.save!

    authenticate_with_user(u)

    query = "query GetById { project_media(ids: \"#{pm1.id},#{p.id}\") {permissions,relationships{sources{edges{node{siblings{edges{node{permissions}}},source{permissions}}}}}}}"
    post :create, query: query, team: t.slug

    assert_response :success
    data = JSON.parse(@response.body)['data']['project_media']

    assert_equal data['permissions'], data['relationships']['sources']['edges'][0]['node']['siblings']['edges'][0]['node']['permissions']
    assert_not_equal data['relationships']['sources']['edges'][0]['node']['siblings']['edges'][0]['node']['permissions'], data['relationships']['sources']['edges'][0]['node']['source']['permissions']
    assert_not_equal data['permissions'], data['relationships']['sources']['edges'][0]['node']['source']['permissions']
  end

  test "should create dynamic annotation type" do
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p
    u = create_user
    create_team_user user: u, team: t, role: 'owner'
    authenticate_with_user(u)

    query = 'mutation create { createDynamicAnnotationMetadata(input: { annotated_id: "' + pm.id.to_s + '", clientMutationId: "1", annotated_type: "ProjectMedia", set_fields: "{\"metadata_value\":\"test\"}" }) { dynamic { id, annotation_type } } }'

    assert_difference 'Dynamic.count' do
      post :create, query: query, team: t
    end
    assert_equal 'metadata', JSON.parse(@response.body)['data']['createDynamicAnnotationMetadata']['dynamic']['annotation_type']
    assert_response :success
  end

  test "should read project media dynamic annotation fields" do
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p
    u = create_user
    create_team_user user: u, team: t, role: 'owner'
    authenticate_with_user(u)
    d = create_dynamic_annotation annotated: pm, annotation_type: 'metadata'

    query = "query GetById { project_media(ids: \"#{pm.id},#{p.id}\") { dynamic_annotation_metadata { dbid }, dynamic_annotations_metadata { edges { node { dbid } } } } }"
    post :create, query: query, team: t.slug

    assert_response :success
    data = JSON.parse(@response.body)['data']['project_media']
    assert_equal d.id.to_s, data['dynamic_annotation_metadata']['dbid']
    assert_equal d.id.to_s, data['dynamic_annotations_metadata']['edges'][0]['node']['dbid']
  end

  test "should return nil on team_userEdge if user is admin and not a team member" do
    u = create_user
    u.is_admin = true; u.save
    authenticate_with_user(u)
    t = create_team name: 'foo'
    User.current = u

    assert_nil GraphqlCrudOperations.define_conditional_returns(t)[:team_userEdge]

    tu = create_team_user user: u, team: t
    assert_equal tu, GraphqlCrudOperations.define_conditional_returns(t)[:team_userEdge].node

    User.current = nil
  end

  test "should get approved bots" do
    BotUser.delete_all
    authenticate_with_user
    tb1 = create_team_bot set_approved: true
    tb2 = create_team_bot set_approved: false
    query = "query read { root { team_bots_approved { edges { node { dbid } } } } }"
    post :create, query: query
    edges = JSON.parse(@response.body)['data']['root']['team_bots_approved']['edges']
    assert_equal [tb1.id], edges.collect{ |e| e['node']['dbid'] }
  end

  test "should get bot by id" do
    authenticate_with_user
    tb = create_team_bot set_approved: true, name: 'My Bot'
    query = "query read { bot_user(id: #{tb.id}) { name } }"
    post :create, query: query
    assert_response :success
    name = JSON.parse(@response.body)['data']['bot_user']['name']
    assert_equal 'My Bot', name
  end

  test "should get bots installed in a team" do
    t = create_team slug: 'test'
    u = create_user
    create_team_user user: u, team: t, role: 'owner'
    authenticate_with_user(u)

    tb1 = create_team_bot set_approved: false, name: 'Custom Bot', team_author_id: t.id
    tb2 = create_team_bot set_approved: true, name: 'My Bot'
    tb3 = create_team_bot set_approved: true, name: 'Other Bot'
    create_team_bot_installation user_id: tb2.id, team_id: t.id

    query = 'query read { team(slug: "test") { team_bots { edges { node { name, team_author { slug } } } } } }'
    post :create, query: query
    assert_response :success
    edges = JSON.parse(@response.body)['data']['team']['team_bots']['edges']
    assert_equal ['Custom Bot', 'My Bot'], edges.collect{ |e| e['node']['name'] }.sort
    assert edges[0]['node']['team_author']['slug'] == 'test' || edges[1]['node']['team_author']['slug'] == 'test'
  end

  test "should get bot installations in a team" do
    t = create_team slug: 'test'
    u = create_user
    create_team_user user: u, team: t, role: 'owner'
    authenticate_with_user(u)

    tb1 = create_team_bot set_approved: false, name: 'Custom Bot', team_author_id: t.id
    tb2 = create_team_bot set_approved: true, name: 'My Bot'
    tb3 = create_team_bot set_approved: true, name: 'Other Bot'
    create_team_bot_installation user_id: tb2.id, team_id: t.id

    query = 'query read { team(slug: "test") { team_bot_installations { edges { node { team { slug, public_team { id } }, bot_user { name } } } } } }'
    post :create, query: query
    assert_response :success
    edges = JSON.parse(@response.body)['data']['team']['team_bot_installations']['edges']
    assert_equal ['Custom Bot', 'My Bot'], edges.collect{ |e| e['node']['bot_user']['name'] }.sort
    assert_equal ['test', 'test'], edges.collect{ |e| e['node']['team']['slug'] }
  end

  test "should install bot using mutation" do
    t = create_team slug: 'test'
    u = create_user
    create_team_user user: u, team: t, role: 'owner'
    tb = create_team_bot set_approved: true

    authenticate_with_user(u)

    assert_equal [], t.team_bots

    query = 'mutation create { createTeamBotInstallation(input: { clientMutationId: "1", user_id: ' + tb.id.to_s + ', team_id: ' + t.id.to_s + ' }) { team { dbid }, bot_user { dbid } } }'
    assert_difference 'TeamBotInstallation.count' do
      post :create, query: query
    end
    data = JSON.parse(@response.body)['data']['createTeamBotInstallation']

    assert_equal [tb], t.reload.team_bots
    assert_equal t.id, data['team']['dbid']
    assert_equal tb.id, data['bot_user']['dbid']
  end

  test "should uninstall bot using mutation" do
    t = create_team slug: 'test'
    u = create_user
    create_team_user user: u, team: t, role: 'owner'
    tb = create_team_bot set_approved: true
    tbi = create_team_bot_installation team_id: t.id, user_id: tb.id

    authenticate_with_user(u)

    assert_equal [tb], t.reload.team_bots

    query = 'mutation delete { destroyTeamBotInstallation(input: { clientMutationId: "1", id: "' + tbi.graphql_id + '" }) { deletedId } }'
    assert_difference 'TeamBotInstallation.count', -1 do
      post :create, query: query
    end
    data = JSON.parse(@response.body)['data']['destroyTeamBotInstallation']

    assert_equal [], t.reload.team_bots
    assert_equal tbi.graphql_id, data['deletedId']
  end

  test "should get task by id" do
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p
    u = create_user
    create_team_user user: u, team: t, role: 'owner'
    authenticate_with_user(u)
    tk = create_task annotated: pm
    c = nil
    with_current_user_and_team(u, t) do
      c = create_comment annotated: tk
    end

    query = "query GetById { task(id: \"#{tk.id}\") { project_media { id }, log_count, options, log { edges { node { annotation { dbid } } } }, responses { edges { node { id } } } } }"
    post :create, query: query, team: t.slug

    assert_response :success
    data = JSON.parse(@response.body)['data']['task']
    assert_equal 1, data['log_count']
    assert_kind_of Array, data['options']
    assert_equal c.id.to_s, data['log']['edges'][0]['node']['annotation']['dbid']
  end

  test "should get team custom tags and teamwide tags" do
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p
    u = create_user
    create_team_user user: u, team: t, role: 'owner'
    authenticate_with_user(u)
    create_tag_text text: 'foo', team_id: t.id, teamwide: true
    create_tag_text text: 'bar', team_id: t.id, teamwide: false

    query = "query GetById { team(id: \"#{t.id}\") { custom_tags { edges { node { text } } }, teamwide_tags { edges { node { text } } } } }"
    post :create, query: query, team: t.slug

    assert_response :success
    data = JSON.parse(@response.body)['data']['team']
    assert_equal 'foo', data['teamwide_tags']['edges'][0]['node']['text']
    assert_equal 'bar', data['custom_tags']['edges'][0]['node']['text']
  end

  test "should get team tasks" do
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p
    u = create_user
    create_team_user user: u, team: t, role: 'owner'
    authenticate_with_user(u)
    create_team_task team_id: t.id, label: 'Foo'

    query = "query GetById { team(id: \"#{t.id}\") { team_tasks { edges { node { label, dbid, type, description, options, project_ids, required, team_id, team { slug } } } } } }"
    post :create, query: query, team: t.slug

    assert_response :success
    data = JSON.parse(@response.body)['data']['team']
    assert_equal 'Foo', data['team_tasks']['edges'][0]['node']['label']
  end

  test "should not import spreadsheet if URL is not present" do
    t = create_team
    u = create_user
    create_team_user user: u, team: t, role: 'owner'

    authenticate_with_user(u)

    query = "mutation importSpreadsheet { importSpreadsheet(input: { clientMutationId: \"1\", team_id: #{t.id}, user_id: #{u.id} }) { success } }"
    post :create, query: query, team: t.slug
    sleep 1
    assert_response :success
    response = JSON.parse(@response.body)
    assert response.has_key?('errors')
    assert_match /invalid value/, response['errors'].first['message']
  end

  test "should not import spreadsheet if team_id is not present" do
    t = create_team
    u = create_user
    create_team_user user: u, team: t, role: 'owner'

    authenticate_with_user(u)

    spreadsheet_url = "https://docs.google.com/spreadsheets/d/1lyxWWe9rRJPZejkCpIqVrK54WUV2UJl9sR75W5_Z9jo/edit#gid=0"
    query = "mutation importSpreadsheet { importSpreadsheet(input: { clientMutationId: \"1\", spreadsheet_url: \"#{spreadsheet_url}\", user_id: #{u.id} }) { success } }"
    post :create, query: query, team: t.slug
    sleep 1
    assert_response :success
    response = JSON.parse(@response.body)
    assert response.has_key?('errors')
    assert_match /invalid value/, response['errors'].first['message']
  end

  test "should not import spreadsheet if user_id is not present" do
    t = create_team
    u = create_user
    create_team_user user: u, team: t, role: 'owner'

    authenticate_with_user(u)

    spreadsheet_url = "https://docs.google.com/spreadsheets/d/1lyxWWe9rRJPZejkCpIqVrK54WUV2UJl9sR75W5_Z9jo/edit#gid=0"
    query = "mutation importSpreadsheet { importSpreadsheet(input: { clientMutationId: \"1\", spreadsheet_url: \"#{spreadsheet_url}\", team_id: #{t.id} }) { success } }"
    post :create, query: query, team: t.slug
    sleep 1
    assert_response :success
    response = JSON.parse(@response.body)
    assert response.has_key?('errors')
    assert_match /invalid value/, response['errors'].first['message']
  end

  test "should not import spreadsheet if URL is invalid" do
    t = create_team
    u = create_user
    create_team_user user: u, team: t, role: 'owner'

    authenticate_with_user(u)

    [' ', 'https://example.com'].each do |url|
      query = "mutation importSpreadsheet { importSpreadsheet(input: { clientMutationId: \"1\", spreadsheet_url: \"#{url}\", team_id: #{t.id}, user_id: #{u.id} }) { success } }"
      post :create, query: query, team: t.slug
      sleep 1
      assert_response 400
      response = JSON.parse(@response.body)
      assert_includes response.keys, 'errors'
      error_info = response['errors'].first
      assert_equal 'INVALID_VALUE', error_info['code']
    end
  end

  test "should not import spreadsheet if id not found" do
    t = create_team
    u = create_user
    create_team_user user: u, team: t, role: 'owner'

    authenticate_with_user(u)
    spreadsheet_url = "https://docs.google.com/spreadsheets/d/invalid_spreadsheet/edit#gid=0"
    query = "mutation importSpreadsheet { importSpreadsheet(input: { clientMutationId: \"1\", spreadsheet_url: \"#{spreadsheet_url}\", team_id: #{t.id}, user_id: #{u.id} }) { success } }"

    post :create, query: query, team: t.slug
    assert_response 400
    response = JSON.parse(@response.body)
    error_info = response['errors'].first
    assert_equal 'INVALID_VALUE', error_info['code']
    assert_match /File not found/, error_info['data']['error_message']
  end

  test "should import spreadsheet if inputs are valid" do
    t = create_team
    u = create_user
    create_team_user user: u, team: t, role: 'owner'

    authenticate_with_user(u)
    spreadsheet_url = "https://docs.google.com/spreadsheets/d/1lyxWWe9rRJPZejkCpIqVrK54WUV2UJl9sR75W5_Z9jo/edit#gid=0"
    query = "mutation importSpreadsheet { importSpreadsheet(input: { clientMutationId: \"1\", spreadsheet_url: \"#{spreadsheet_url}\", team_id: #{t.id}, user_id: #{u.id} }) { success } }"
    post :create, query: query, team: t.slug
    assert_response :success
    assert_equal({"success" => true}, JSON.parse(@response.body)['data']['importSpreadsheet'])
  end

  test "should not read project media user if annotator" do
    u = create_user
    u2 = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'annotator'
    create_team_user user: u2, team: t
    authenticate_with_user(u)
    p = create_project team: t
    pm = create_project_media project: p, user: u2
    t = create_task annotated: pm
    t.assign_user(u.id)
    query = "query GetById { project_media(ids: \"#{pm.id},#{p.id}\") { user { id } } }"
    post :create, query: query, team: t.slug
    assert_response :success
    assert_nil JSON.parse(@response.body)['data']['project_media']['user']
  end

  test "should read project media user if not annotator" do
    u = create_user
    u2 = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'contributor'
    create_team_user user: u2, team: t
    authenticate_with_user(u)
    p = create_project team: t
    pm = create_project_media project: p, user: u2
    t = create_task annotated: pm
    t.assign_user(u.id)
    query = "query GetById { project_media(ids: \"#{pm.id},#{p.id}\") { user { id } } }"
    post :create, query: query, team: t.slug
    assert_response :success
    assert_not_nil JSON.parse(@response.body)['data']['project_media']['user']
  end

  test "should list filtered users to annotator" do
    u1 = create_user name: 'Annotator'
    u2 = create_user name: 'Owner'
    t = create_team
    create_team_user user: u1, team: t, role: 'annotator'
    create_team_user user: u2, team: t, role: 'owner'

    authenticate_with_user(u1)
    post :create, query: 'query Team { team { team_users { edges { node { user { name } } } } } }', team: t.slug
    list = JSON.parse(@response.body)['data']['team']['team_users']['edges']
    assert_equal 1, list.size
    assert_equal 'Annotator', list[0]['node']['user']['name']
  end

  test "should list all users to non-annotators" do
    u1 = create_user name: 'Annotator'
    u2 = create_user name: 'Owner'
    t = create_team
    create_team_user user: u1, team: t, role: 'annotator'
    create_team_user user: u2, team: t, role: 'owner'

    authenticate_with_user(u2)
    post :create, query: 'query Team { team { team_users { edges { node { user { name } } } } } }', team: t.slug
    list = JSON.parse(@response.body)['data']['team']['team_users']['edges']
    assert_equal 2, list.size
  end

  test "should list filtered log to annotator" do
    u1 = create_user name: 'Annotator'
    u2 = create_user name: 'Owner'
    t = create_team
    create_team_user user: u1, team: t, role: 'annotator'
    create_team_user user: u2, team: t, role: 'owner'
    p = create_project team: t
    pm = create_project_media project: p
    tk = create_task annotated: pm
    tk.assign_user(u1.id)
    with_current_user_and_team(u1, t) { create_comment(annotated: pm, annotator: u1) }
    with_current_user_and_team(u2, t) { create_comment(annotated: pm, annotator: u2) }

    authenticate_with_user(u1)
    query = "query { project_media(ids: \"#{pm.id},#{p.id}\") { log(first: 1000) { edges { node { id } } } } }"
    post :create, query: query, team: t.slug
    list = JSON.parse(@response.body)['data']['project_media']['log']['edges']
    assert_equal 1, list.size
  end

  test "should list whole log to non-annotator" do
    u1 = create_user name: 'Annotator'
    u2 = create_user name: 'Owner'
    t = create_team
    create_team_user user: u1, team: t, role: 'annotator'
    create_team_user user: u2, team: t, role: 'owner'
    p = create_project team: t
    pm = create_project_media project: p
    tk = create_task annotated: pm
    tk.assign_user(u1.id)
    with_current_user_and_team(u1, t) { create_comment(annotated: pm, annotator: u1) }
    with_current_user_and_team(u2, t) { create_comment(annotated: pm, annotator: u2) }

    authenticate_with_user(u2)
    query = "query { project_media(ids: \"#{pm.id},#{p.id}\") { log(first: 1000) { edges { node { id } } } } }"
    post :create, query: query, team: t.slug
    list = JSON.parse(@response.body)['data']['project_media']['log']['edges']
    assert_equal 2, list.size
  end

  test "should list filtered task assignees to annotator" do
    u1 = create_user name: 'Annotator'
    u2 = create_user name: 'Owner'
    t = create_team
    create_team_user user: u1, team: t, role: 'annotator'
    create_team_user user: u2, team: t, role: 'owner'
    p = create_project team: t
    pm = create_project_media project: p
    tk = create_task annotated: pm
    tk.assign_user(u1.id)
    tk.assign_user(u2.id)

    authenticate_with_user(u1)
    query = "query GetById { task(id: \"#{tk.id}\") { assignments { edges { node { name } } } } }"
    post :create, query: query, team: t.slug
    list = JSON.parse(@response.body)['data']['task']['assignments']['edges']
    assert_equal 1, list.size
    assert_equal 'Annotator', list[0]['node']['name']
  end

  test "should list all task assignees to non-annotator" do
    u1 = create_user name: 'Annotator'
    u2 = create_user name: 'Owner'
    t = create_team
    create_team_user user: u1, team: t, role: 'annotator'
    create_team_user user: u2, team: t, role: 'owner'
    p = create_project team: t
    pm = create_project_media project: p
    tk = create_task annotated: pm
    tk.assign_user(u1.id)
    tk.assign_user(u2.id)

    authenticate_with_user(u2)
    query = "query GetById { task(id: \"#{tk.id}\") { assignments { edges { node { name } } } } }"
    post :create, query: query, team: t.slug
    list = JSON.parse(@response.body)['data']['task']['assignments']['edges']
    assert_equal 2, list.size
  end

  test "should show assigned task to annotator" do
    u1 = create_user name: 'Annotator'
    u2 = create_user name: 'Owner'
    t = create_team
    create_team_user user: u1, team: t, role: 'annotator'
    create_team_user user: u2, team: t, role: 'owner'
    p = create_project team: t
    pm = create_project_media project: p
    tk1 = create_task annotated: pm
    tk1.assign_user(u1.id)
    tk2 = create_task annotated: pm
    tk2.assign_user(u2.id)

    authenticate_with_user(u1)
    query = "query GetById { task(id: \"#{tk1.id}\") { id } }"
    post :create, query: query, team: t.slug
    assert_response :success
    query = "query GetById { task(id: \"#{tk2.id}\") { id } }"
    post :create, query: query, team: t.slug
    assert_response 403
  end

  test "should show any task to non-annotator" do
    u1 = create_user name: 'Annotator'
    u2 = create_user name: 'Owner'
    t = create_team
    create_team_user user: u1, team: t, role: 'annotator'
    create_team_user user: u2, team: t, role: 'owner'
    p = create_project team: t
    pm = create_project_media project: p
    tk1 = create_task annotated: pm
    tk1.assign_user(u1.id)
    tk2 = create_task annotated: pm
    tk2.assign_user(u2.id)

    authenticate_with_user(u2)
    query = "query GetById { task(id: \"#{tk1.id}\") { id } }"
    post :create, query: query, team: t.slug
    assert_response :success
    query = "query GetById { task(id: \"#{tk2.id}\") { id } }"
    post :create, query: query, team: t.slug
    assert_response :success
  end

  test "should list filtered tasks to annotator" do
    u1 = create_user name: 'Annotator'
    u2 = create_user name: 'Owner'
    t = create_team
    create_team_user user: u1, team: t, role: 'annotator'
    create_team_user user: u2, team: t, role: 'owner'
    p = create_project team: t
    pm = create_project_media project: p
    tk1 = create_task annotated: pm
    tk1.assign_user(u1.id)
    tk2 = create_task annotated: pm
    tk2.assign_user(u2.id)

    authenticate_with_user(u1)
    query = "query { project_media(ids: \"#{pm.id},#{p.id}\") { tasks(first: 1000) { edges { node { dbid } } } } }"
    post :create, query: query, team: t.slug
    list = JSON.parse(@response.body)['data']['project_media']['tasks']['edges']
    assert_equal 1, list.size
    assert_equal tk1.id, list[0]['node']['dbid'].to_i
  end

  test "should list all tasks to non-annotator" do
    u1 = create_user name: 'Annotator'
    u2 = create_user name: 'Owner'
    t = create_team
    create_team_user user: u1, team: t, role: 'annotator'
    create_team_user user: u2, team: t, role: 'owner'
    p = create_project team: t
    pm = create_project_media project: p
    tk1 = create_task annotated: pm
    tk1.assign_user(u1.id)
    tk2 = create_task annotated: pm
    tk2.assign_user(u2.id)

    authenticate_with_user(u2)
    query = "query { project_media(ids: \"#{pm.id},#{p.id}\") { tasks(first: 1000) { edges { node { dbid } } } } }"
    post :create, query: query, team: t.slug
    list = JSON.parse(@response.body)['data']['project_media']['tasks']['edges']
    assert_equal 2, list.size
  end

  test "should list filtered projects to annotator" do
    u1 = create_user name: 'Annotator'
    u2 = create_user name: 'Owner'
    t = create_team
    create_team_user user: u1, team: t, role: 'annotator'
    create_team_user user: u2, team: t, role: 'owner'
    p1 = create_project team: t, title: 'Annotator Project'
    p2 = create_project team: t
    pm = create_project_media project: p1
    tk = create_task annotated: pm
    tk.assign_user(u1.id)

    authenticate_with_user(u1)
    post :create, query: 'query Team { team { projects { edges { node { title } } } } }', team: t.slug
    list = JSON.parse(@response.body)['data']['team']['projects']['edges']
    assert_equal 1, list.size
    assert_equal 'Annotator Project', list[0]['node']['title']
  end

  test "should list all projects to non-annotator" do
    u1 = create_user name: 'Annotator'
    u2 = create_user name: 'Owner'
    t = create_team
    create_team_user user: u1, team: t, role: 'annotator'
    create_team_user user: u2, team: t, role: 'owner'
    p1 = create_project team: t, title: 'Annotator Project'
    p2 = create_project team: t
    pm = create_project_media project: p1
    tk = create_task annotated: pm
    tk.assign_user(u1.id)

    authenticate_with_user(u2)
    post :create, query: 'query Team { team { projects { edges { node { title } } } } }', team: t.slug
    list = JSON.parse(@response.body)['data']['team']['projects']['edges']
    assert_equal 2, list.size
  end

  test "should list filtered medias to annotator" do
    u1 = create_user name: 'Annotator'
    u2 = create_user name: 'Owner'
    t = create_team
    create_team_user user: u1, team: t, role: 'annotator'
    create_team_user user: u2, team: t, role: 'owner'
    p = create_project team: t
    pm1 = create_project_media project: p
    pm2 = create_project_media project: p
    tk = create_task annotated: pm1
    tk.assign_user(u1.id)

    authenticate_with_user(u1)
    post :create, query: "query { project(ids: \"#{p.id},#{t.id}\") { project_medias { edges { node { dbid } } } } }", team: t.slug
    list = JSON.parse(@response.body)['data']['project']['project_medias']['edges']
    assert_equal 1, list.size
    assert_equal pm1.id, list[0]['node']['dbid'].to_i
  end

  test "should list all medias to non-annotator" do
    u1 = create_user name: 'Annotator'
    u2 = create_user name: 'Owner'
    t = create_team
    create_team_user user: u1, team: t, role: 'annotator'
    create_team_user user: u2, team: t, role: 'owner'
    p = create_project team: t
    pm1 = create_project_media project: p
    pm2 = create_project_media project: p
    tk = create_task annotated: pm1
    tk.assign_user(u1.id)

    authenticate_with_user(u2)
    post :create, query: "query { project(ids: \"#{p.id},#{t.id}\") { project_medias { edges { node { dbid } } } } }", team: t.slug
    list = JSON.parse(@response.body)['data']['project']['project_medias']['edges']
    assert_equal 2, list.size
  end

  test "should list filtered annotations to annotator" do
    u1 = create_user name: 'Annotator'
    u2 = create_user name: 'Owner'
    t = create_team
    create_team_user user: u1, team: t, role: 'annotator'
    create_team_user user: u2, team: t, role: 'owner'
    p = create_project team: t
    pm = create_project_media project: p
    tk = create_task annotated: pm
    tk.assign_user(u1.id)
    d1 = create_dynamic_annotation annotation_type: 'metadata', annotated: pm, annotator: u1
    d2 = create_dynamic_annotation annotation_type: 'metadata', annotated: pm, annotator: u2

    authenticate_with_user(u1)
    query = "query { project_media(ids: \"#{pm.id},#{p.id}\") { dynamic_annotations_metadata(first: 1000) { edges { node { dbid } } } } }"
    post :create, query: query, team: t.slug
    list = JSON.parse(@response.body)['data']['project_media']['dynamic_annotations_metadata']['edges']
    assert_equal 1, list.size
    assert_equal d1.id, list[0]['node']['dbid'].to_i
  end

  test "should list all annotations to non-annotator" do
    u1 = create_user name: 'Annotator'
    u2 = create_user name: 'Owner'
    t = create_team
    create_team_user user: u1, team: t, role: 'annotator'
    create_team_user user: u2, team: t, role: 'owner'
    p = create_project team: t
    pm = create_project_media project: p
    tk = create_task annotated: pm
    tk.assign_user(u1.id)
    d1 = create_dynamic_annotation annotation_type: 'metadata', annotated: pm, annotator: u1
    d2 = create_dynamic_annotation annotation_type: 'metadata', annotated: pm, annotator: u2

    authenticate_with_user(u2)
    query = "query { project_media(ids: \"#{pm.id},#{p.id}\") { dynamic_annotations_metadata(first: 1000) { edges { node { dbid } } } } }"
    post :create, query: query, team: t.slug
    list = JSON.parse(@response.body)['data']['project_media']['dynamic_annotations_metadata']['edges']
    assert_equal 2, list.size
  end

  test "should get project assignments" do
    u = create_user is_admin: true
    u2 = create_user name: 'Assigned to Project'
    t = create_team
    create_team_user user: u2, team: t
    p = create_project team: t
    p.assign_user(u2.id)
    authenticate_with_user(u)

    post :create, query: "query { project(ids: \"#{p.id},#{t.id}\") { assignments_count, assigned_users(first: 10000) { edges { node { name } } } } }", team: t.slug
    data = JSON.parse(@response.body)['data']['project']
    assert_equal 1, data['assignments_count']
    assert_equal 'Assigned to Project', data['assigned_users']['edges'][0]['node']['name']
  end

  test "should filter user assignments by team" do
    u = create_user
    t1 = create_team
    create_team_user team: t1, user: u
    p1 = create_project team: t1
    pm1 = create_project_media project: p1
    tk1 = create_task annotated: pm1
    tk1.assign_user(u.id)
    t2 = create_team
    create_team_user team: t2, user: u
    p2 = create_project team: t2
    pm2 = create_project_media project: p2
    tk2 = create_task annotated: pm2
    tk2.assign_user(u.id)
    authenticate_with_user(u)

    post :create, query: "query { me { assignments(first: 10000) { edges { node { dbid } } } } }", team: t1.slug
    assert_response :success
    data = JSON.parse(@response.body)['data']['me']['assignments']['edges']
    assert_equal 2, data.size

    post :create, query: "query { me { assignments(team_id: #{t1.id}, first: 10000) { edges { node { dbid } } } } }", team: t1.slug
    assert_response :success
    data = JSON.parse(@response.body)['data']['me']['assignments']['edges']
    assert_equal 1, data.size
    assert_equal pm1.id, data[0]['node']['dbid']

    post :create, query: "query { me { assignments(team_id: #{t2.id}, first: 10000) { edges { node { dbid } } } } }", team: t2.slug
    assert_response :success
    data = JSON.parse(@response.body)['data']['me']['assignments']['edges']
    assert_equal 1, data.size
    assert_equal pm2.id, data[0]['node']['dbid']
  end

  test "should search for dynamic annotations" do
    u = create_user
    authenticate_with_user(u)
    t = create_team slug: 'team'
    create_team_user user: u, team: t
    p = create_project team: t

    att = 'language'
    at = create_annotation_type annotation_type: att, label: 'Language'
    language = create_field_type field_type: 'language', label: 'Language'
    create_field_instance annotation_type_object: at, name: 'language', field_type_object: language
    pm1 = create_project_media disable_es_callbacks: false, project: p
    create_dynamic_annotation annotation_type: att, annotated: pm1, set_fields: { language: 'en' }.to_json, disable_es_callbacks: false
    pm2 = create_project_media disable_es_callbacks: false, project: p
    create_dynamic_annotation annotation_type: att, annotated: pm2, set_fields: { language: 'pt' }.to_json, disable_es_callbacks: false

    sleep 5

    query = 'query CheckSearch { search(query: "{\"dynamic\":{\"language\":[\"en\"]}}") { id,medias(first:20){edges{node{dbid}}}}}';
    post :create, query: query, team: 'team'
    assert_response :success
    pmids = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |pm| pm['node']['dbid'] }
    assert_equal 1, pmids.size
    assert_equal pm1.id, pmids[0]

    query = 'query CheckSearch { search(query: "{\"dynamic\":{\"language\":[\"pt\"]}}") { id,medias(first:20){edges{node{dbid}}}}}';
    post :create, query: query, team: 'team'
    assert_response :success
    pmids = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |pm| pm['node']['dbid'] }
    assert_equal 1, pmids.size
    assert_equal pm2.id, pmids[0]
  end

  test "should bulk-update things" do
    RequestStore.store[:skip_cached_field_update] = false
    Sidekiq::Testing.fake! do
      u = create_user
      t = create_team
      create_team_user team: t, user: u, role: 'owner'
      p1 = create_project team: t
      p2 = create_project team: t
      pm1 = create_project_media project: p1
      pm2 = create_project_media project: p1
      pm3 = create_project_media project: p1
      pm4 = create_project_media project: p1
      Sidekiq::Worker.drain_all

      assert_equal p1, pm1.reload.project
      assert_equal p1, pm2.reload.project
      assert_equal p1, pm3.reload.project
      assert_equal 0, Sidekiq::Worker.jobs.size

      authenticate_with_user(u)
      query = "mutation { updateProjectMedia(input: { clientMutationId: \"1\", id: \"#{pm1.graphql_id}\", ids: [\"#{pm1.graphql_id}\", \"#{pm2.graphql_id}\", \"#{pm3.graphql_id}\", \"#{pm4.graphql_id}\"], project_id: #{p2.id} }) { affectedIds, check_search_project { number_of_results } } }"
      post :create, query: query, team: t.slug
      assert_response :success
      assert_equal [pm1.graphql_id, pm2.graphql_id, pm3.graphql_id, pm4.graphql_id].sort, JSON.parse(@response.body)['data']['updateProjectMedia']['affectedIds'].sort
      sleep 1
      assert_equal 1, Sidekiq::Worker.jobs.size
      assert_equal p1, pm1.reload.project
      assert_equal p1, pm2.reload.project
      assert_equal p1, pm3.reload.project
      pm3.update_column(:archived, true)
      pm4.destroy!
      Sidekiq::Worker.drain_all
      assert_equal 0, Sidekiq::Worker.jobs.size
      assert_equal p2, ProjectMedia.find(pm1.id).project
      assert_equal p2, ProjectMedia.find(pm2.id).project
      assert_equal p1, ProjectMedia.find(pm3.id).project
      assert_nil ProjectMedia.where(id: pm4.id).last
    end
  end

  test "should bulk-destroy things" do
    RequestStore.store[:skip_cached_field_update] = false
    Sidekiq::Testing.fake! do
      u = create_user
      t = create_team
      create_team_user team: t, user: u, role: 'owner'
      p1 = create_project team: t
      p2 = create_project team: t
      pm1 = create_project_media project: p1
      pm2 = create_project_media project: p1
      Sidekiq::Worker.drain_all

      assert_not_nil ProjectMedia.where(id: pm1.id).last
      assert_not_nil ProjectMedia.where(id: pm2.id).last
      assert_equal 0, Sidekiq::Worker.jobs.size

      authenticate_with_user(u)
      query = "mutation { destroyProjectMedia(input: { clientMutationId: \"1\", id: \"#{pm1.graphql_id}\", ids: [\"#{pm1.graphql_id}\", \"#{pm2.graphql_id}\"] }) { affectedIds, check_search_team { number_of_results }, project { medias_count } } }"
      post :create, query: query, team: t.slug
      assert_response :success
      assert_equal [pm1.graphql_id, pm2.graphql_id].sort, JSON.parse(@response.body)['data']['destroyProjectMedia']['affectedIds'].sort
      sleep 1
      # size change due to obj.save! instead of update_all in `freeze_or_unfreeze_objects` method
      # assert_equal 1, Sidekiq::Worker.jobs.size
      assert_not_nil ProjectMedia.where(id: pm1.id).last
      assert_not_nil ProjectMedia.where(id: pm2.id).last
      Sidekiq::Worker.drain_all
      assert_equal 0, Sidekiq::Worker.jobs.size
      assert_nil ProjectMedia.where(id: pm1.id).last
      assert_nil ProjectMedia.where(id: pm2.id).last
    end
  end

  test "should set statuses of related items" do
    Sidekiq::Testing.fake! do
      BotUser.delete_all
      b = create_team_bot name: 'Smooch', login: 'smooch', set_approved: true, set_events: []
      u = create_user
      t = create_team
      create_team_bot_installation user_id: b.id, team_id: t.id
      create_team_user team: t, user: u, role: 'owner'
      p = create_project team: t
      pm1 = create_project_media project: p
      pm2 = create_project_media project: p
      pm3 = create_project_media project: p
      create_relationship source_id: pm1.id, target_id: pm2.id, user: create_user
      create_relationship source_id: pm1.id, target_id: pm3.id, user: create_user
      authenticate_with_user(u)

      assert_equal 'undetermined', pm1.reload.last_verification_status
      assert_equal 'undetermined', pm2.reload.last_verification_status
      assert_equal 'undetermined', pm3.reload.last_verification_status

      d = pm1.last_verification_status_obj

      query = 'mutation update { updateDynamic(input: { clientMutationId: "1", id: "' + d.graphql_id + '", set_fields: "{\"verification_status_status\":\"verified\"}" }) { project_media { targets_by_users(first: 10) { edges { node { last_status } } } } } }'
      post :create, query: query, team: t.slug
      assert_response :success
      assert_equal ['verified', 'verified'].sort, JSON.parse(@response.body)['data']['updateDynamic']['project_media']['targets_by_users']['edges'].collect{ |x| x['node']['last_status'] }
    end
  end

  test "should not remove logo when update team" do
    u = create_user
    team = create_team
    create_team_user team: team, user: u, role: 'owner'
    id = team.graphql_id

    authenticate_with_user(u)
    query = 'mutation { updateTeam(input: { clientMutationId: "1", id: "' + id + '" }) { team { id } } }'

    path = File.join(Rails.root, 'test', 'data', 'rails.png')
    file = Rack::Test::UploadedFile.new(path, 'image/png')
    post :create, query: query, team: team.slug, file: file
    team.reload
    assert_match /rails\.png$/, team.logo.url

    post :create, query: query, team: team.slug, file: 'undefined'
    team.reload
    assert_match /rails\.png$/, team.logo.url
  end

  test "should update relationship" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    pm1 = create_project_media project: p
    pm2 = create_project_media project: p
    r = create_relationship source_id: pm1.id, target_id: pm2.id
    assert_equal pm1, r.reload.source
    assert_equal pm2, r.reload.target
    authenticate_with_user(u)
    query = 'mutation { updateRelationship(input: { clientMutationId: "1", id: "' + r.graphql_id + '", source_id: ' + pm2.id.to_s + ', target_id: ' + pm1.id.to_s + ' }) { relationship { id, target { dbid }, source { dbid } }, source_project_media { id }, target_project_media { id } } }'
    post :create, query: query, team: t.slug
    assert_response :success
    data = JSON.parse(@response.body)['data']['updateRelationship']['relationship']
    assert_equal pm1.dbid, data['target']['dbid']
    assert_equal pm2.dbid, data['source']['dbid']
    assert_equal pm1, r.reload.target
    assert_equal pm2, r.reload.source
    assert_equal pm2.graphql_id, JSON.parse(@response.body)['data']['updateRelationship']['source_project_media']['id']
    assert_equal pm1.graphql_id, JSON.parse(@response.body)['data']['updateRelationship']['target_project_media']['id']
  end

  test "should destroy relationship" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    pm1 = create_project_media project: p
    pm2 = create_project_media project: p
    r = create_relationship source_id: pm1.id, target_id: pm2.id
    assert_not_nil Relationship.where(id: r.id).last
    authenticate_with_user(u)
    query = 'mutation { destroyRelationship(input: { clientMutationId: "1", id: "' + r.graphql_id + '" }) { deletedId, source_project_media { id }, target_project_media { id }, current_project_media { id } } }'
    post :create, query: query, team: t.slug
    assert_response :success
    assert_equal pm2.graphql_id, JSON.parse(@response.body)['data']['destroyRelationship']['deletedId']
    assert_equal pm1.graphql_id, JSON.parse(@response.body)['data']['destroyRelationship']['source_project_media']['id']
    assert_equal pm2.graphql_id, JSON.parse(@response.body)['data']['destroyRelationship']['target_project_media']['id']
    assert_nil Relationship.where(id: r.id).last
  end

  test "should get version from global id" do
    authenticate_with_user
    v = create_version
    t = Team.last
    id = Base64.encode64("Version/#{v.id}")
    q = assert_queries 10 do
      post :create, query: "query Query { node(id: \"#{id}\") { id } }", team: t.slug
    end
    assert !q.include?('SELECT  "versions".* FROM "versions" WHERE "versions"."id" = $1 LIMIT 1')
    assert q.include?("SELECT  \"versions\".* FROM \"versions_partitions\".\"p#{t.id}\" \"versions\" WHERE \"versions\".\"id\" = $1  ORDER BY \"versions\".\"id\" DESC LIMIT 1")
  end

  test "should empty trash" do
    u = create_user
    team = create_team
    create_team_user team: team, user: u, role: 'owner'
    p = create_project team: team
    create_project_media archived: true, project: p
    assert_equal 1, team.reload.trash_count
    id = team.graphql_id
    authenticate_with_user(u)
    query = 'mutation { updateTeam(input: { clientMutationId: "1", id: "' + id + '", empty_trash: 1 }) { public_team { trash_count } } }'
    post :create, query: query, team: team.slug
    assert_response :success
    assert_equal 0, JSON.parse(@response.body)['data']['updateTeam']['public_team']['trash_count']
  end
end
