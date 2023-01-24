require_relative '../test_helper'

class GraphqlController6Test < ActionController::TestCase
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

  test "should search using OR or AND on PG" do
    t = create_team
    p1 = create_project team: t
    p2 = create_project team: t
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    authenticate_with_user(u)

    pm1 = create_project_media team: t, project: p1, read: true
    pm2 = create_project_media team: t, project: p2, read: false

    query = 'query CheckSearch { search(query: "{\"operator\":\"AND\",\"read\":true,\"projects\":[' + p2.id.to_s + ']}") { medias(first: 20) { edges { node { dbid } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal [], JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |e| e['node']['dbid'] }

    query = 'query CheckSearch { search(query: "{\"operator\":\"OR\",\"read\":true,\"projects\":[' + p2.id.to_s + ']}") { medias(first: 20) { edges { node { dbid } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal [pm1.id, pm2.id].sort, JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |e| e['node']['dbid'] }.sort
  end

  test "should search using OR or AND on ES" do
    setup_elasticsearch
    RequestStore.store[:skip_cached_field_update] = false
    t = create_team
    p1 = create_project team: t
    p2 = create_project team: t
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    authenticate_with_user(u)

    pm1 = create_project_media team: t, project: p1, read: true
    pm2 = create_project_media team: t, project: p2, read: false

    query = 'query CheckSearch { search(query: "{\"operator\":\"AND\",\"read\":[1],\"projects\":[' + p2.id.to_s + '],\"report_status\":\"unpublished\"}") { medias(first: 20) { edges { node { dbid } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal [], JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |e| e['node']['dbid'] }

    query = 'query CheckSearch { search(query: "{\"operator\":\"OR\",\"read\":[1],\"projects\":[' + p2.id.to_s + '],\"report_status\":\"unpublished\"}") { medias(first: 20) { edges { node { dbid } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal [pm1.id, pm2.id].sort, JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |e| e['node']['dbid'] }.sort
  end

  test "should search by project" do
    t = create_team
    p = create_project team: t
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    authenticate_with_user(u)

    create_project_media team: t, project: nil, project_id: nil
    create_project_media project: p
    
    query = 'query CheckSearch { search(query: "{}") { medias(first: 20) { edges { node { dbid } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal 2, JSON.parse(@response.body)['data']['search']['medias']['edges'].size
  end

  test "should get Smooch newsletter information" do
    setup_smooch_bot(true)
    rss = '<rss version="1"><channel><title>x</title><link>x</link><description>x</description><item><title>x</title><link>x</link></item></channel></rss>'
    WebMock.stub_request(:get, 'http://test.com/feed.rss').to_return(status: 200, body: rss)
    u = create_user is_admin: true
    authenticate_with_user(u)
    query = "query { team(slug: \"#{@team.slug}\") { team_bot_installations(first: 1) { edges { node { smooch_newsletter_information } } } } }"
    post :create, params: { query: query }
    assert_response :success
    assert_not_nil json_response.dig('data', 'team', 'team_bot_installations', 'edges', 0, 'node', 'smooch_newsletter_information')
  end

  test "should search by similar image on PG" do
    t = create_team
    u = create_user is_admin: true
    authenticate_with_user(u)

    pm = create_project_media team: t

    Bot::Alegre.stubs(:get_items_with_similar_media).returns({ pm.id => 0.8 })
    path = File.join(Rails.root, 'test', 'data', 'rails.png')
    file = Rack::Test::UploadedFile.new(path, 'image/png')
    query = 'query CheckSearch { search(query: "{\"file_type\":\"image\"}") { medias(first: 20) { edges { node { dbid } } } } }'
    post :create, params: { query: query, team: t.slug, file: file }
    assert_response :success
    assert_equal 1, JSON.parse(@response.body)['data']['search']['medias']['edges'].size
    assert_equal pm.id, JSON.parse(@response.body)['data']['search']['medias']['edges'][0]['node']['dbid']
    Bot::Alegre.unstub(:get_items_with_similar_media)
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

    Bot::Alegre.stubs(:get_items_with_similar_media).returns({ pm.id => 0.8 })
    path = File.join(Rails.root, 'test', 'data', 'rails.png')
    file = Rack::Test::UploadedFile.new(path, 'image/png')
    query = 'query CheckSearch { search(query: "{\"keyword\":\"Test\",\"file_type\":\"image\"}") { medias(first: 20) { edges { node { dbid } } } } }'
    post :create, params: { query: query, team: t.slug, file: file }
    assert_response :success
    assert_equal 1, JSON.parse(@response.body)['data']['search']['medias']['edges'].size
    assert_equal pm.id, JSON.parse(@response.body)['data']['search']['medias']['edges'][0]['node']['dbid']
    Bot::Alegre.unstub(:get_items_with_similar_media)
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
    f = create_feed
    f.teams << t
    query = "query { team(slug: \"#{t.slug}\") { shared_teams } }"
    post :create, params: { query: query }
    assert_equal({ t.id.to_s => t.name }, JSON.parse(@response.body).dig('data', 'team', 'shared_teams'))
    assert_response :success
  end

  test "should search by feed" do
    setup_elasticsearch
    t1 = create_team
    t2 = create_team
    u = create_user
    create_team_user(team: t1, user: u, role: 'editor')
    authenticate_with_user(u)
    f = create_feed
    f.filters = { keyword: 'banana' }
    f.teams = [t1, t2]
    f.save!

    # Team 1 content to be shared
    ft1 = FeedTeam.where(feed: f, team: t1).last
    ft1.filters = { keyword: 'apple' }
    ft1.shared = false
    ft1.save!
    pm1a = create_project_media quote: 'I like apple and banana', team: t1
    pm1b = create_project_media quote: 'I like orange and banana', team: t1

    # Team 2 content to be shared
    ft2 = FeedTeam.where(feed: f, team: t2).last
    ft2.filters = { keyword: 'orange' }
    ft2.shared = true
    ft2.save!
    pm2a = create_project_media quote: 'I love apple and banana', team: t2
    pm2b = create_project_media quote: 'I love orange and banana', team: t2

    # Wait for content to be indexed in ElasticSearch
    sleep 5
    query = 'query CheckSearch { search(query: "{\"keyword\":\"and\",\"feed_id\":' + f.id.to_s + '}") { medias(first: 20) { edges { node { dbid } } } } }'

    # Can't see anything until content is shared
    post :create, params: { query: query, team: t1.slug }
    assert_response :success
    assert_equal [], JSON.parse(@response.body)['data']['search']['medias']['edges']

    # See content after content is shared
    with_current_user_and_team(u, t1) do
      ft1.shared = true
      ft1.save!
    end
    post :create, params: { query: query, team: t1.slug }
    assert_response :success
    assert_equal [pm1a.id, pm2b.id].sort, JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |pm| pm['node']['dbid'] }.sort

    # Filter by published if feed is published
    with_current_user_and_team(nil, nil) do
      f.published = true
      f.save!
    end
    post :create, params: { query: query, team: t1.slug }
    assert_response :success
    assert_equal [], JSON.parse(@response.body)['data']['search']['medias']['edges']
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
