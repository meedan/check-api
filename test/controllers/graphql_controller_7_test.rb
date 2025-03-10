require_relative '../test_helper'

class GraphqlController7Test < ActionController::TestCase
  def setup
    require 'sidekiq/testing'
    super
    TestDynamicAnnotationTables.load!
    @controller = Api::V1::GraphqlController.new
    RequestStore.store[:skip_cached_field_update] = false
    Sidekiq::Testing.fake!
    User.unstub(:current)
    Team.unstub(:current)
    User.current = nil
    Team.current = nil

    @t = create_team
    @u = create_user
    @tu = create_team_user team: @t, user: @u, role: 'admin'
    Sidekiq::Worker.drain_all
    sleep 1
    authenticate_with_user(@u)
  end

  def teardown
    super
    Sidekiq::Worker.drain_all
  end

  test "should search team sources by keyword" do
    t = create_team slug: 'sawy'
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    create_source team: t, name: 'keyword begining'
    create_source team: t, name: 'ending keyword'
    create_source team: t, name: 'in the KEYWORD middle'
    create_source team: t
    authenticate_with_user(u)
    query = 'query read { team(slug: "sawy") { sources_count, sources(first: 1000) { edges { node { dbid } } } } }'
    post :create, params: { query: query }
    assert_response :success
    edges = JSON.parse(@response.body)['data']['team']['sources']['edges']
    assert_equal 4, edges.length
    query = 'query read { team(slug: "sawy") { sources_count(keyword: "keyword"), sources(first: 1000, keyword: "keyword") { edges { node { dbid } } } } }'
    post :create, params: { query: query }
    assert_response :success
    edges = JSON.parse(@response.body)['data']['team']['sources']['edges']
    assert_equal 3, edges.length
  end

  test "should search team tag texts by keyword" do
    t = create_team slug: 'sawy'
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    create_tag_text team_id: t.id, text: 'keyword begining'
    create_tag_text team_id: t.id, text: 'ending keyword'
    create_tag_text team_id: t.id, text: 'in the KEYWORD middle'
    create_tag_text team_id: t.id
    authenticate_with_user(u)
    query = 'query read { team(slug: "sawy") { tag_texts_count, tag_texts(first: 1000) { edges { node { dbid } } } } }'
    post :create, params: { query: query }
    assert_response :success
    edges = JSON.parse(@response.body)['data']['team']['tag_texts']['edges']
    assert_equal 4, edges.length
    query = 'query read { team(slug: "sawy") { tag_texts_count(keyword: "keyword"), tag_texts(first: 1000, keyword: "keyword") { edges { node { dbid } } } } }'
    post :create, params: { query: query }
    assert_response :success
    edges = JSON.parse(@response.body)['data']['team']['tag_texts']['edges']
    assert_equal 3, edges.length
  end

  test "should update last_active_at from users before a graphql request" do
    assert_nil @u.last_active_at
    query = "query { user(id: #{@u.id}) { last_active_at } }"
    post :create, params: { query: query }
    assert_response :success
    assert_not_nil JSON.parse(@response.body)['data']['user']['last_active_at']
    assert_not_nil @u.reload.last_active_at
  end

  test "should not get Smooch integrations if not permissioned" do
    t = create_team private: true
    b = create_team_bot login: 'smooch', set_approved: true
    app_id = random_string
    tbi = create_team_bot_installation team_id: t.id, user_id: b.id, settings: { smooch_app_id: app_id }
    u = create_user
    t2 = create_team
    create_team_user user: u, team: t2, role: 'admin'

    query = "query { team(slug: \"#{t.slug}\") { team_bot_installations(first: 1) { edges { node { smooch_enabled_integrations } } } } }"
    post :create, params: { query: query }
    assert_error_message 'Not Found'

    authenticate_with_user(u)
    post :create, params: { query: query }
    assert_error_message 'Not Found'
  end

  test "should get Smooch integrations if permissioned" do
    t = create_team private: true
    b = create_team_bot login: 'smooch', set_approved: true
    app_id = random_string
    tbi = create_team_bot_installation team_id: t.id, user_id: b.id, settings: { smooch_app_id: app_id }
    u = create_user
    create_team_user user: u, team: t, role: 'admin'

    authenticate_with_user(u)
    query = "query { team(slug: \"#{t.slug}\") { team_bot_installations(first: 1) { edges { node { smooch_enabled_integrations } } } } }"
    post :create, params: { query: query }
    assert_not_nil json_response.dig('data', 'team', 'team_bot_installations', 'edges', 0, 'node', 'smooch_enabled_integrations')
  end

  test "should remove Smooch integration if permissioned" do
    t = create_team private: true
    b = create_team_bot login: 'smooch', set_approved: true
    app_id = random_string
    tbi = create_team_bot_installation team_id: t.id, user_id: b.id, settings: { smooch_app_id: app_id }
    u = create_user
    create_team_user user: u, team: t, role: 'admin'

    authenticate_with_user(u)
    query = "mutation { smoochBotRemoveIntegration(input: { clientMutationId: \"1\", team_bot_installation_id: \"#{tbi.graphql_id}\", integration_type: \"whatsapp\" }) { team_bot_installation { smooch_enabled_integrations } } }"
    post :create, params: { query: query }
    assert_not_nil json_response.dig('data', 'smoochBotRemoveIntegration', 'team_bot_installation', 'smooch_enabled_integrations')
  end

  test "should not remove Smooch integration if not permissioned" do
    t = create_team private: true
    b = create_team_bot login: 'smooch', set_approved: true
    app_id = random_string
    tbi = create_team_bot_installation team_id: t.id, user_id: b.id, settings: { smooch_app_id: app_id }
    u = create_user
    t2 = create_team
    create_team_user user: u, team: t2, role: 'admin'
    query = "mutation { smoochBotRemoveIntegration(input: { clientMutationId: \"1\", team_bot_installation_id: \"#{tbi.graphql_id}\", integration_type: \"whatsapp\" }) { team_bot_installation { smooch_enabled_integrations } } }"

    post :create, params: { query: query }
    assert_error_message 'Not Found'

    authenticate_with_user(u)
    post :create, params: { query: query }
    assert_error_message 'Not Found'
  end

  test "should add Smooch integration if permissioned" do
    SmoochApi::IntegrationApi.any_instance.stubs(:create_integration).returns(nil)
    t = create_team private: true
    b = create_team_bot login: 'smooch', set_approved: true
    app_id = random_string
    tbi = create_team_bot_installation team_id: t.id, user_id: b.id, settings: { smooch_app_id: app_id }
    u = create_user
    create_team_user user: u, team: t, role: 'admin'

    authenticate_with_user(u)
    query = 'mutation { smoochBotAddIntegration(input: { clientMutationId: "1", team_bot_installation_id: "' + tbi.graphql_id + '", integration_type: "messenger", params: "{\"token\":\"abc\"}" }) { team_bot_installation { smooch_enabled_integrations } } }'
    post :create, params: { query: query }
    assert_not_nil json_response.dig('data', 'smoochBotAddIntegration', 'team_bot_installation', 'smooch_enabled_integrations')
  end

  test "should not add Smooch integration if not permissioned" do
    t = create_team private: true
    b = create_team_bot login: 'smooch', set_approved: true
    app_id = random_string
    tbi = create_team_bot_installation team_id: t.id, user_id: b.id, settings: { smooch_app_id: app_id }
    u = create_user
    t2 = create_team
    create_team_user user: u, team: t2, role: 'admin'
    query = 'mutation { smoochBotAddIntegration(input: { clientMutationId: "1", team_bot_installation_id: "' + tbi.graphql_id + '", integration_type: "messenger", params: "{\"token\":\"abc\"}" }) { team_bot_installation { smooch_enabled_integrations } } }'

    post :create, params: { query: query }
    assert_error_message 'Not Found'

    authenticate_with_user(u)
    post :create, params: { query: query }
    assert_error_message 'Not Found'
  end

  test "should get saved search filters" do
    t = create_team
    ss = create_saved_search team: t, filters: { foo: 'bar' }
    f = create_feed team_id: t.id
    query = "query { team(slug: \"#{t.slug}\") { saved_searches(first: 1) { edges { node { filters, is_part_of_feeds, feeds(first: 1) { edges { node { dbid }}} } } } } }"
    post :create, params: { query: query }
    assert_response :success
    data = JSON.parse(@response.body).dig('data', 'team', 'saved_searches', 'edges', 0, 'node')
    assert_equal '{"foo":"bar"}', data['filters']
    assert_not data['is_part_of_feeds']
    assert_empty data['feeds']['edges']
    # add list to feed
    f.saved_search_id = ss.id
    f.skip_check_ability = true
    f.save!
    query = "query { team(slug: \"#{t.slug}\") { saved_searches(first: 1) { edges { node { filters, is_part_of_feeds, feeds(first: 1) { edges { node { dbid }}} } } } } }"
    post :create, params: { query: query }
    assert_response :success
    data = JSON.parse(@response.body).dig('data', 'team', 'saved_searches', 'edges', 0, 'node')
    assert data['is_part_of_feeds']
    assert_not_empty data['feeds']['edges']
  end

  test "should search by report fields" do
    setup_elasticsearch
    RequestStore.store[:skip_cached_field_update] = false
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    authenticate_with_user(u)

    # Published
    pm1 = create_project_media team: t, disable_es_callbacks: false
    r1 = publish_report(pm1)
    r1 = Dynamic.find(r1.id)
    r1.disable_es_callbacks = false
    r1.set_fields = { state: 'published' }.to_json
    r1.save!

    # Paused
    pm2 = create_project_media team: t, disable_es_callbacks: false
    r2 = publish_report(pm2, {}, nil, {'language' => 'fr'})
    r2 = Dynamic.find(r2.id)
    r2.disable_es_callbacks = false
    r2.set_fields = { state: 'paused' }.to_json
    r2.save!

    # Not published
    pm3 = create_project_media team: t, disable_es_callbacks: false

    # Search
    sleep 2
    query = 'query CheckSearch { search(query: "{\"report_status\":[\"published\"]}") { medias(first: 20) { edges { node { dbid } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal [pm1.id], JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |e| e['node']['dbid'] }

    # Verify filter by report published data
    query = 'query CheckSearch { search(query: "{\"range\": {\"report_published_at\":{\"condition\":\"less_than\",\"period\":\"1\",\"period_type\":\"y\"},\"timezone\":\"America/Bahia\"}}") { medias(first:20){edges{node{dbid}}}}}'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
    assert_equal [pm1.id, pm2.id], results.sort
    # filter by report language
    query = 'query CheckSearch { search(query: "{\"language_filter\":{\"report_language\":[\"fr\"]}}") { medias(first: 20) { edges { node { dbid } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal [pm2.id], JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |e| e['node']['dbid'] }
  end

  test "should filter by read in PostgreSQL" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t
    p = create_project team: t
    pm1 = create_project_media team: t, project: p, read: true
    pm2 = create_project_media team: t, project: p
    pm3 = create_project_media
    authenticate_with_user(u)

    query = 'query CheckSearch { search(query: "{\"read\":true, \"projects\":[' + p.id.to_s + ']}") { medias(first: 10) { edges { node { dbid } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal [pm1.id], JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }

    query = 'query CheckSearch { search(query: "{\"read\":false, \"projects\":[' + p.id.to_s + ']}") { medias(first: 10) { edges { node { dbid } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal [pm2.id], JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }

    query = 'query CheckSearch { search(query: "{\"projects\":[' + p.id.to_s + ']}") { medias(first: 10) { edges { node { dbid } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal [pm1.id, pm2.id].sort, JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }.sort
  end

  test "should set a project as default" do
    default_folder = @t.default_folder.id
    p = create_project team: @t
    query = "mutation { updateProject(input: { clientMutationId: \"1\", id: \"#{p.graphql_id}\", previous_default_project_id: #{default_folder},is_default: true}) { project { is_default }, previous_default_project { dbid, is_default } } }"
    post :create, params: { query: query, team: @t.slug }
    assert_response :success
    data = JSON.parse(@response.body)['data']['updateProject']
    assert data['project']['is_default']
    assert_equal default_folder, data['previous_default_project']['dbid']
    assert !data['previous_default_project']['is_default']
  end

  test "should create related project media for source" do
    t = create_team
    pm = create_project_media team: t
    u = create_user
    create_team_user user: u, team: t, role: 'admin'
    authenticate_with_user(u)
    query = 'mutation create { createSource(input: { name: "new source", slogan: "new source", clientMutationId: "1", add_to_project_media_id: ' + pm.id.to_s + ' }) { source { dbid } } }'
    post :create, params: { query: query, team: t }
    assert_response :success
    source = JSON.parse(@response.body)['data']['createSource']['source']
    assert_equal pm.reload.source_id, source['dbid']
  end

  test "should set and get Alegre Bot settings" do
    u = create_user
    t = create_team
    b = create_team_bot name: 'Alegre', login: 'alegre', set_approved: true
    tbi = create_team_bot_installation team_id: t.id, user_id: b.id
    tu = create_team_user team: t, user: u, role: 'admin'
    authenticate_with_user(u)
    query = 'mutation { updateTeamBotInstallation(input: { clientMutationId: "1", id: "' + tbi.graphql_id + '", json_settings: "{\"text_length_matching_threshold\":\"4\"}" }) { team_bot_installation { json_settings, lock_version } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    query = 'query { node(id: "' + tbi.graphql_id + '") { ... on TeamBotInstallation { alegre_settings } } }'
    post :create, params: { query: query, team: t.slug }
    alegre_settings =  JSON.parse(@response.body)['data']['node']['alegre_settings']
    assert_equal 4.0, alegre_settings['text_length_matching_threshold']
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

    query = 'query CheckSearch { search(query: "{}") { id,medias(first:20){edges{node{id,dbid,url,quote,published,updated_at,pusher_channel,domain,permissions,last_status,last_status_obj{id,dbid},media{url,quote,embed_path,thumbnail_path,id},user{name,source{dbid,accounts(first:10000){edges{node{url,id}}},id},id},team{slug,id},tags(first:10000){edges{node{tag,id}}}}}}}}'

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
    post :create, params: { query: "query { me { confirmed  } }" }
    assert_response :success
    data = JSON.parse(@response.body)['data']['me']
    assert data['confirmed']
  end

  test "should get timezone from header" do
    authenticate_with_user
    @request.headers['X-Timezone'] = 'America/Bahia'
    t = create_team slug: 'context'
    post :create, params: { query: 'query Query { me { name } }' }
    assert_equal 'America/Bahia', assigns(:context_timezone)
  end

  test "should return project medias with provided URL that user has access to" do
    l = create_valid_media
    u = create_user
    t = create_team
    t2 = create_team
    create_team_user team: t, user: u
    create_team_user team: t2, user: u
    authenticate_with_user(u)
    p1 = create_project team: t
    p2 = create_project team: t2
    pm1 = create_project_media project: p1, media: l
    pm2 = create_project_media project: p2, media: l
    pm3 = create_project_media media: l
    query = "query GetById { project_medias(url: \"#{l.url}\", first: 10000) { edges { node { dbid } } } }"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal [pm1.id], JSON.parse(@response.body)['data']['project_medias']['edges'].collect{ |x| x['node']['dbid'] }
  end

  test "should return project medias when provided URL is not normalized and it exists on db" do
    url = 'http://www.atarde.uol.com.br/bahia/salvador/noticias/2089363-comunidades-recebem-caminhao-da-biometria-para-regularizacao-eleitoral'
    url_normalized = 'http://www.atarde.com.br/bahia/salvador/noticias/2089363-comunidades-recebem-caminhao-da-biometria-para-regularizacao-eleitoral'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: '{"type":"media","data":{"url":"' + url_normalized + '","type":"item"}}')
    m = create_media url: url
    u = create_user
    t = create_team
    create_team_user team: t, user: u
    authenticate_with_user(u)
    p = create_project team: t
    pm = create_project_media project: p, media: m
    query = "query GetById { project_medias(url: \"#{url}\", first: 10000) { edges { node { dbid } } } }"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal [pm.id], JSON.parse(@response.body)['data']['project_medias']['edges'].collect{ |x| x['node']['dbid'] }
  end

  test "should upload files when calling a mutation" do
    u = create_user is_admin: true
    t = create_task
    f = Rack::Test::UploadedFile.new(File.join(Rails.root, 'test', 'data', 'rails.png'), 'image/png')
    authenticate_with_user(u)
    query = 'mutation { updateTask(input: { clientMutationId: "1", id: "' + t.graphql_id + '" }) { task { id } } }' # It could be any other mutation, not only updateTask
    post :create, params: { query: query, team: t.slug, file: { '0' => f } }
    assert_response :success
  end

  test "should get Smooch default messages" do
    t = create_team private: true
    t.set_languages = ['es', 'fr']
    t.save!
    b = create_team_bot login: 'smooch', set_approved: true
    app_id = random_string
    tbi = create_team_bot_installation team_id: t.id, user_id: b.id, settings: { smooch_app_id: app_id }
    u = create_user
    create_team_user user: u, team: t, role: 'admin'

    authenticate_with_user(u)
    query = "query { team(slug: \"#{t.slug}\") { team_bot_installations(first: 1) { edges { node { smooch_default_messages } } } } }"
    post :create, params: { query: query }
    assert_equal ['es', 'fr'].sort, json_response.dig('data', 'team', 'team_bot_installations', 'edges', 0, 'node', 'smooch_default_messages').keys
  end

  protected

  def assert_error_message(expected)
    assert_match /#{expected}/, JSON.parse(@response.body)['errors'][0]['message']
  end
end
