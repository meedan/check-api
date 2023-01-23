require_relative '../test_helper'

class GraphqlController7Test < ActionController::TestCase
  def setup
    require 'sidekiq/testing'
    super
    @controller = Api::V1::GraphqlController.new
    RequestStore.store[:skip_cached_field_update] = false
    Sidekiq::Testing.fake!
    User.unstub(:current)
    Team.unstub(:current)
    User.current = nil
    Team.current = nil
    create_verification_status_stuff
    @t = create_team
    @u = create_user
    @tu = create_team_user team: @t, user: @u, role: 'admin'
    @p1 = create_project team: @t
    @p2 = create_project team: @t
    @p3 = create_project team: @t
    @ps = [@p1, @p2, @p3]
    @pm1 = create_project_media team: @t, disable_es_callbacks: false, project: @p1
    @pm2 = create_project_media team: @t, disable_es_callbacks: false, project: @p2
    @pm3 = create_project_media team: @t, disable_es_callbacks: false, project: @p3
    Sidekiq::Worker.drain_all
    sleep 1
    @pms = [@pm1, @pm2, @pm3]
    @ids = @pms.map(&:graphql_id).to_json
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
    query = "query { team(slug: \"#{t.slug}\") { saved_searches(first: 1) { edges { node { filters } } } } }"
    post :create, params: { query: query }
    assert_equal '{"foo":"bar"}', JSON.parse(@response.body).dig('data', 'team', 'saved_searches', 'edges', 0, 'node', 'filters')
    assert_response :success
  end

  test "should search by report status" do
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
    r2 = publish_report(pm2)
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
    query = 'mutation { updateTeamBotInstallation(input: { clientMutationId: "1", id: "' + tbi.graphql_id + '", json_settings: "{\"text_length_matching_threshold\":\"4\"}" }) { team_bot_installation { json_settings } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    query = 'query { node(id: "' + tbi.graphql_id + '") { ... on TeamBotInstallation { alegre_settings } } }'
    post :create, params: { query: query, team: t.slug }
    alegre_settings =  JSON.parse(@response.body)['data']['node']['alegre_settings']
    assert_equal 4.0, alegre_settings['text_length_matching_threshold']
  end

  test "should not get Smooch Bot RSS feed preview if not owner" do
    u = create_user
    t = create_team
    b = create_team_bot name: 'Smooch', login: 'smooch', set_approved: true, set_events: [], set_request_url: "#{CheckConfig.get('checkdesk_base_url_private')}/api/bots/smooch"
    tbi = create_team_bot_installation team_id: t.id, user_id: b.id
    tu = create_team_user team: t, user: u, role: 'collaborator'
    authenticate_with_user(u)
    url = random_url
    output = "Foo\nhttp://foo\n\nBar\nhttp://bar"
    query = 'query { node(id: "' + tbi.graphql_id + '") { ... on TeamBotInstallation { smooch_bot_preview_rss_feed(rss_feed_url: "' + url + '", number_of_articles: 3) } } }'
    post :create, params: { query: query, team: t.slug }
    assert_match /Sorry/, @response.body
  end

  test "should not get Smooch Bot RSS feed preview if not member of the team" do
    u = create_user
    t = create_team
    b = create_team_bot name: 'Smooch', login: 'smooch', set_approved: true, set_events: [], set_request_url: "#{CheckConfig.get('checkdesk_base_url_private')}/api/bots/smooch"
    tbi = create_team_bot_installation team_id: t.id, user_id: b.id
    tu = create_team_user team: t, user: u, role: 'admin'
    authenticate_with_user(create_user)
    url = random_url
    output = "Foo\nhttp://foo\n\nBar\nhttp://bar"
    query = 'query { node(id: "' + tbi.graphql_id + '") { ... on TeamBotInstallation { smooch_bot_preview_rss_feed(rss_feed_url: "' + url + '", number_of_articles: 3) } } }'
    post :create, params: { query: query, team: t.slug }
    assert_match /Sorry/, @response.body
  end

  test "should update project media source" do
    t = create_team
    s = create_source team: t
    s2 = create_source team: t
    pm = create_project_media team: t, source_id: s.id, skip_autocreate_source: false
    pm2 = create_project_media team: t, source_id: s2.id, skip_autocreate_source: false
    assert_equal s.id, pm.source_id
    query = "mutation { updateProjectMedia(input: { clientMutationId: \"1\", id: \"#{pm.graphql_id}\", source_id: #{s2.id}}) { project_media { source { dbid, medias_count, medias(first: 10) { edges { node { dbid } } } } } } }"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    data = JSON.parse(@response.body)['data']['updateProjectMedia']['project_media']
    assert_equal s2.id, data['source']['dbid']
    assert_equal 2, data['source']['medias_count']
    assert_equal 2, data['source']['medias']['edges'].size
  end

  protected

  def assert_error_message(expected)
    assert_match /#{expected}/, JSON.parse(@response.body)['errors'][0]['message']
  end

  def search_results(filters)
    sleep 1
    $repository.search(query: { bool: { must: [{ term: filters }, { term: { team_id: @t.id } }] } }).results.collect{|i| i['annotated_id']}.sort
  end

  def assert_search_finds_all(filters)
    assert_equal @pms.map(&:id).sort, search_results(filters)
  end

  def assert_search_finds_none(filters)
    assert_equal [], search_results(filters)
  end
end
