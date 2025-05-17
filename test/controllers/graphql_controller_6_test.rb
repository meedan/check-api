require_relative '../test_helper'

class GraphqlController6Test < ActionController::TestCase
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

  test "should get a single bot installation" do
    t = create_team private: true
    b = create_team_bot login: 'smooch', set_approved: true
    app_id = random_string
    tbi = create_team_bot_installation team_id: t.id, user_id: b.id, settings: { smooch_app_id: app_id }
    u = create_user
    create_team_user user: u, team: t, role: 'admin'

    authenticate_with_user(u)
    query = "query { team(slug: \"#{t.slug}\") { team_bot_installation(bot_identifier: \"smooch\") { smooch_enabled_integrations(force: true) } } }"
    post :create, params: { query: query }
    assert_not_nil json_response.dig('data', 'team', 'team_bot_installation', 'smooch_enabled_integrations')
  end

  test "should search using OR or AND" do
    setup_elasticsearch
    RequestStore.store[:skip_cached_field_update] = false
    t = create_team
    u = create_user
    u2 = create_user
    create_team_user team: t, user: u, role: 'admin'
    authenticate_with_user(u)
    pm1 = create_project_media team: t, user: u, read: true, disable_es_callbacks: false
    pm2 = create_project_media team: t, user: u2, read: false, disable_es_callbacks: false
    # PG
    query = 'query CheckSearch { search(query: "{\"operator\":\"AND\",\"read\":true,\"users\":[' + u2.id.to_s + ']}") { medias(first: 20) { edges { node { dbid } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal [], JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |e| e['node']['dbid'] }
    query = 'query CheckSearch { search(query: "{\"operator\":\"OR\",\"read\":true,\"users\":[' + u2.id.to_s + ']}") { medias(first: 20) { edges { node { dbid } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal [pm1.id, pm2.id].sort, JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |e| e['node']['dbid'] }.sort
    # ES
    query = 'query CheckSearch { search(query: "{\"operator\":\"AND\",\"read\":[1],\"users\":[' + u2.id.to_s + '],\"report_status\":\"unpublished\"}") { medias(first: 20) { edges { node { dbid } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal [], JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |e| e['node']['dbid'] }
    query = 'query CheckSearch { search(query: "{\"operator\":\"OR\",\"read\":[1],\"users\":[' + u2.id.to_s + '],\"report_status\":\"unpublished\"}") { medias(first: 20) { edges { node { dbid } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal [pm1.id, pm2.id].sort, JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |e| e['node']['dbid'] }.sort
  end

  test "should search by similar image on PG" do
    t = create_team
    u = create_user is_admin: true
    authenticate_with_user(u)
    pm = create_project_media team: t

    Bot::Alegre.stubs(:get_items_with_similar_media_v2).returns({ pm.id => 0.8 })
    path = File.join(Rails.root, 'test', 'data', 'rails.png')
    file = Rack::Test::UploadedFile.new(path, 'image/png')
    query = 'query CheckSearch { search(query: "{\"file_type\":\"image\"}") { medias(first: 20) { edges { node { dbid } } } } }'
    post :create, params: { query: query, team: t.slug, file: file }
    assert_response :success
    assert_equal 1, JSON.parse(@response.body)['data']['search']['medias']['edges'].size
    assert_equal pm.id, JSON.parse(@response.body)['data']['search']['medias']['edges'][0]['node']['dbid']
    Bot::Alegre.unstub(:get_items_with_similar_media_v2)
  end

  test "should search by similar image on ES" do
    setup_elasticsearch
    t = create_team
    u = create_user is_admin: true
    authenticate_with_user(u)
    m = create_claim_media quote: 'Test'
    m2 = create_claim_media quote: 'Another Test'
    pm = create_project_media team: t, media: m
    pm2 = create_project_media team: t, media: m2
    sleep 2
    Bot::Alegre.stubs(:get_items_with_similar_media_v2).returns({ pm.id => 0.8 })
    path = File.join(Rails.root, 'test', 'data', 'rails.png')
    file = Rack::Test::UploadedFile.new(path, 'image/png')
    query = 'query CheckSearch { search(query: "{\"keyword\":\"Test\",\"file_type\":\"image\"}") { medias(first: 20) { edges { node { dbid } } } } }'
    post :create, params: { query: query, team: t.slug, file: file }
    assert_response :success
    assert_equal 1, JSON.parse(@response.body)['data']['search']['medias']['edges'].size
    assert_equal pm.id, JSON.parse(@response.body)['data']['search']['medias']['edges'][0]['node']['dbid']
    Bot::Alegre.unstub(:get_items_with_similar_media_v2)
  end

  test "should upload search file" do
    t = create_team
    u = create_user is_admin: true
    authenticate_with_user(u)
    path = File.join(Rails.root, 'test', 'data', 'rails.png')
    file = Rack::Test::UploadedFile.new(path, 'image/png')
    query = 'mutation { searchUpload(input: {}) { file_handle, file_url } }'
    post :create, params: { query: query, team: t.slug, file: file }
    assert_response :success
    data = JSON.parse(@response.body)['data']['searchUpload']
    hash = data['file_handle']
    assert_kind_of String, hash
    assert CheckS3.exist?("check_search/#{hash}")
    assert_not_nil data['file_url']
  end

  test "should get shared teams" do
    t = create_team
    f = create_feed team: nil
    f.teams << t
    query = "query { team(slug: \"#{t.slug}\") { shared_teams } }"
    post :create, params: { query: query }
    assert_equal({ t.id.to_s => t.name }, JSON.parse(@response.body).dig('data', 'team', 'shared_teams'))
    assert_response :success
  end

  test "should send GraphQL queries in batch" do
    u = create_user is_admin: true
    authenticate_with_user(u)
    t1 = create_team slug: 'batch-1', name: 'Batch 1'
    t2 = create_team slug: 'batch-2', name: 'Batch 2'
    t3 = create_team slug: 'batch-3', name: 'Batch 3'
    post :batch, params: { _json: [
      { query: 'query { team(slug: "batch-1") { name } }', variables: {}, id: 'q1' },
      { query: 'query { team(slug: "batch-2") { name } }', variables: {}, id: 'q2' },
      { query: 'query { team(slug: "batch-3") { name } }', variables: {}, id: 'q3' }
    ]}
    result = JSON.parse(@response.body)
    assert_equal 'Batch 1', result.find{ |t| t['id'] == 'q1' }['payload']['data']['team']['name']
    assert_equal 'Batch 2', result.find{ |t| t['id'] == 'q2' }['payload']['data']['team']['name']
    assert_equal 'Batch 3', result.find{ |t| t['id'] == 'q3' }['payload']['data']['team']['name']
  end

  test "should update tag" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'collaborator'
    authenticate_with_user(u)
    pm = create_project_media team: t
    tg = create_tag annotated: pm
    id = Base64.encode64("Tag/#{tg.id}")
    query = 'mutation update { updateTag(input: { clientMutationId: "1", id: "' + id + '", fragment: "t=1,2" }) { tag { id } } }'
    post :create, params: { query: query }
    assert_response :success
  end

  test "should return updated offset from PG" do
    RequestStore.store[:skip_cached_field_update] = false
    u = create_user is_admin: true
    authenticate_with_user(u)
    t = create_team
    pm1 = create_project_media team: t
    pm2 = create_project_media team: t
    query = 'query CheckSearch { search(query: "{\"sort\":\"recent_activity\",\"id\":' + pm1.id.to_s + ',\"esoffset\":0,\"eslimit\":1}") {item_navigation_offset,medias(first:20){edges{node{dbid}}}}}'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    response = JSON.parse(@response.body)['data']['search']
    assert_equal pm1.id, response['medias']['edges'][0]['node']['dbid']
    assert_equal 1, response['item_navigation_offset']
  end

  # TODO: Should review by Sawy
  # test "should set Smooch user Slack channel URL" do
  #   u = create_user
  #   t = create_team
  #   p = create_project team: t
  #   create_team_user team: t, user: u, role: 'admin'
  #   set_fields = { smooch_user_data: { id: random_string }.to_json, smooch_user_app_id: 'fake', smooch_user_id: 'fake' }.to_json
  #   d = create_dynamic_annotation annotated: p, annotation_type: 'smooch_user', set_fields: set_fields
  #   authenticate_with_token
  #   query = 'mutation { smoochBotAddSlackChannelUrl(input: { id: "' + d.id.to_s + '", set_fields: "{\"smooch_user_slack_channel_url\":\"' + random_url + '\"}" }) { annotation { dbid } } }'
  #   post :create, params: { query: query }
  #   assert_response :success
  # end

  # test "should not set Smooch user Slack channel URL" do
  #   u = create_user
  #   t = create_team
  #   p = create_project team: t
  #   create_team_user team: t, user: u, role: 'admin'
  #   authenticate_with_token
  #   query = 'mutation { smoochBotAddSlackChannelUrl(input: { id: "0", set_fields: "{\"smooch_user_slack_channel_url\":\"' + random_url + '\"}" }) { annotation { dbid } } }'
  #   post :create, params: { query: query }
  #   assert_response :success
  # end
end
