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

  test "should get listed bots, current user and current team" do
    BotUser.delete_all
    authenticate_with_user
    tb1 = create_team_bot set_listed: true
    tb2 = create_team_bot set_listed: false
    query = "query read { root { current_user { id }, current_team { id }, team_bots_listed { edges { node { dbid } } } } }"
    post :create, params: { query: query }
    edges = JSON.parse(@response.body)['data']['root']['team_bots_listed']['edges']
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

  test "should get team task" do
    t = create_team
    t2 = create_team
    u = create_user
    create_team_user user: u, team: t, role: 'admin'
    authenticate_with_user(u)
    tt = create_team_task team_id: t.id, order: 3

    query = "query GetById { team(id: \"#{t.id}\") { team_task(dbid: #{tt.id}) { dbid } } }"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal tt.id, JSON.parse(@response.body)['data']['team']['team_task']['dbid']

    query = "query GetById { team(id: \"#{t2.id}\") { team_task(dbid: #{tt.id}) { dbid } } }"
    post :create, params: { query: query, team: t2.slug }
    assert_response :success
    assert_nil JSON.parse(@response.body)['data']['team']['team_task']
  end

  test "should return suggested similar items count" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'admin'
    authenticate_with_user(u)
    p = create_project team: t
    p1 = create_project_media project: p
    p1a = create_project_media project: p
    p1b = create_project_media project: p
    create_relationship source_id: p1.id, target_id: p1a.id, relationship_type: Relationship.suggested_type
    create_relationship source_id: p1.id, target_id: p1b.id, relationship_type: Relationship.suggested_type
    p2 = create_project_media project: p
    p2a = create_project_media project: p
    p2b = create_project_media project: p
    create_relationship source_id: p2.id, target_id: p2a.id
    create_relationship source_id: p2.id, target_id: p2b.id, relationship_type: Relationship.suggested_type
    post :create, params: { query: "query { project_media(ids: \"#{p1.id},#{p.id}\") { suggested_similar_items_count } }", team: t.slug }; false
    assert_equal 2, JSON.parse(@response.body)['data']['project_media']['suggested_similar_items_count']
  end

  test "should return confirmed similar items count" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'admin'
    authenticate_with_user(u)
    p = create_project team: t
    p1 = create_project_media project: p
    p1a = create_project_media project: p
    p1b = create_project_media project: p
    create_relationship source_id: p1.id, target_id: p1a.id, relationship_type: Relationship.confirmed_type
    create_relationship source_id: p1.id, target_id: p1b.id, relationship_type: Relationship.confirmed_type
    p2 = create_project_media project: p
    p2a = create_project_media project: p
    p2b = create_project_media project: p
    create_relationship source_id: p2.id, target_id: p2a.id
    create_relationship source_id: p2.id, target_id: p2b.id, relationship_type: Relationship.confirmed_type
    post :create, params: { query: "query { project_media(ids: \"#{p1.id},#{p.id}\") { confirmed_similar_items_count } }", team: t.slug }; false
    assert_equal 2, JSON.parse(@response.body)['data']['project_media']['confirmed_similar_items_count']
  end

  test "should sort search by metadata value where items without metadata value show first on ascending order" do
    RequestStore.store[:skip_cached_field_update] = false
    at = create_annotation_type annotation_type: 'task_response_free_text'
    create_field_instance annotation_type_object: at, name: 'response_free_text'
    u = create_user is_admin: true
    t = create_team
    create_team_user team: t, user: u
    tt1 = create_team_task fieldset: 'metadata', team_id: t.id
    tt2 = create_team_task fieldset: 'metadata', team_id: t.id
    t.list_columns = ["task_value_#{tt1.id}", "task_value_#{tt2.id}"]
    t.save!
    pm1 = create_project_media team: t, disable_es_callbacks: false
    pm2 = create_project_media team: t, disable_es_callbacks: false
    pm3 = create_project_media team: t, disable_es_callbacks: false
    pm4 = create_project_media team: t, disable_es_callbacks: false

    m = pm1.get_annotations('task').map(&:load).select{ |t| t.team_task_id == tt1.id }.last
    m.disable_es_callbacks = false
    m.response = { annotation_type: 'task_response_free_text', set_fields: { response_free_text: 'B' }.to_json }.to_json
    m.save!
    m = pm3.get_annotations('task').map(&:load).select{ |t| t.team_task_id == tt1.id }.last
    m.disable_es_callbacks = false
    m.response = { annotation_type: 'task_response_free_text', set_fields: { response_free_text: 'A' }.to_json }.to_json
    m.save!
    m = pm4.get_annotations('task').map(&:load).select{ |t| t.team_task_id == tt1.id }.last
    m.disable_es_callbacks = false
    m.response = { annotation_type: 'task_response_free_text', set_fields: { response_free_text: 'C' }.to_json }.to_json
    m.save!
    sleep 5

    m = pm1.get_annotations('task').map(&:load).select{ |t| t.team_task_id == tt2.id }.last
    m.disable_es_callbacks = false
    m.response = { annotation_type: 'task_response_free_text', set_fields: { response_free_text: 'C' }.to_json }.to_json
    m.save!
    m = pm2.get_annotations('task').map(&:load).select{ |t| t.team_task_id == tt2.id }.last
    m.disable_es_callbacks = false
    m.response = { annotation_type: 'task_response_free_text', set_fields: { response_free_text: 'B' }.to_json }.to_json
    m.save!
    m = pm4.get_annotations('task').map(&:load).select{ |t| t.team_task_id == tt2.id }.last
    m.disable_es_callbacks = false
    m.response = { annotation_type: 'task_response_free_text', set_fields: { response_free_text: 'A' }.to_json }.to_json
    m.save!
    sleep 5

    authenticate_with_user(u)

    query = 'query CheckSearch { search(query: "{\"sort\":\"task_value_' + tt1.id.to_s + '\",\"sort_type\":\"asc\"}") {medias(first:20){edges{node{dbid}}}}}'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
    assert_equal 4, results.size
    assert_equal pm2.id, results.first

    query = 'query CheckSearch { search(query: "{\"sort\":\"task_value_' + tt2.id.to_s + '\",\"sort_type\":\"asc\"}") {medias(first:20){edges{node{dbid}}}}}'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
    assert_equal 4, results.size
    assert_equal pm3.id, results.first

    query = 'query CheckSearch { search(query: "{\"sort\":\"task_value_' + tt1.id.to_s + '\",\"sort_type\":\"desc\"}") {medias(first:20){edges{node{dbid}}}}}'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
    assert_equal 4, results.size
    assert_equal pm2.id, results.last

    query = 'query CheckSearch { search(query: "{\"sort\":\"task_value_' + tt2.id.to_s + '\",\"sort_type\":\"desc\"}") {medias(first:20){edges{node{dbid}}}}}'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
    assert_equal 4, results.size
    assert_equal pm3.id, results.last
  end

  test "should load permissions for GraphQL" do
    pm1 = create_project_media
    pm2 = create_project_media
    User.current = create_user
    PermissionsLoader.any_instance.stubs(:fulfill).returns(nil)
    assert_kind_of Array, PermissionsLoader.new(nil).perform([pm1.id, pm2.id])
    PermissionsLoader.any_instance.unstub(:fulfill)
    User.current = nil
  end

  test "should not get Smooch Bot RSS feed preview if not logged in" do
    u = create_user
    t = create_team
    b = create_team_bot name: 'Smooch', login: 'smooch', set_approved: true, set_events: [], set_request_url: "#{CheckConfig.get('checkdesk_base_url_private')}/api/bots/smooch"
    tbi = create_team_bot_installation team_id: t.id, user_id: b.id
    tu = create_team_user team: t, user: u, role: 'admin'
    url = random_url
    output = "Foo\nhttp://foo\n\nBar\nhttp://bar"
    query = 'query { node(id: "' + tbi.graphql_id + '") { ... on TeamBotInstallation { smooch_bot_preview_rss_feed(rss_feed_url: "' + url + '", number_of_articles: 3) } } }'
    post :create, params: { query: query, team: t.slug }
    assert_match /Sorry/, @response.body
  end

  test "should return similar items" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'admin'
    authenticate_with_user(u)
    p = create_project team: t
    p1 = create_project_media project: p
    p1a = create_project_media project: p
    p1b = create_project_media project: p
    create_relationship source_id: p1.id, target_id: p1a.id, relationship_type: Relationship.suggested_type
    create_relationship source_id: p1.id, target_id: p1b.id, relationship_type: Relationship.suggested_type
    p2 = create_project_media project: p
    p2a = create_project_media project: p
    p2b = create_project_media project: p
    create_relationship source_id: p2.id, target_id: p2a.id
    create_relationship source_id: p2.id, target_id: p2b.id, relationship_type: Relationship.suggested_type
    post :create, params: { query: "query { project_media(ids: \"#{p1.id},#{p.id}\") { is_main, is_secondary, is_confirmed_similar_to_another_item, suggested_main_item { id }, confirmed_main_item { id }, default_relationships_count, default_relationships(first: 10000) { edges { node { dbid } } }, confirmed_similar_relationships(first: 10000) { edges { node { dbid } } }, suggested_similar_relationships(first: 10000) { edges { node { target { dbid } } } } } }", team: t.slug }
    assert_equal [p1a.id, p1b.id].sort, JSON.parse(@response.body)['data']['project_media']['suggested_similar_relationships']['edges'].collect{ |x| x['node']['target']['dbid'] }.sort
  end

  test "should get Smooch Bot RSS feed preview if has permissions" do
    rss = %{
      <rss xmlns:atom="http://www.w3.org/2005/Atom" version="2.0">
        <channel>
          <title>Test</title>
          <link>http://test.com/rss.xml</link>
          <description>Test</description>
          <language>en</language>
          <lastBuildDate>Fri, 09 Oct 2020 18:00:48 GMT</lastBuildDate>
          <managingEditor>test@test.com (editors)</managingEditor>
          <item>
            <title>Foo</title>
            <description>This is the description.</description>
            <pubDate>Wed, 11 Apr 2018 15:25:00 GMT</pubDate>
            <link>http://foo</link>
          </item>
          <item>
            <title>Bar</title>
            <description>This is the description.</description>
            <pubDate>Wed, 10 Apr 2018 15:25:00 GMT</pubDate>
            <link>http://bar</link>
          </item>
        </channel>
      </rss>
    }
    u = create_user
    t = create_team
    b = create_team_bot name: 'Smooch', login: 'smooch', set_approved: true, set_events: [], set_request_url: "#{CheckConfig.get('checkdesk_base_url_private')}/api/bots/smooch"
    tbi = create_team_bot_installation team_id: t.id, user_id: b.id
    tu = create_team_user team: t, user: u, role: 'admin'
    authenticate_with_user(u)
    url = random_url
    WebMock.stub_request(:get, url).to_return(status: 200, body: rss)
    output = "Foo\nhttp://foo\n\nBar\nhttp://bar"
    query = 'query { node(id: "' + tbi.graphql_id + '") { ... on TeamBotInstallation { smooch_bot_preview_rss_feed(rss_feed_url: "' + url + '", number_of_articles: 3) } } }'
    post :create, params: { query: query, team: t.slug }
    assert_no_match /Sorry/, @response.body
    assert_equal output, JSON.parse(@response.body)['data']['node']['smooch_bot_preview_rss_feed']
  end

  test "should get item tasks by fieldset" do
    u = create_user is_admin: true
    t = create_team
    pm = create_project_media team: t
    t1 = create_task annotated: pm, fieldset: 'tasks'
    t2 = create_task annotated: pm, fieldset: 'metadata'
    ids = [pm.id, nil, t.id].join(',')
    authenticate_with_user(u)

    query = 'query { project_media(ids: "' + ids + '") { tasks(fieldset: "tasks", first: 1000) { edges { node { dbid } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal t1.id, JSON.parse(@response.body)['data']['project_media']['tasks']['edges'][0]['node']['dbid'].to_i

    query = 'query { project_media(ids: "' + ids + '") { tasks(fieldset: "metadata", first: 1000) { edges { node { dbid } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal t2.id, JSON.parse(@response.body)['data']['project_media']['tasks']['edges'][0]['node']['dbid'].to_i
    s = create_source team: t
    t3 = create_task annotated: s, fieldset: 'metadata'
    query = 'query { source(id: "' + s.id.to_s + '") { tasks(fieldset: "metadata", first: 1000) { edges { node { dbid } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal t3.id, JSON.parse(@response.body)['data']['source']['tasks']['edges'][0]['node']['dbid'].to_i
  end

  test "should get team tasks by fieldset" do
    u = create_user is_admin: true
    t = create_team
    t1 = create_team_task team_id: t.id, fieldset: 'tasks'
    t2 = create_team_task team_id: t.id, fieldset: 'metadata'
    authenticate_with_user(u)

    query = 'query { team { team_tasks(fieldset: "tasks", first: 1000) { edges { node { dbid } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal t1.id, JSON.parse(@response.body)['data']['team']['team_tasks']['edges'][0]['node']['dbid'].to_i

    query = 'query { team { team_tasks(fieldset: "metadata", first: 1000) { edges { node { dbid } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal t2.id, JSON.parse(@response.body)['data']['team']['team_tasks']['edges'][0]['node']['dbid'].to_i
  end

  test "should update task options" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'admin'
    tt = create_team_task team_id: t.id, label: 'Select one', type: 'single_choice', options: ['ans_a', 'ans_b', 'ans_c']
    pm = create_project_media team: t
    authenticate_with_user(u)
    query = 'mutation { updateTeamTask(input: { clientMutationId: "1", id: "' + tt.graphql_id + '", label: "Select only one", json_options: "[ \"bli\", \"blo\", \"bla\" ]", options_diff: "{ \"deleted\": [\"ans_c\"], \"changed\": { \"ans_a\": \"bli\", \"ans_b\": \"blo\" }, \"added\": \"bla\" }" }) { team_task { label } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal 'Select only one', tt.reload.label
    assert_equal ['bli', 'blo', 'bla'], tt.options
  end
  
  test "should get team fieldsets" do
    u = create_user is_admin: true
    authenticate_with_user(u)
    t = create_team
    query = 'query { team { get_fieldsets } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_kind_of Array, JSON.parse(@response.body)['data']['team']['get_fieldsets']
  end

  test "should get number of results without similar items" do
    u = create_user
    authenticate_with_user(u)
    t = create_team slug: 'team'
    create_team_user user: u, team: t
    p = create_project team: t
    pm1 = create_project_media project: p, quote: 'Test 1 Bar', disable_es_callbacks: false
    pm2 = create_project_media project: p, quote: 'Test 2 Foo', disable_es_callbacks: false
    create_relationship source_id: pm1.id, target_id: pm2.id, relationship_type: Relationship.confirmed_type, disable_es_callbacks: false
    pm3 = create_project_media project: p, quote: 'Test 3 Bar', disable_es_callbacks: false
    pm4 = create_project_media project: p, quote: 'Test 4 Foo', disable_es_callbacks: false
    create_relationship source_id: pm3.id, target_id: pm4.id, relationship_type: Relationship.confirmed_type, disable_es_callbacks: false
    sleep 1

    query = 'query CheckSearch { search(query: "{\"keyword\":\"Test\"}") { number_of_results } }' 
    post :create, params: { query: query, team: 'team' }
    assert_response :success
    assert_equal 2, JSON.parse(@response.body)['data']['search']['number_of_results']

    query = 'query CheckSearch { search(query: "{\"keyword\":\"Test\",\"show_similar\":false}") { number_of_results } }' 
    post :create, params: { query: query, team: 'team' }
    assert_response :success
    assert_equal 2, JSON.parse(@response.body)['data']['search']['number_of_results']

    query = 'query CheckSearch { search(query: "{\"keyword\":\"Test\",\"show_similar\":true}") { number_of_results } }' 
    post :create, params: { query: query, team: 'team' }
    assert_response :success
    assert_equal 4, JSON.parse(@response.body)['data']['search']['number_of_results']

    query = 'query CheckSearch { search(query: "{\"keyword\":\"Foo\",\"show_similar\":false}") { number_of_results } }' 
    post :create, params: { query: query, team: 'team' }
    assert_response :success
    assert_equal 2, JSON.parse(@response.body)['data']['search']['number_of_results']
  end

  test "should reload mutations" do
    assert_nothing_raised do
      RelayOnRailsSchema.reload_mutations!
    end
  end

  test "should replace blank project media by another" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'admin'
    old = create_project_media team: t, media: Blank.create!
    r = publish_report(old)
    new = create_project_media team: t
    authenticate_with_user(u)

    query = 'mutation { replaceProjectMedia(input: { clientMutationId: "1", project_media_to_be_replaced_id: "' + old.graphql_id + '", new_project_media_id: "' + new.graphql_id + '" }) { old_project_media_deleted_id, new_project_media { dbid } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    data = JSON.parse(@response.body)['data']['replaceProjectMedia']
    assert_equal old.graphql_id, data['old_project_media_deleted_id']
    assert_equal new.id, data['new_project_media']['dbid']
    assert_nil ProjectMedia.find_by_id(old.id)
    assert_equal r, new.get_dynamic_annotation('report_design')
  end

  test "should set and get Slack settings for team" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'admin'
    authenticate_with_user(u)
    query = 'mutation { updateTeam(input: { clientMutationId: "1", id: "' + t.graphql_id + '", slack_notifications: "[{\"label\":\"not #1\",\"event_type\":\"any_activity\",\"slack_channel\":\"#list\"}]" }) { team { get_slack_notifications } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_not_nil JSON.parse(@response.body)['data']['updateTeam']['team']['get_slack_notifications']
  end

  test "should set and get special list filters for team" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'admin'
    authenticate_with_user(u)
    # Tipline list
    query = 'mutation { updateTeam(input: { clientMutationId: "1", id: "' + t.graphql_id + '", tipline_inbox_filters: "{\"read\":[\"0\"],\"projects\":[\"-1\"]}" }) { team { get_tipline_inbox_filters } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_not_nil JSON.parse(@response.body)['data']['updateTeam']['team']['get_tipline_inbox_filters']
    # Suggested match list
    query = 'mutation { updateTeam(input: { clientMutationId: "1", id: "' + t.graphql_id + '", suggested_matches_filters: "{\"projects\":[\"-1\"],\"suggestions_count\":{\"min\":5,\"max\":10}}" }) { team { get_suggested_matches_filters } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_not_nil JSON.parse(@response.body)['data']['updateTeam']['team']['get_suggested_matches_filters']
  end
end
