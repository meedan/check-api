require_relative '../test_helper'
require 'error_codes'

class GraphqlController2Test < ActionController::TestCase
  def setup
    @controller = Api::V1::GraphqlController.new
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
    post :create, params: { query: 'query PublicTeam { public_team { id, trash_count, pusher_channel } }', team: 'team' }
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

    query = 'query CheckSearch { search(query: "{}") { id,medias(first:20){edges{node{id,dbid,url,quote,published,updated_at,log_count,pusher_channel,domain,permissions,last_status,last_status_obj{id,dbid},media{url,quote,embed_path,thumbnail_path,id},user{name,source{dbid,accounts(first:10000){edges{node{url,id}}},id},id},team{slug,id},tags(first:10000){edges{node{tag,id}}}}}}}}'

    post :create, params: { query: query, team: 'team' }
    assert_response :success
    assert_equal 2, JSON.parse(@response.body)['data']['search']['medias']['edges'].size
  end

  test "should read attribution" do
    t, p, pm = assert_task_response_attribution
    u = create_user is_admin: true
    authenticate_with_user(u)
    query = "query GetById { project_media(ids: \"#{pm.id},#{p.id}\") { tasks { edges { node { first_response { attribution { edges { node { name } } } } } } } } }"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    data = JSON.parse(@response.body)['data']['project_media']
    users = data['tasks']['edges'][0]['node']['first_response']['attribution']['edges'].collect{ |u| u['node']['name'] }
    assert_equal ['User 1', 'User 3'].sort, users.sort
  end

  test "should create team and return user and team_userEdge" do
    authenticate_with_user
    query = 'mutation create { createTeam(input: { clientMutationId: "1", name: "Test", slug: "' + random_string + '") { user { id }, team_userEdge } }'
    post :create, params: { query: query }
    assert_response :success
  end

  test "should return 409 on conflict" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'admin'
    s = create_source user: u, team: t
    s.name = 'Changed'
    s.save!
    assert_equal 1, s.reload.lock_version
    authenticate_with_user(u)
    query = 'mutation update { updateSource(input: { clientMutationId: "1", name: "Changed again", lock_version: 0, id: "' + s.reload.graphql_id + '"}) { source { id } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response 409
  end

  test "should parse JSON exception" do
    url = 'http://test.com'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item"}}'
    PenderClient::Mock.mock_medias_returns_parsed_data(CheckConfig.get('pender_url_private')) do
      WebMock.disable_net_connect! allow: [CheckConfig.get('elasticsearch_host').to_s + ':' + CheckConfig.get('elasticsearch_port').to_s, CheckConfig.get('storage_endpoint')]
      WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)

      u = create_user
      t = create_team
      create_team_user user: u, team: t, role: 'admin'
      p = create_project team: t
      authenticate_with_user(u)

      query = 'mutation { createProjectMedia(input: { clientMutationId: "1", url: "' + url + '"}) { project_media { id } } }'
      post :create, params: { query: query, team: t.slug }
      assert_response :success

      post :create, params: { query: query, team: t.slug }
      assert_response 400
      ret = JSON.parse(@response.body)
      assert_includes ret.keys, 'errors'
      error_info = ret['errors'].first
      assert_equal error_info.keys.sort, ['code', 'data', 'message'].sort
      assert_equal ::LapisConstants::ErrorCodes::DUPLICATED, error_info['code']
      assert_kind_of Integer, error_info['data']['team_id']
      assert_kind_of Integer, error_info['data']['id']
      assert_equal 'media', error_info['data']['type']
    end
  end

  test "should get user confirmed" do
    u = create_user
    authenticate_with_user(u)
    post :create, params: { query: "query GetById { user(id: \"#{u.id}\") { confirmed  } }" }
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
    post :create, params: { query: "query GetById { user(id: \"#{u.id}\") { assignments(first: 10) { edges { node { dbid, assignments(first: 10, user_id: #{u.id}, annotation_type: \"task\") { edges { node { dbid } } } } } } } }" }
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
    post :create, params: { query: 'query Team { team(slug: "team") { name, public_team { id } } }' }
    assert_response 200
    assert_equal "Not Found", JSON.parse(@response.body)['errors'][0]['message']
  end

  test "should start Apollo if not running" do
    File.stubs(:exist?).returns(true)
    File.stubs(:read).returns({ frontends: [{ port: 9999 }] }.to_json)
    post :create, params: { query: 'query Query { about { name, version } }' }
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
    post :create, params: { query: 'query Query { about { name, version } }' }
    File.unstub(:exist?)
    File.unstub(:read)
    apollo.close
    assert_response 200
    assert_equal false, assigns(:started_apollo)
  end

  test "should get team with arabic slug" do
    authenticate_with_user
    t = create_team slug: 'المصالحة', name: 'Arabic Team'
    post :create, params: { query: 'query Query { about { name, version } }', team: '%D8%A7%D9%84%D9%85%D8%B5%D8%A7%D9%84%D8%AD%D8%A9' }
    assert_response :success
    assert_equal t, assigns(:context_team)
  end

  test "should not create duplicated tag" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'admin'
    authenticate_with_user(u)
    p = create_project team: t
    pm = create_project_media project: p
    query = 'mutation create { createTag(input: { clientMutationId: "1", tag: "egypt", annotated_type: "ProjectMedia", annotated_id: "' + pm.id.to_s + '"}) { tag { id } } }'
    post :create, params: { query: query }
    assert_response :success
    post :create, params: { query: query }
    assert_response 400
    assert_match /Tag already exists/, @response.body
  end

  test "should change status if collaborator" do
    create_verification_status_stuff
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'collaborator'
    create_team_user team: create_team, user: u, role: 'admin'
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
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal 'verified', f.reload.value
  end

  test "should assign status if collaborator" do
    create_verification_status_stuff
    u = create_user
    u2 = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'collaborator'
    create_team_user team: t, user: u2, role: 'collaborator'
    create_team_user team: create_team, user: u, role: 'admin'
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
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal 'undetermined', f.reload.value
  end

  test "should get relationship from global id" do
    authenticate_with_user
    pm = create_project_media
    id = Base64.encode64("Relationships/#{pm.id}")
    id2 = Base64.encode64("ProjectMedia/#{pm.id}")
    post :create, params: { query: "query Query { node(id: \"#{id}\") { id } }" }
    assert_equal id2, JSON.parse(@response.body)['data']['node']['id']
  end

  test "should create related report" do
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p
    u = create_user
    create_team_user user: u, team: t, role: 'collaborator'
    authenticate_with_user(u)
    query = 'mutation create { createProjectMedia(input: { url: "", quote: "X", media_type: "Claim", clientMutationId: "1", related_to_id: ' + pm.id.to_s + ' }) { check_search_team { number_of_results }, project_media { id } } }'
    assert_difference 'Relationship.count' do
      post :create, params: { query: query, team: t }
    end
    assert_response :success
  end

  test "should return permissions of sibling report" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'admin'
    p = create_project team: t
    pm = create_project_media project: p
    pm1 = create_project_media project: p, user: u
    create_relationship source_id: pm.id, target_id: pm1.id
    pm1.archived = CheckArchivedFlags::FlagCodes::TRASHED
    pm1.save!

    authenticate_with_user(u)

    query = "query GetById { project_media(ids: \"#{pm1.id},#{p.id}\") {permissions,source{permissions}}}"
    post :create, params: { query: query, team: t.slug }

    assert_response :success
  end

  test "should create dynamic annotation type" do
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p
    u = create_user
    create_team_user user: u, team: t, role: 'admin'
    authenticate_with_user(u)

    query = 'mutation create { createDynamicAnnotationMetadata(input: { annotated_id: "' + pm.id.to_s + '", clientMutationId: "1", annotated_type: "ProjectMedia", set_fields: "{\"metadata_value\":\"test\"}" }) { dynamic { id, annotation_type } } }'

    assert_difference 'Dynamic.count' do
      post :create, params: { query: query, team: t }
    end
    assert_equal 'metadata', JSON.parse(@response.body)['data']['createDynamicAnnotationMetadata']['dynamic']['annotation_type']
    assert_response :success
  end

  test "should read project media dynamic annotation fields" do
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p
    u = create_user
    create_team_user user: u, team: t, role: 'admin'
    authenticate_with_user(u)
    d = create_dynamic_annotation annotated: pm, annotation_type: 'metadata'

    query = "query GetById { project_media(ids: \"#{pm.id},#{p.id}\") { dynamic_annotation_metadata { dbid }, dynamic_annotations_metadata { edges { node { dbid } } } } }"
    post :create, params: { query: query, team: t.slug }

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

  test "should get approved bots, current user and current team" do
    BotUser.delete_all
    authenticate_with_user
    tb1 = create_team_bot set_approved: true
    tb2 = create_team_bot set_approved: false
    query = "query read { root { current_user { id }, current_team { id }, team_bots_approved { edges { node { dbid } } } } }"
    post :create, params: { query: query }
    edges = JSON.parse(@response.body)['data']['root']['team_bots_approved']['edges']
    assert_equal [tb1.id], edges.collect{ |e| e['node']['dbid'] }
  end

  test "should get bot by id" do
    authenticate_with_user
    tb = create_team_bot set_approved: true, name: 'My Bot'
    query = "query read { bot_user(id: #{tb.id}) { name } }"
    post :create, params: { query: query }
    assert_response :success
    name = JSON.parse(@response.body)['data']['bot_user']['name']
    assert_equal 'My Bot', name
  end

  test "should get bots installed in a team" do
    t = create_team slug: 'test'
    u = create_user
    create_team_user user: u, team: t, role: 'admin'
    authenticate_with_user(u)

    tb1 = create_team_bot set_approved: false, name: 'Custom Bot', team_author_id: t.id
    tb2 = create_team_bot set_approved: true, name: 'My Bot'
    tb3 = create_team_bot set_approved: true, name: 'Other Bot'
    create_team_bot_installation user_id: tb2.id, team_id: t.id

    query = 'query read { team(slug: "test") { team_bots { edges { node { name, settings_as_json_schema(team_slug: "test"), team_author { slug } } } } } }'
    post :create, params: { query: query }
    assert_response :success
    edges = JSON.parse(@response.body)['data']['team']['team_bots']['edges']
    assert_equal ['Custom Bot', 'My Bot'], edges.collect{ |e| e['node']['name'] }.sort
    assert edges[0]['node']['team_author']['slug'] == 'test' || edges[1]['node']['team_author']['slug'] == 'test'
  end

  test "should get bot installations in a team" do
    t = create_team slug: 'test'
    u = create_user
    create_team_user user: u, team: t, role: 'admin'
    authenticate_with_user(u)

    tb1 = create_team_bot set_approved: false, name: 'Custom Bot', team_author_id: t.id
    tb2 = create_team_bot set_approved: true, name: 'My Bot'
    tb3 = create_team_bot set_approved: true, name: 'Other Bot'
    create_team_bot_installation user_id: tb2.id, team_id: t.id

    query = 'query read { team(slug: "test") { team_bot_installations { edges { node { team { slug, public_team { id } }, bot_user { name } } } } } }'
    post :create, params: { query: query }
    assert_response :success
    edges = JSON.parse(@response.body)['data']['team']['team_bot_installations']['edges']
    assert_equal ['Custom Bot', 'My Bot'], edges.collect{ |e| e['node']['bot_user']['name'] }.sort
    assert_equal ['test', 'test'], edges.collect{ |e| e['node']['team']['slug'] }
  end

  test "should install bot using mutation" do
    t = create_team slug: 'test'
    u = create_user
    create_team_user user: u, team: t, role: 'admin'
    tb = create_team_bot set_approved: true

    authenticate_with_user(u)

    assert_equal [], t.team_bots

    query = 'mutation create { createTeamBotInstallation(input: { clientMutationId: "1", user_id: ' + tb.id.to_s + ', team_id: ' + t.id.to_s + ' }) { team { dbid }, bot_user { dbid } } }'
    assert_difference 'TeamBotInstallation.count' do
      post :create, params: { query: query }
    end
    data = JSON.parse(@response.body)['data']['createTeamBotInstallation']

    assert_equal [tb], t.reload.team_bots
    assert_equal t.id, data['team']['dbid']
    assert_equal tb.id, data['bot_user']['dbid']
  end

  test "should uninstall bot using mutation" do
    t = create_team slug: 'test'
    u = create_user
    create_team_user user: u, team: t, role: 'admin'
    tb = create_team_bot set_approved: true
    tbi = create_team_bot_installation team_id: t.id, user_id: tb.id

    authenticate_with_user(u)

    assert_equal [tb], t.reload.team_bots

    query = 'mutation delete { destroyTeamBotInstallation(input: { clientMutationId: "1", id: "' + tbi.graphql_id + '" }) { deletedId } }'
    assert_difference 'TeamBotInstallation.count', -1 do
      post :create, params: { query: query }
    end
    data = JSON.parse(@response.body)['data']['destroyTeamBotInstallation']

    assert_equal [], t.reload.team_bots
    assert_equal tbi.graphql_id, data['deletedId']
  end

  test "should get team tag_texts" do
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p
    u = create_user
    create_team_user user: u, team: t, role: 'admin'
    authenticate_with_user(u)
    create_tag_text text: 'foo', team_id: t.id

    query = "query GetById { team(id: \"#{t.id}\") { tag_texts { edges { node { text } } } } }"
    post :create, params: { query: query, team: t.slug }

    assert_response :success
    data = JSON.parse(@response.body)['data']['team']
    assert_equal 'foo', data['tag_texts']['edges'][0]['node']['text']
  end

  test "should get team team_users" do
    t = create_team
    u = create_user
    u2 = create_user
    create_team_user team: t, user: u, role: 'admin'
    create_team_user team: t, user: u2
    authenticate_with_user(u)
    query = "query GetById { team(id: \"#{t.id}\") { team_users { edges { node { user { dbid } } } } } }"
    post :create, params: { query: query, team: t.slug }

    assert_response :success
    data = JSON.parse(@response.body)['data']['team']['team_users']['edges']
    ids = data.collect{ |i| i['node']['user']['dbid'] }
    assert_equal 2, data.size
    assert_equal [u.id, u2.id], ids.sort
  end

  test "should get team tasks" do
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p
    u = create_user
    create_team_user user: u, team: t, role: 'admin'
    authenticate_with_user(u)
    tt = create_team_task team_id: t.id, order: 3
    tt2 = create_team_task team_id: t.id, order: 5
    tt3 = create_team_task team_id: t.id, label: 'Foo'

    query = "query GetById { team(id: \"#{t.id}\") { team_tasks { edges { node { label, dbid, type, order, description, options, project_ids, required, team_id, team { slug } } } } } }"
    post :create, params: { query: query, team: t.slug }

    assert_response :success
    data = JSON.parse(@response.body)['data']['team']
    assert_equal 3, data['team_tasks']['edges'][0]['node']['order']
    assert_equal tt.id, data['team_tasks']['edges'][0]['node']['dbid']
    assert_equal tt2.id, data['team_tasks']['edges'][1]['node']['dbid']
    assert_equal tt3.id, data['team_tasks']['edges'][2]['node']['dbid']
  end

  # test "should not import spreadsheet if URL is not present" do
  #   t = create_team
  #   u = create_user
  #   create_team_user user: u, team: t, role: 'admin'

  #   authenticate_with_user(u)

  #   query = "mutation importSpreadsheet { importSpreadsheet(input: { clientMutationId: \"1\", team_id: #{t.id}, user_id: #{u.id} }) { success } }"
  #   post :create, query: query, team: t.slug
  #   sleep 1
  #   assert_response :success
  #   response = JSON.parse(@response.body)
  #   assert response.has_key?('errors')
  #   assert_match /invalid value/, response['errors'].first['message']
  # end

  # test "should not import spreadsheet if team_id is not present" do
  #   t = create_team
  #   u = create_user
  #   create_team_user user: u, team: t, role: 'admin'

  #   authenticate_with_user(u)

  #   spreadsheet_url = "https://docs.google.com/spreadsheets/d/1lyxWWe9rRJPZejkCpIqVrK54WUV2UJl9sR75W5_Z9jo/edit#gid=0"
  #   query = "mutation importSpreadsheet { importSpreadsheet(input: { clientMutationId: \"1\", spreadsheet_url: \"#{spreadsheet_url}\", user_id: #{u.id} }) { success } }"
  #   post :create, query: query, team: t.slug
  #   sleep 1
  #   assert_response :success
  #   response = JSON.parse(@response.body)
  #   assert response.has_key?('errors')
  #   assert_match /invalid value/, response['errors'].first['message']
  # end

  # test "should not import spreadsheet if user_id is not present" do
  #   t = create_team
  #   u = create_user
  #   create_team_user user: u, team: t, role: 'admin'

  #   authenticate_with_user(u)

  #   spreadsheet_url = "https://docs.google.com/spreadsheets/d/1lyxWWe9rRJPZejkCpIqVrK54WUV2UJl9sR75W5_Z9jo/edit#gid=0"
  #   query = "mutation importSpreadsheet { importSpreadsheet(input: { clientMutationId: \"1\", spreadsheet_url: \"#{spreadsheet_url}\", team_id: #{t.id} }) { success } }"
  #   post :create, query: query, team: t.slug
  #   sleep 1
  #   assert_response :success
  #   response = JSON.parse(@response.body)
  #   assert response.has_key?('errors')
  #   assert_match /invalid value/, response['errors'].first['message']
  # end

  # test "should not import spreadsheet if URL is invalid" do
  #   t = create_team
  #   u = create_user
  #   create_team_user user: u, team: t, role: 'admin'

  #   authenticate_with_user(u)

  #   [' ', 'https://example.com'].each do |url|
  #     query = "mutation importSpreadsheet { importSpreadsheet(input: { clientMutationId: \"1\", spreadsheet_url: \"#{url}\", team_id: #{t.id}, user_id: #{u.id} }) { success } }"
  #     post :create, query: query, team: t.slug
  #     sleep 1
  #     assert_response 400
  #     response = JSON.parse(@response.body)
  #     assert_includes response.keys, 'errors'
  #     error_info = response['errors'].first
  #     assert_equal 'INVALID_VALUE', error_info['code']
  #   end
  # end

  # test "should not import spreadsheet if id not found" do
  #   t = create_team
  #   u = create_user
  #   create_team_user user: u, team: t, role: 'admin'

  #   authenticate_with_user(u)
  #   spreadsheet_url = "https://docs.google.com/spreadsheets/d/invalid_spreadsheet/edit#gid=0"
  #   query = "mutation importSpreadsheet { importSpreadsheet(input: { clientMutationId: \"1\", spreadsheet_url: \"#{spreadsheet_url}\", team_id: #{t.id}, user_id: #{u.id} }) { success } }"

  #   post :create, query: query, team: t.slug
  #   assert_response 400
  #   response = JSON.parse(@response.body)
  #   error_info = response['errors'].first
  #   assert_equal 'INVALID_VALUE', error_info['code']
  #   assert_match /File not found/, error_info['data']['error_message']
  # end

  # test "should import spreadsheet if inputs are valid" do
  #   t = create_team
  #   u = create_user
  #   create_team_user user: u, team: t, role: 'admin'

  #   authenticate_with_user(u)
  #   spreadsheet_url = "https://docs.google.com/spreadsheets/d/1lyxWWe9rRJPZejkCpIqVrK54WUV2UJl9sR75W5_Z9jo/edit#gid=0"
  #   query = "mutation importSpreadsheet { importSpreadsheet(input: { clientMutationId: \"1\", spreadsheet_url: \"#{spreadsheet_url}\", team_id: #{t.id}, user_id: #{u.id} }) { success } }"
  #   post :create, query: query, team: t.slug
  #   assert_response :success
  #   assert_equal({"success" => true}, JSON.parse(@response.body)['data']['importSpreadsheet'])
  # end

  test "should read project media user if not annotator" do
    u = create_user
    u2 = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'collaborator'
    create_team_user user: u2, team: t
    authenticate_with_user(u)
    p = create_project team: t
    pm = create_project_media project: p, user: u2
    t = create_task annotated: pm
    t.assign_user(u.id)
    query = "query GetById { project_media(ids: \"#{pm.id},#{p.id}\") { user { id } } }"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_not_nil JSON.parse(@response.body)['data']['project_media']['user']
  end

  test "should get project assignments" do
    u = create_user is_admin: true
    u2 = create_user name: 'Assigned to Project'
    t = create_team
    create_team_user user: u2, team: t
    p = create_project team: t
    p.assign_user(u2.id)
    authenticate_with_user(u)

    post :create, params: { query: "query { project(ids: \"#{p.id},#{t.id}\") { assignments_count, assigned_users(first: 10000) { edges { node { name } } } } }", team: t.slug }
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

    post :create, params: { query: "query { me { assignments(first: 10000) { edges { node { dbid } } } } }", team: t1.slug }
    assert_response :success
    data = JSON.parse(@response.body)['data']['me']['assignments']['edges']
    assert_equal 2, data.size

    post :create, params: { query: "query { me { assignments(team_id: #{t1.id}, first: 10000) { edges { node { dbid } } } } }", team: t1.slug }
    assert_response :success
    data = JSON.parse(@response.body)['data']['me']['assignments']['edges']
    assert_equal 1, data.size
    assert_equal pm1.id, data[0]['node']['dbid']

    post :create, params: { query: "query { me { assignments(team_id: #{t2.id}, first: 10000) { edges { node { dbid } } } } }", team: t2.slug }
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
    post :create, params: { query: query, team: 'team' }
    assert_response :success
    pmids = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |pm| pm['node']['dbid'] }
    assert_equal 1, pmids.size
    assert_equal pm1.id, pmids[0]

    query = 'query CheckSearch { search(query: "{\"dynamic\":{\"language\":[\"pt\"]}}") { id,medias(first:20){edges{node{dbid}}}}}';
    post :create, params: { query: query, team: 'team' }
    assert_response :success
    pmids = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |pm| pm['node']['dbid'] }
    assert_equal 1, pmids.size
    assert_equal pm2.id, pmids[0]
  end

  test "should not remove logo when update team" do
    u = create_user
    team = create_team
    create_team_user team: team, user: u, role: 'admin'
    id = team.graphql_id

    authenticate_with_user(u)
    query = 'mutation { updateTeam(input: { clientMutationId: "1", id: "' + id + '" }) { team { id } } }'

    path = File.join(Rails.root, 'test', 'data', 'rails.png')
    file = Rack::Test::UploadedFile.new(path, 'image/png')
    post :create, params: { query: query, team: team.slug, file: file }
    team.reload
    assert_match /rails\.png$/, team.logo.url

    post :create, params: { query: query, team: team.slug, file: 'undefined' }
    team.reload
    assert_match /rails\.png$/, team.logo.url
  end

  test "should update relationship" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'admin'
    p = create_project team: t
    pm1 = create_project_media project: p
    pm2 = create_project_media project: p
    r = create_relationship source_id: pm1.id, target_id: pm2.id
    assert_equal pm1, r.reload.source
    assert_equal pm2, r.reload.target
    authenticate_with_user(u)
    query = 'mutation { updateRelationship(input: { clientMutationId: "1", id: "' + r.graphql_id + '", source_id: ' + pm2.id.to_s + ', target_id: ' + pm1.id.to_s + ' }) { relationship { id, target { dbid }, source { dbid } }, source_project_media { id }, target_project_media { id } } }'
    post :create, params: { query: query, team: t.slug }
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
    create_team_user team: t, user: u, role: 'admin'
    p = create_project team: t
    pm1 = create_project_media project: p
    pm2 = create_project_media project: p
    r = create_relationship source_id: pm1.id, target_id: pm2.id
    assert_not_nil Relationship.where(id: r.id).last
    authenticate_with_user(u)
    query = 'mutation { destroyRelationship(input: { clientMutationId: "1", id: "' + r.graphql_id + '" }) { deletedId, source_project_media { id }, target_project_media { id } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal pm1.graphql_id, JSON.parse(@response.body)['data']['destroyRelationship']['source_project_media']['id']
    assert_equal pm2.graphql_id, JSON.parse(@response.body)['data']['destroyRelationship']['target_project_media']['id']
    assert_nil Relationship.where(id: r.id).last
    # detach to specific list
    p2 = create_project team: t
    r = create_relationship source_id: pm1.id, target_id: pm2.id
    assert_equal p.id, pm2.project_id
    query = 'mutation { destroyRelationship(input: { clientMutationId: "1", id: "' + r.graphql_id + '", add_to_project_id: ' + p2.id.to_s + ' }) { deletedId, source_project_media { id }, target_project_media { id } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal p2.id, pm2.reload.project_id
  end

  test "should get version from global id" do
    authenticate_with_user
    v = create_version
    t = Team.last
    id = Base64.encode64("Version/#{v.id}")
    q = assert_queries 9, '<=' do
      post :create, params: { query: "query Query { node(id: \"#{id}\") { id } }", team: t.slug }
    end
    assert !q.include?('SELECT  "versions".* FROM "versions" WHERE "versions"."id" = $1 LIMIT 1')
    assert q.include?("SELECT  \"versions\".* FROM \"versions_partitions\".\"p#{t.id}\" \"versions\" WHERE \"versions\".\"id\" = $1 ORDER BY \"versions\".\"id\" DESC LIMIT $2")
  end

  test "should empty trash" do
    u = create_user
    team = create_team
    create_team_user team: team, user: u, role: 'admin'
    p = create_project team: team
    create_project_media archived: CheckArchivedFlags::FlagCodes::TRASHED, project: p
    assert_equal 1, team.reload.trash_count
    id = team.graphql_id
    authenticate_with_user(u)
    query = 'mutation { updateTeam(input: { clientMutationId: "1", id: "' + id + '", empty_trash: 1 }) { public_team { trash_count } } }'
    post :create, params: { query: query, team: team.slug }
    assert_response :success
    assert_equal 0, JSON.parse(@response.body)['data']['updateTeam']['public_team']['trash_count']
  end

  test "should provide empty fallback only if deleted status has no items" do
    t = create_team
    value = {
      label: 'Status',
      active: 'id',
      default: 'id',
      statuses: [
        { id: 'id', locales: { en: { label: 'Custom Status', description: 'The meaning of this status' } }, style: { color: 'red' } },
      ]
    }
    t.set_media_verification_statuses(value)
    t.save!

    u = create_user
    create_team_user user: u, team: t, role: 'admin'
    authenticate_with_user(u)

    pm = create_project_media project: nil, team: t
    s = pm.annotations.where(annotation_type: 'verification_status').last.load
    s.status = 'id'
    s.save!

    query = "mutation deleteTeamStatus { deleteTeamStatus(input: { clientMutationId: \"1\", team_id: \"#{t.graphql_id}\", status_id: \"id\", fallback_status_id: \"\" }) { team { id } } }"
    post :create, params: { query: query, team: t.slug }
    assert_response 400

    pm.destroy!

    query = "mutation deleteTeamStatus { deleteTeamStatus(input: { clientMutationId: \"1\", team_id: \"#{t.graphql_id}\", status_id: \"id\", fallback_status_id: \"\" }) { team { id } } }"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
  end

  test "should duplicate when user is owner and not duplicate when not an owner" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'admin'
    value = {
      label: 'Status',
      active: 'id',
      default: 'id',
      statuses: [
        { id: 'id', locales: { en: { label: 'Custom Status', description: 'The meaning of this status' } }, style: { color: 'red' } },
      ]
    }
    t.set_media_verification_statuses(value)
    t.save!

    query = "mutation duplicateTeam { duplicateTeam(input: { team_id: \"#{t.graphql_id}\" }) { team { id } } }"
    post :create, params: { query: query, team: t.slug }
    assert_response 400

    authenticate_with_user(u)
    query = "mutation duplicateTeam { duplicateTeam(input: { team_id: \"#{t.graphql_id}\" }) { team { id } } }"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
  end

  test "should filter by link published date" do
    RequestStore.store[:skip_cached_field_update] = false
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'admin'

    WebMock.disable_net_connect! allow: [CheckConfig.get('elasticsearch_host').to_s + ':' + CheckConfig.get('elasticsearch_port').to_s, CheckConfig.get('storage_endpoint')]
    url = 'http://test.com'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item","published_at":"Sat Oct 31 15:11:49 +0000 2020"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    pm1 = create_project_media team: t, url: url, disable_es_callbacks: false ; sleep 1

    WebMock.disable_net_connect! allow: [CheckConfig.get('elasticsearch_host').to_s + ':' + CheckConfig.get('elasticsearch_port').to_s, CheckConfig.get('storage_endpoint')]
    url = 'http://test.com/2'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item","published_at":"Fri Oct 23 14:41:05 +0000 2020"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    pm2 = create_project_media team: t, url: url, disable_es_callbacks: false ; sleep 1

    authenticate_with_user(u)

    query = 'query CheckSearch { search(query: "{\"range\":{\"media_published_at\":{\"start_time\":\"2020-10-30\",\"end_time\":\"2020-11-01\"}}}") { id,medias(first:20){edges{node{dbid}}}}}';
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal [pm1.id], JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |pm| pm.dig('node', 'dbid') }

    query = 'query CheckSearch { search(query: "{\"range\":{\"media_published_at\":{\"start_time\":\"2020-10-20\",\"end_time\":\"2020-10-24\"}}}") { id,medias(first:20){edges{node{dbid}}}}}';
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal [pm2.id], JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |pm| pm.dig('node', 'dbid') }

    WebMock.disable_net_connect! allow: [CheckConfig.get('elasticsearch_host').to_s + ':' + CheckConfig.get('elasticsearch_port').to_s, CheckConfig.get('storage_endpoint')]
    url = 'http://test.com'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item","published_at":"Fri Oct 23 14:41:05 +0000 2020"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url, refresh: '1' } }).to_return(body: response)
    pm1 = ProjectMedia.find(pm1.id) ; pm1.disable_es_callbacks = false ; pm1.refresh_media = true ; pm1.save! ; sleep 1

    WebMock.disable_net_connect! allow: [CheckConfig.get('elasticsearch_host').to_s + ':' + CheckConfig.get('elasticsearch_port').to_s, CheckConfig.get('storage_endpoint')]
    url = 'http://test.com/2'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item","published_at":"Sat Oct 31 15:11:49 +0000 2020"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url, refresh: '1' } }).to_return(body: response)
    pm2 = ProjectMedia.find(pm2.id) ; pm2.disable_es_callbacks = false ; pm2.refresh_media = true ; pm2.save! ; sleep 1

    query = 'query CheckSearch { search(query: "{\"range\":{\"media_published_at\":{\"start_time\":\"2020-10-30\",\"end_time\":\"2020-11-01\"}}}") { id,medias(first:20){edges{node{dbid}}}}}';
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal [pm2.id], JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |pm| pm.dig('node', 'dbid') }

    query = 'query CheckSearch { search(query: "{\"range\":{\"media_published_at\":{\"start_time\":\"2020-10-20\",\"end_time\":\"2020-10-24\"}}}") { id,medias(first:20){edges{node{dbid}}}}}';
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal [pm1.id], JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |pm| pm.dig('node', 'dbid') }
  end

  test "should search for tags using operator" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'admin'
    authenticate_with_user(u)
    pm1 = create_project_media team: t, disable_es_callbacks: false
    create_tag annotated: pm1, tag: 'test tag 1', disable_es_callbacks: false
    pm2 = create_project_media team: t, disable_es_callbacks: false
    create_tag annotated: pm2, tag: 'test tag 2', disable_es_callbacks: false
    pm3 = create_project_media team: t, disable_es_callbacks: false
    create_tag annotated: pm3, tag: 'test tag 1', disable_es_callbacks: false
    create_tag annotated: pm3, tag: 'test tag 2', disable_es_callbacks: false
    pm4 = create_project_media team: t, disable_es_callbacks: false
    create_tag annotated: pm4, tag: 'test tag 3', disable_es_callbacks: false
    pm5 = create_project_media team: t, disable_es_callbacks: false
    sleep 2

    query = 'query CheckSearch { search(query: "{\"tags\":[\"test tag 1\",\"test tag 2\"]}") { id,medias(first:20){edges{node{dbid}}}}}'
    post :create, params: { query: query, team: 'team' }
    assert_response :success
    assert_equal 3, JSON.parse(@response.body)['data']['search']['medias']['edges'].size

    query = 'query CheckSearch { search(query: "{\"tags\":[\"test tag 1\",\"test tag 2\"],\"tags_operator\":\"or\"}") { id,medias(first:20){edges{node{dbid}}}}}'
    post :create, params: { query: query, team: 'team' }
    assert_response :success
    assert_equal 3, JSON.parse(@response.body)['data']['search']['medias']['edges'].size

    query = 'query CheckSearch { search(query: "{\"tags\":[\"test tag 1\",\"test tag 2\"],\"tags_operator\":\"and\"}") { id,medias(first:20){edges{node{dbid}}}}}'
    post :create, params: { query: query, team: 'team' }
    assert_response :success
    assert_equal [pm3.id], JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |e| e['node']['dbid'] }
  end

  test "should search by user assigned to item" do
    u = create_user is_admin: true
    t = create_team
    create_team_user user: u, team: t, role: 'admin'
    authenticate_with_user(u)

    u1 = create_user
    create_team_user user: u1, team: t
    pm1 = create_project_media team: t, disable_es_callbacks: false
    a1 = Assignment.create! user: u1, assigned: pm1.last_status_obj, disable_es_callbacks: false
    u3 = create_user
    create_team_user user: u3, team: t
    Assignment.create! user: u3, assigned: pm1.last_status_obj, disable_es_callbacks: false

    u2 = create_user
    create_team_user user: u2, team: t
    pm2 = create_project_media team: t, disable_es_callbacks: false
    a2 = Assignment.create! user: u2, assigned: pm2.last_status_obj, disable_es_callbacks: false
    u4 = create_user
    create_team_user user: u4, team: t
    Assignment.create! user: u4, assigned: pm2.last_status_obj, disable_es_callbacks: false

    u5 = create_user
    sleep 2

    query = 'query CheckSearch { search(query: "{\"assigned_to\":[' + u1.id.to_s + ',' + u5.id.to_s + ']}") { id,medias(first:20){edges{node{dbid}}}}}'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal [pm1.id], JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |pm| pm['node']['dbid'] }

    query = 'query CheckSearch { search(query: "{\"assigned_to\":[' + u2.id.to_s + ',' + u5.id.to_s + ']}") { id,medias(first:20){edges{node{dbid}}}}}'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal [pm2.id], JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |pm| pm['node']['dbid'] }

    query = 'query CheckSearch { search(query: "{\"assigned_to\":[\"ANY_VALUE\"]}") { id,medias(first:20){edges{node{dbid}}}}}'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    ids = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |pm| pm['node']['dbid'] }
    assert_equal [pm1.id, pm2.id], ids.sort

    query = 'query CheckSearch { search(query: "{\"assigned_to\":[\"NO_VALUE\"]}") { id,medias(first:20){edges{node{dbid}}}}}'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    ids = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |pm| pm['node']['dbid'] }
    assert_empty ids

    a1.destroy!
    a2.destroy!
    sleep 2

    query = 'query CheckSearch { search(query: "{\"assigned_to\":[' + u1.id.to_s + ',' + u5.id.to_s + ']}") { id,medias(first:20){edges{node{dbid}}}}}'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal [], JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |pm| pm['node']['dbid'] }

    query = 'query CheckSearch { search(query: "{\"assigned_to\":[' + u2.id.to_s + ',' + u5.id.to_s + ']}") { id,medias(first:20){edges{node{dbid}}}}}'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal [], JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |pm| pm['node']['dbid'] }
  end

  test "should search by project group" do
    u = create_user is_admin: true
    t = create_team
    create_team_user user: u, team: t, role: 'admin'
    authenticate_with_user(u)

    pg = create_project_group team: t
    p1 = create_project team: t
    p1.project_group = pg
    p1.save!
    create_project_media project: p1
    p2 = create_project team: t
    p2.project_group = pg
    p2.save!
    create_project_media project: p2
    p3 = create_project team: t
    create_project_media project: p3

    query = 'query CheckSearch { search(query: "{}") { number_of_results } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal 3, JSON.parse(@response.body)['data']['search']['number_of_results']

    query = 'query CheckSearch { search(query: "{\"project_group_id\":' + pg.id.to_s + '}") { number_of_results } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal 2, JSON.parse(@response.body)['data']['search']['number_of_results']
  end

  test "should get OCR" do
    b = create_alegre_bot(name: 'alegre', login: 'alegre')
    b.approve!
    create_extracted_text_annotation_type
    Bot::Alegre.unstub(:request_api)
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      Sidekiq::Testing.fake! do
        WebMock.disable_net_connect! allow: /#{CheckConfig.get('elasticsearch_host')}|#{CheckConfig.get('storage_endpoint')}/
        WebMock.stub_request(:get, 'http://alegre/image/ocr/').with({ query: { url: "some/path" } }).to_return(body: { text: 'Foo bar' }.to_json)
        WebMock.stub_request(:get, 'http://alegre/text/similarity/')

        u = create_user
        t = create_team
        create_team_user user: u, team: t, role: 'admin'
        authenticate_with_user(u)

        Bot::Alegre.unstub(:media_file_url)
        pm = create_project_media team: t, media: create_uploaded_image
        Bot::Alegre.stubs(:media_file_url).with(pm).returns('some/path')

        query = 'mutation ocr { extractText(input: { clientMutationId: "1", id: "' + pm.graphql_id + '" }) { project_media { id } } }'
        post :create, params: { query: query, team: t.slug }
        assert_response :success

        extracted_text_annotation = pm.get_annotations('extracted_text').last
        assert_equal 'Foo bar', extracted_text_annotation.data['text']
        Bot::Alegre.unstub(:media_file_url)
      end
    end
  end

  test "should not get OCR" do
    u = create_user
    t = create_team private: true
    authenticate_with_user(u)

    pm = create_project_media team: t, media: create_uploaded_image

    query = 'mutation ocr { extractText(input: { clientMutationId: "1", id: "' + pm.graphql_id + '" }) { project_media { id } } }'
    post :create, params: { query: query, team: t.slug }

    assert_nil pm.get_annotations('extracted_text').last
  end

  test "should get cached values for list columns" do
    RequestStore.store[:skip_cached_field_update] = false
    t = create_team
    t.set_list_columns = ["updated_at_timestamp", "last_seen", "demand", "share_count", "folder", "linked_items_count", "suggestions_count", "type_of_media", "status", "created_at_timestamp", "report_status", "tags_as_sentence", "media_published_at", "comment_count", "reaction_count", "related_count"]
    t.save!
    5.times { create_project_media team: t }
    u = create_user is_admin: true
    create_team_user user: u, team: t, role: 'admin'
    authenticate_with_user(u)

    query = 'query CheckSearch { search(query: "{}") { medias(first: 5) { edges { node { list_columns_values } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success

    assert_queries(9, '=') do
      query = 'query CheckSearch { search(query: "{}") { medias(first: 5) { edges { node { list_columns_values } } } } }'
      post :create, params: { query: query, team: t.slug }
      assert_response :success
    end
  end
end
