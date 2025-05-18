require_relative '../test_helper'
require 'error_codes'

class GraphqlController10Test < ActionController::TestCase
  def setup
    @controller = Api::V1::GraphqlController.new
    @url = 'https://www.youtube.com/user/MeedanTube'
    require 'sidekiq/testing'
    Sidekiq::Testing.inline!
    super
    TestDynamicAnnotationTables.load!
    User.unstub(:current)
    Team.unstub(:current)
    User.current = nil
    Team.current = nil
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

    data = JSON.parse(response.body)['data']['destroyTeamBotInstallation']
    assert_equal [], t.reload.team_bots
    assert_equal tbi.graphql_id, data['deletedId']
  end

    test "should get task by id" do
    t = create_team
    pm = create_project_media team: t
    u = create_user
    create_team_user user: u, team: t, role: 'admin'
    authenticate_with_user(u)
    tk = create_task annotated: pm

    query = "query GetById { task(id: \"#{tk.id}\") { project_media { id }, options, responses { edges { node { id } } } } }"
    post :create, params: { query: query, team: t.slug }

    assert_response :success
    data = JSON.parse(response.body)['data']['task']

    assert_kind_of Array, data['options']
  end

  test "should get team tag_texts" do
    t = create_team
    pm = create_project_media team: t
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

  test "should get team users and bots" do
    t = create_team
    u = create_user
    u2 = create_user
    u3 = create_bot_user team: t
    create_team_user team: t, user: u, role: 'admin'
    create_team_user team: t, user: u2
    authenticate_with_user(u)
    query = "query GetById { team(id: \"#{t.id}\") { team_users { edges { node { user { dbid, source { medias(first: 1) { edges { node { id } } } } } } } } } }"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    data = JSON.parse(@response.body)['data']['team']['team_users']['edges']
    ids = data.collect{ |i| i['node']['user']['dbid'] }
    assert_equal 3, data.size
    assert_equal [u.id, u2.id, u3.id], ids.sort
    # Quey bot
    query = "query { me { dbid, get_send_email_notifications, get_send_successful_login_notifications, get_send_failed_login_notifications, source { medias(first: 1) { edges { node { id } } } }, annotations(first: 1) { edges { node { id } } }, team_users_count, team_users(first: 1) { edges { node { id } } }, bot { get_description, get_role, get_version, get_source_code_url } } }"
    post :create, params: { query: query }
    assert_response :success
  end

  test "should get team tasks" do
    t = create_team
    pm = create_project_media team: t
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
    pm = create_project_media team: t, user: u2
    t = create_task annotated: pm
    t.assign_user(u.id)
    query = "query GetById { project_media(ids: \"#{pm.id}\") { user { id } } }"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_not_nil JSON.parse(@response.body)['data']['project_media']['user']
  end

  test "should filter user assignments by team" do
    u = create_user
    t1 = create_team
    create_team_user team: t1, user: u
    pm1 = create_project_media team: t1
    tk1 = create_task annotated: pm1
    tk1.assign_user(u.id)
    t2 = create_team
    create_team_user team: t2, user: u
    pm2 = create_project_media team: t2
    tk2 = create_task annotated: pm2
    tk2.assign_user(u.id)
    authenticate_with_user(u)

    post :create, params: { query: "query { me { current_team { id }, user_teams, teams(first: 10) { edges { node { id } } }, assignments(first: 10000) { edges { node { dbid } } } } }", team: t1.slug }
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
    Sidekiq::Testing.inline! do
      u = create_user
      authenticate_with_user(u)
      t = create_team slug: 'team'
      create_team_user user: u, team: t

      pm1 = create_project_media disable_es_callbacks: false, team: t
      create_dynamic_annotation annotation_type: 'language', annotated: pm1, set_fields: { language: 'en' }.to_json, disable_es_callbacks: false
      pm2 = create_project_media disable_es_callbacks: false, team: t
      create_dynamic_annotation annotation_type: 'language', annotated: pm2, set_fields: { language: 'pt' }.to_json, disable_es_callbacks: false

      sleep 2
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
    pm1 = create_project_media team: t
    pm2 = create_project_media team: t
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
    pm1 = create_project_media team: t
    pm2 = create_project_media team: t
    r = create_relationship source_id: pm1.id, target_id: pm2.id
    assert_not_nil Relationship.where(id: r.id).last
    authenticate_with_user(u)
    query = 'mutation { destroyRelationship(input: { clientMutationId: "1", id: "' + r.graphql_id + '" }) { deletedId, source_project_media { id }, target_project_media { id } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal pm1.graphql_id, JSON.parse(@response.body)['data']['destroyRelationship']['source_project_media']['id']
    assert_equal pm2.graphql_id, JSON.parse(@response.body)['data']['destroyRelationship']['target_project_media']['id']
    assert_nil Relationship.where(id: r.id).last
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
      assert !q.include?('SELECT "versions".* FROM "versions" WHERE "versions"."id" = $1 LIMIT 1')
      assert q.include?("SELECT \"versions\".* FROM \"versions_partitions\".\"p#{t.id}\" \"versions\" WHERE \"versions\".\"id\" = $1 ORDER BY \"versions\".\"id\" DESC LIMIT $2")
    end
  end

  test "should empty trash" do
    Sidekiq::Testing.inline! do
      u = create_user
      team = create_team
      create_team_user team: team, user: u, role: 'admin'
      create_project_media archived: CheckArchivedFlags::FlagCodes::TRASHED, team: team
      assert_equal 1, team.reload.trash_count
      id = team.graphql_id
      authenticate_with_user(u)
      query = 'mutation { updateTeam(input: { clientMutationId: "1", id: "' + id + '", empty_trash: 1 }) { public_team { trash_count } } }'
      post :create, params: { query: query, team: team.slug }
      assert_response :success
      assert_equal 0, JSON.parse(@response.body)['data']['updateTeam']['public_team']['trash_count']
    end
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
    Sidekiq::Testing.inline! do
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
  end

  test "should search for tags using operator" do
    Sidekiq::Testing.inline! do
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
  end

  test "should search by user assigned to item" do
    Sidekiq::Testing.inline! do
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
  end

  test "should not access GraphQL mutation if not authenticated" do
    post :create, params: { query: 'mutation Test' }
    assert_response 401
  end

  test "should get project media assignments" do
    Sidekiq::Testing.inline! do
      u = create_user
      u2 = create_user
      t = create_team
      create_team_user user: u, team: t, status: 'member'
      create_team_user user: u2, team: t, status: 'member'
      pm1 = create_project_media team: t
      pm2 = create_project_media team: t
      pm3 = create_project_media team: t
      pm4 = create_project_media team: t
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
      post :create, params: { query: "query { me { assignments(first: 10) { edges { node { dbid, assignments(first: 10, user_id: #{u.id}, annotation_type: \"task\") { edges { node { dbid } } } } } } } }" }
      data = JSON.parse(@response.body)['data']['me']
      assert_equal [pm3.id, pm2.id, pm1.id], data['assignments']['edges'].collect{ |x| x['node']['dbid'] }
      assert_equal [t2.id], data['assignments']['edges'][0]['node']['assignments']['edges'].collect{ |x| x['node']['dbid'].to_i }
      assert_equal [], data['assignments']['edges'][1]['node']['assignments']['edges']
      assert_equal [t1.id], data['assignments']['edges'][2]['node']['assignments']['edges'].collect{ |x| x['node']['dbid'].to_i }
    end
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
    pm = create_project_media team: t
    query = 'mutation create { createTag(input: { clientMutationId: "1", tag: "egypt", annotated_type: "ProjectMedia", annotated_id: "' + pm.id.to_s + '"}) { tag { id } } }'
    post :create, params: { query: query }
    assert_response :success
    post :create, params: { query: query }
    assert_response 400
    assert_match /Tag already exists/, @response.body
  end

  test "should change status if collaborator" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'collaborator'
    create_team_user team: create_team, user: u, role: 'admin'
    m = create_valid_media
    pm = create_project_media team: t, media: m
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
    u = create_user
    u2 = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'collaborator'
    create_team_user team: t, user: u2, role: 'collaborator'
    create_team_user team: create_team, user: u, role: 'admin'
    m = create_valid_media
    pm = create_project_media team: t, media: m
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
    pm = create_project_media team: t
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
    pm = create_project_media team: t
    pm1 = create_project_media team: t, user: u
    create_relationship source_id: pm.id, target_id: pm1.id
    pm1.archived = CheckArchivedFlags::FlagCodes::TRASHED
    pm1.save!

    authenticate_with_user(u)

    query = "query GetById { project_media(ids: \"#{pm1.id}\") {permissions,source{permissions}}}"
    post :create, params: { query: query, team: t.slug }

    assert_response :success
  end

  test "should create dynamic annotation type" do
    t = create_team
    pm = create_project_media team: t
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

  test "should not search without permission" do
    t1 = create_team private: true
    t2 = create_team private: true
    t3 = create_team private: false
    u = create_user
    create_team_user team: t2, user: u
    pm1 = create_project_media team: t1
    pm2 = create_project_media team: t2
    pm3a = create_project_media team: t3
    pm3b = create_project_media team: t3
    query = 'query { search(query: "{}") { number_of_results, medias(first: 10) { edges { node { dbid, permissions } } } } }'

    # Anonymous user searching across all teams
    post :create, params: { query: query }
    assert_response :success
    assert_nil JSON.parse(@response.body)['data']['search']
    assert_not_nil JSON.parse(@response.body)['errors']

    # Anonymous user searching for a public team
    post :create, params: { query: query, team: t3.slug }
    assert_response :success
    assert_not_nil JSON.parse(@response.body)['data']['search']
    assert_nil JSON.parse(@response.body)['errors']

    # Anonymous user searching for a team
    post :create, params: { query: query, team: t1.slug }
    assert_response :success
    assert_nil JSON.parse(@response.body)['data']['search']
    assert_not_nil JSON.parse(@response.body)['errors']

    # Unpermissioned user searching across all teams
    authenticate_with_user(u)
    post :create, params: { query: query, team: t1.slug }
    assert_response :success
    assert_nil JSON.parse(@response.body)['data']['search']
    assert_not_nil JSON.parse(@response.body)['errors']

    # Unpermissioned user searching for a team
    authenticate_with_user(u)
    post :create, params: { query: query, team: t1.slug }
    assert_response :success
    assert_nil JSON.parse(@response.body)['data']['search']
    assert_not_nil JSON.parse(@response.body)['errors']

    # Permissioned user searching for a team
    authenticate_with_user(u)
    post :create, params: { query: query, team: t2.slug }
    assert_response :success
    assert_not_nil JSON.parse(@response.body)['data']['search']
    assert_nil JSON.parse(@response.body)['errors']
  end

  test "should filter by unmatched" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t
    pm = create_project_media team: t
    pm2 = create_project_media team: t, unmatched: 1
    authenticate_with_user(u)

    query = 'query CheckSearch { search(query: "{\"unmatched\":[1]}") { medias(first: 10) { edges { node { dbid } } } } }'
    post :create, params: { query: query, team: t.slug }

    assert_response :success
    assert_equal [pm2.id], JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
  end

  test "should send custom message to user" do
    Bot::Smooch.stubs(:send_message_to_user).returns(OpenStruct.new(code: 200)).twice
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'editor'
    pm = create_project_media team: t
    tr = create_tipline_request team_id: t.id, associated: pm, language: 'en', smooch_data: { authorId: '123', language: 'en', received: Time.now.to_f }
    assert_equal 0, tr.reload.first_manual_response_at
    assert_equal 0, tr.reload.last_manual_response_at
    authenticate_with_user(u)

    query = "mutation { sendTiplineMessage(input: { clientMutationId: \"1\", message: \"Hello\", inReplyToId: #{tr.id} }) { success } }"
    post :create, params: { query: query, team: t.slug }

    assert_response :success
    assert JSON.parse(@response.body)['data']['sendTiplineMessage']['success']
    first_manual_response_at = tr.reload.first_manual_response_at
    assert first_manual_response_at > 0
    assert_equal first_manual_response_at, tr.reload.last_manual_response_at

    sleep 1

    query = "mutation { sendTiplineMessage(input: { clientMutationId: \"1\", message: \"Bye\", inReplyToId: #{tr.id} }) { success } }"
    post :create, params: { query: query, team: t.slug }

    assert_response :success
    assert JSON.parse(@response.body)['data']['sendTiplineMessage']['success']
    assert_equal first_manual_response_at, tr.reload.first_manual_response_at
    assert tr.reload.last_manual_response_at > first_manual_response_at
  end

  test "should not send custom message to user" do
    Bot::Smooch.stubs(:send_message_to_user).returns(OpenStruct.new(code: 200)).never
    u = create_user
    t = create_team
    pm = create_project_media team: t
    tr = create_tipline_request team_id: t.id, associated: pm, language: 'en', smooch_data: { authorId: '123', language: 'en', received: Time.now.to_f }
    authenticate_with_user(u)

    query = "mutation { sendTiplineMessage(input: { clientMutationId: \"1\", message: \"Hello\", inReplyToId: #{tr.id} }) { success } }"
    post :create, params: { query: query, team: t.slug }

    assert_response :success
    assert !JSON.parse(@response.body)['data']['sendTiplineMessage']['success']
  end

  test "should add NLU keyword to tipline menu option" do
    SmoochNlu.any_instance.stubs(:enable!).once
    SmoochNlu.any_instance.stubs(:add_keyword_to_menu_option).once
    SmoochNlu.any_instance.stubs(:remove_keyword_from_menu_option).never
    u = create_user is_admin: true
    t = create_team
    b = create_team_bot name: 'Smooch', login: 'smooch', set_approved: true
    b.install_to!(t)
    authenticate_with_user(u)

    query = "mutation { addNluKeywordToTiplineMenu(input: { language: \"en\", menu: \"main\", menuOptionIndex: 0, keyword: \"Foo bar\" }) { success } }"
    post :create, params: { query: query, team: t.slug }

    assert_response :success
    assert JSON.parse(@response.body)['data']['addNluKeywordToTiplineMenu']['success']
  end

  test "should remove NLU keyword from tipline menu option" do
    SmoochNlu.any_instance.stubs(:enable!).once
    SmoochNlu.any_instance.stubs(:add_keyword_to_menu_option).never
    SmoochNlu.any_instance.stubs(:remove_keyword_from_menu_option).once
    u = create_user is_admin: true
    t = create_team
    b = create_team_bot name: 'Smooch', login: 'smooch', set_approved: true
    b.install_to!(t)
    authenticate_with_user(u)

    query = "mutation { removeNluKeywordFromTiplineMenu(input: { language: \"en\", menu: \"main\", menuOptionIndex: 0, keyword: \"Foo bar\" }) { success } }"
    post :create, params: { query: query, team: t.slug }

    assert_response :success
    assert JSON.parse(@response.body)['data']['removeNluKeywordFromTiplineMenu']['success']
  end

  test "should not change tipline menu option NLU keywords if it's not a super-admin" do
    SmoochNlu.any_instance.stubs(:enable!).never
    SmoochNlu.any_instance.stubs(:add_keyword_to_menu_option).never
    SmoochNlu.any_instance.stubs(:remove_keyword_from_menu_option).never
    u = create_user is_admin: false
    t = create_team
    b = create_team_bot name: 'Smooch', login: 'smooch', set_approved: true
    b.install_to!(t)
    authenticate_with_user(u)

    query = "mutation { addNluKeywordToTiplineMenu(input: { language: \"en\", menu: \"main\", menuOptionIndex: 0, keyword: \"Foo bar\" }) { success } }"
    post :create, params: { query: query, team: t.slug }

    assert_response :success
    assert !JSON.parse(@response.body)['data']['addNluKeywordToTiplineMenu']['success']
  end

  test "should not change tipline menu option NLU keywords if tipline is not installed" do
    SmoochNlu.any_instance.stubs(:enable!).never
    SmoochNlu.any_instance.stubs(:add_keyword_to_menu_option).never
    SmoochNlu.any_instance.stubs(:remove_keyword_from_menu_option).never
    u = create_user is_admin: true
    t = create_team
    authenticate_with_user(u)

    query = "mutation { addNluKeywordToTiplineMenu(input: { language: \"en\", menu: \"main\", menuOptionIndex: 0, keyword: \"Foo bar\" }) { success } }"
    post :create, params: { query: query, team: t.slug }

    assert_response :success
    assert !JSON.parse(@response.body)['data']['addNluKeywordToTiplineMenu']['success']
  end
end
