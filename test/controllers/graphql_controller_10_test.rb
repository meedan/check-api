require_relative '../test_helper'
require 'error_codes'

class GraphqlController10Test < ActionController::TestCase
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

    test "should get task by id" do
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p
    u = create_user
    create_team_user user: u, team: t, role: 'admin'
    authenticate_with_user(u)
    tk = create_task annotated: pm


    query = "query GetById { task(id: \"#{tk.id}\") { project_media { id }, options, responses { edges { node { id } } } } }"
    post :create, params: { query: query, team: t.slug }

    assert_response :success
    data = JSON.parse(@response.body)['data']['task']
    assert_kind_of Array, data['options']
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

    query = "query GetById { team(id: \"#{t.id}\") { team_tasks { edges { node { label, dbid, type, order, description, options, required, team_id, team { slug } } } } } }"
    post :create, params: { query: query, team: t.slug }

    assert_response :success
    data = JSON.parse(@response.body)['data']['team']
    assert_equal 3, data['team_tasks']['edges'][0]['node']['order']
    assert_equal tt.id, data['team_tasks']['edges'][0]['node']['dbid']
    assert_equal tt2.id, data['team_tasks']['edges'][1]['node']['dbid']
    assert_equal tt3.id, data['team_tasks']['edges'][2]['node']['dbid']
  end

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
    query = 'query CheckSearch { search(query: "{\"language\":[\"en\"]}") { id,medias(first:20){edges{node{dbid}}}}}';
    post :create, params: { query: query, team: 'team' }
    assert_response :success
    pmids = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |pm| pm['node']['dbid'] }
    assert_equal 1, pmids.size
    assert_equal pm1.id, pmids[0]

    query = 'query CheckSearch { search(query: "{\"language\":[\"pt\"]}") { id,medias(first:20){edges{node{dbid}}}}}';
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
    with_versioning do
      v = create_version
      t = Team.last
      id = Base64.encode64("Version/#{v.id}")
      q = assert_queries 10, '<=' do
        post :create, params: { query: "query Query { node(id: \"#{id}\") { id } }", team: t.slug }
      end
      assert !q.include?('SELECT  "versions".* FROM "versions" WHERE "versions"."id" = $1 LIMIT 1')
      assert q.include?("SELECT  \"versions\".* FROM \"versions_partitions\".\"p#{t.id}\" \"versions\" WHERE \"versions\".\"id\" = $1 ORDER BY \"versions\".\"id\" DESC LIMIT $2")
    end
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
    assert_response 401

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

  test "should avoid n+1 queries problem" do
    n = 2 # Number of media items to be created
    m = 2 # Number of annotations per media
    u = create_user
    authenticate_with_user(u)
    t = create_team slug: 'team'
    create_team_user user: u, team: t
    p = create_project team: t
    with_current_user_and_team(u, t) do
      n.times do
        pm = create_project_media project: p, disable_es_callbacks: false
        m.times { create_comment annotated: pm, annotator: u, disable_es_callbacks: false }
      end
    end
    sleep 4

    query = "query { search(query: \"{}\") { medias(first: 10000) { edges { node { dbid, media { dbid } } } } } }"

    # This number should be always CONSTANT regardless the number of medias and annotations above
    assert_queries (19), '<=' do
      post :create, params: { query: query, team: 'team' }
    end

    assert_response :success
    assert_equal n, JSON.parse(@response.body)['data']['search']['medias']['edges'].size
  end

  test "should get project information fast" do
    RequestStore.store[:skip_cached_field_update] = false
    n = 3 # Number of media items to be created
    m = 2 # Number of annotations per media (doesn't matter in this case because we use the cached count - using random values to make sure it remains consistent)
    u = create_user
    authenticate_with_user(u)
    t = create_team slug: 'team'
    create_team_task team_id: t.id
    create_tag_text team_id: t.id
    create_team_bot_installation team_id: t.id
    create_team_user user: u, team: t
    p = create_project team: t
    n.times do
      pm = create_project_media project: p, user: create_user, disable_es_callbacks: false
      s = create_source
      create_account_source source: s, disable_es_callbacks: false
      m.times { create_comment annotated: pm, annotator: create_user, disable_es_callbacks: false }
    end
    create_project_media project: p, user: u, disable_es_callbacks: false
    pm = create_project_media project: p, disable_es_callbacks: false
    pm.archived = CheckArchivedFlags::FlagCodes::TRASHED
    pm.save!
    sleep 10

    # Current search query used by the frontend
    query = %{query CheckSearch {
      search(query: "{}") {
        id
        pusher_channel
        number_of_results
        team {
          id
          dbid
          name
          slug
          verification_statuses
          pusher_channel
          dynamic_search_fields_json_schema
          rules_search_fields_json_schema
          medias_count
          permissions
          search_id
          list_columns
          team_tasks(first: 10000) {
            edges {
              node {
                id
                dbid
                fieldset
                label
                options
                type
              }
            }
          }
          tag_texts(first: 10000) {
            edges {
              node {
                text
              }
            }
          }
          projects(first: 10000) {
            edges {
              node {
                title
                dbid
                id
                description
              }
            }
          }
          users(first: 10000) {
            edges {
              node {
                id
                dbid
                name
              }
            }
          }
          check_search_trash {
            id
            number_of_results
          }
          check_search_unconfirmed {
            id
            number_of_results
          }
          public_team {
            id
            trash_count
            unconfirmed_count
          }
          search {
            id
            number_of_results
          }
          team_bot_installations(first: 10000) {
            edges {
              node {
                id
                team_bot: bot_user {
                  id
                  identifier
                }
              }
            }
          }
        }
        medias(first: 20) {
          edges {
            node {
              id
              dbid
              picture
              title
              description
              is_read
              list_columns_values
              team {
                verification_statuses
              }
            }
          }
        }
      }
    }}

    # Make sure we only run queries for the 20 first items
    assert_queries 100, '<=' do
      post :create, params: { query: query, team: 'team' }
    end

    assert_response :success
    assert_equal 4, JSON.parse(@response.body)['data']['search']['medias']['edges'].size
  end

    test "should delete custom status" do
    setup_elasticsearch
    RequestStore.store[:skip_cached_field_update] = false
    u = create_user
    authenticate_with_user(u)
    t = create_team slug: 'team'
    create_team_user user: u, team: t, role: 'admin'
    value = {
      label: 'Field label',
      active: 'id1',
      default: 'id1',
      statuses: [
        { id: 'id1', locales: { en: { label: 'Custom Status 1', description: 'The meaning of this status' } }, style: { color: 'red' } },
        { id: 'id2', locales: { en: { label: 'Custom Status 2', description: 'The meaning of that status' } }, style: { color: 'blue' } },
        { id: 'id3', locales: { en: { label: 'Custom Status 3', description: 'The meaning of that status' } }, style: { color: 'green' } }
      ]
    }
    t.set_media_verification_statuses(value)
    t.save!
    pm1 = create_project_media project: nil, team: t
    s = pm1.annotations.where(annotation_type: 'verification_status').last.load
    s.status = 'id1'
    s.disable_es_callbacks = false
    s.save!
    r1 = publish_report(pm1)
    pm2 = create_project_media project: nil, team: t
    s = pm2.annotations.where(annotation_type: 'verification_status').last.load
    s.status = 'id2'
    s.disable_es_callbacks = false
    s.save!
    r2 = publish_report(pm2)

    assert_equal 'id1', pm1.reload.last_status
    assert_equal 'id2', pm2.reload.last_status
    assert_queries(0, '=') do
      assert_equal 'id1', pm1.status
      assert_equal 'id2', pm2.status
    end
    assert_not_equal [], t.reload.get_media_verification_statuses[:statuses].select{ |s| s[:id] == 'id2' }
    sleep 5
    assert_equal [pm2.id], CheckSearch.new({ verification_status: ['id2'] }.to_json, nil, t.id).medias.map(&:id)
    assert_equal [], CheckSearch.new({ verification_status: ['id3'] }.to_json, nil, t.id).medias.map(&:id)
    assert_equal 'published', r1.reload.get_field_value('state')
    assert_equal 'published', r2.reload.get_field_value('state')
    assert_not_equal 'red', r1.reload.report_design_field_value('theme_color')
    assert_not_equal 'blue', r2.reload.report_design_field_value('theme_color')
    assert_not_equal 'Custom Status 1', r1.reload.report_design_field_value('status_label')
    assert_not_equal 'Custom Status 3', r2.reload.report_design_field_value('status_label')

    query = "mutation deleteTeamStatus { deleteTeamStatus(input: { clientMutationId: \"1\", team_id: \"#{t.graphql_id}\", status_id: \"id2\", fallback_status_id: \"id3\" }) { team { id, verification_statuses(items_count_for_status: \"id3\") } } }"
    post :create, params: { query: query, team: 'team' }
    assert_response :success

    assert_equal 'id1', pm1.reload.last_status
    assert_equal 'id3', pm2.reload.last_status
    assert_queries(0, '=') do
      assert_equal 'id1', pm1.status
      assert_equal 'id3', pm2.status
    end
    sleep 5
    assert_equal [], CheckSearch.new({ verification_status: ['id2'] }.to_json, nil, t.id).medias.map(&:id)
    assert_equal [pm2.id], CheckSearch.new({ verification_status: ['id3'] }.to_json, nil, t.id).medias.map(&:id)
    assert_equal [], t.reload.get_media_verification_statuses[:statuses].select{ |s| s[:id] == 'id2' }
    assert_equal 'published', r1.reload.get_field_value('state')
    assert_equal 'paused', r2.reload.get_field_value('state')
    assert_not_equal 'red', r1.reload.report_design_field_value('theme_color')
    assert_equal 'green', r2.reload.report_design_field_value('theme_color')
    assert_not_equal 'Custom Status 1', r1.reload.report_design_field_value('status_label')
    assert_equal 'Custom Status 3', r2.reload.report_design_field_value('status_label')
  end

  test "should access GraphQL query if not authenticated" do
    post :create, params: { query: 'query Query { about { name, version } }' }
    assert_response 200
  end

  test "should not access GraphQL mutation if not authenticated" do
    post :create, params: { query: 'mutation Test' }
    assert_response 401
  end

  test "should access About if not authenticated" do
    post :create, params: { query: 'query About { about { name, version } }' }
    assert_response :success
  end

  test "should access GraphQL if authenticated" do
    authenticate_with_user
    post :create, params: { query: 'query Query { about { name, version, upload_max_size, upload_extensions, upload_max_dimensions, upload_min_dimensions, terms_last_updated_at } }', variables: '{"foo":"bar"}' }
    assert_response :success
    data = JSON.parse(@response.body)['data']['about']
    assert_kind_of String, data['name']
    assert_kind_of String, data['version']
  end

  test "should not access GraphQL if authenticated as a bot" do
    authenticate_with_user(create_bot_user)
    post :create, params: { query: 'query Query { about { name, version, upload_max_size, upload_extensions, upload_max_dimensions, upload_min_dimensions } }', variables: '{"foo":"bar"}' }
    assert_response 401
  end

  test "should get node from global id" do
    authenticate_with_user
    id = Base64.encode64('About/1')
    post :create, params: { query: "query Query { node(id: \"#{id}\") { id } }" }
    assert_equal id, JSON.parse(@response.body)['data']['node']['id']
  end

  test "should get current user" do
    u = create_user name: 'Test User'
    authenticate_with_user(u)
    post :create, params: { query: 'query Query { me { source_id, token, is_admin, current_project { id }, name, bot { id } } }' }
    assert_response :success
    data = JSON.parse(@response.body)['data']['me']
    assert_equal 'Test User', data['name']
  end

  test "should get current user if logged in with token" do
    u = create_user name: 'Test User'
    authenticate_with_user_token(u.token)
    post :create, params: { query: 'query Query { me { name } }' }
    assert_response :success
    data = JSON.parse(@response.body)['data']['me']
    assert_equal 'Test User', data['name']
  end

  test "should return 404 if object does not exist" do
    authenticate_with_user
    post :create, params: { query: 'query GetById { project_media(ids: "99999,99999") { id } }' }
    assert_response :success
  end

  test "should set context team" do
    authenticate_with_user
    t = create_team slug: 'context'
    post :create, params: { query: 'query Query { about { name, version } }', team: 'context' }
    assert_equal t, assigns(:context_team)
  end

  test "should get team by context" do
    authenticate_with_user
    t = create_team slug: 'context', name: 'Context Team'
    post :create, params: { query: 'query Team { team { name } }', team: 'context' }
    assert_response :success
    assert_equal 'Context Team', JSON.parse(@response.body)['data']['team']['name']
  end

  test "should get public team by context" do
    authenticate_with_user
    t1 = create_team slug: 'team1', name: 'Team 1'
    t2 = create_team slug: 'team2', name: 'Team 2'
    post :create, params: { query: 'query PublicTeam { public_team { name } }', team: 'team1' }
    assert_response :success
    assert_equal 'Team 1', JSON.parse(@response.body)['data']['public_team']['name']
  end

  test "should get public team by slug" do
    authenticate_with_user
    t1 = create_team slug: 'team1', name: 'Team 1'
    t2 = create_team slug: 'team2', name: 'Team 2'
    post :create, params: { query: 'query PublicTeam { public_team(slug: "team2") { name } }', team: 'team1' }
    assert_response :success
    assert_equal 'Team 2', JSON.parse(@response.body)['data']['public_team']['name']
  end

  test "should not get team by context" do
    authenticate_with_user
    Team.delete_all
    post :create, params: { query: 'query Team { team { name } }', team: 'test' }
    assert_response :success
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

    post :create, params: { query: 'query Query { me { name } }', team: 'team1' }
    assert_response :success
    assert_equal t1, u.reload.current_team

    post :create, params: { query: 'query Query { me { name } }', team: 'team2' }
    assert_response :success
    assert_equal t1, u.reload.current_team

    post :create, params: { query: 'query Query { me { name } }', team: 'team3' }
    assert_response :success
    assert_equal t3, u.reload.current_team
  end

  test "should return 404 if public team does not exist" do
    authenticate_with_user
    Team.delete_all
    post :create, params: { query: 'query PublicTeam { public_team { name } }', team: 'foo' }
    assert_response :success
  end

  test "should return null if public team is not found" do
    authenticate_with_user
    Team.delete_all
    post :create, params: { query: 'query FindPublicTeam { find_public_team(slug: "foo") { name } }', team: 'foo' }
    assert_response :success
    assert_nil JSON.parse(@response.body)['data']['find_public_team']
  end

  test "should get team by slug" do
    authenticate_with_user
    t = create_team slug: 'context', name: 'Context Team'
    post :create, params: { query: 'query Team { team(slug: "context") { name } }' }
    assert_response :success
    assert_equal 'Context Team', JSON.parse(@response.body)['data']['team']['name']
  end

end