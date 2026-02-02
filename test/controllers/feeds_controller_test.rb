require_relative '../test_helper'

class FeedsControllerTest < ActionController::TestCase
  def setup
    @controller = Api::V2::FeedsController.new
    super
    RequestStore.clear!
    RequestStore.store[:skip_cached_field_update] = false
    [FeedTeam, Feed, ProjectMediaRequest, Request].each { |klass| klass.delete_all }
    create_verification_status_stuff
    @a = create_api_key
    @b = @a.bot_user
    @t1 = create_team name: 'Foo'
    @t2 = create_team name: 'Bar'
    @t3 = create_team
    TeamUser.destroy_all
    create_team_user team: @t1, user: @b
    create_team_user team: @t2, user: @b
    @pm1 = create_project_media quote: 'Foo 1', media: nil, team: @t1
    @pm2 = create_project_media quote: 'Foo 2', media: nil, team: @t2
    create_project_media quote: 'Bar 1', media: nil, team: @t1
    create_project_media quote: 'Bar 2', media: nil, team: @t2
    create_project_media quote: 'Foo Bar', media: nil, team: @t3
    @f = create_feed published: true
    @f.teams = [@t1, @t2]
    FeedTeam.update_all(shared: true)
    Bot::Smooch.stubs(:search_for_similar_published_fact_checks).with('text', 'Foo', [@t1.id, @t2.id], 3, nil, @f.id, nil, false).returns([@pm1, @pm2])
  end

  def teardown
    Bot::Smooch.unstub(:search_for_similar_published_fact_checks)
  end

  test "should not request feed data if not authenticated" do
    get :index, params: {}
    assert_response 401
  end

  test "should request team data" do
    a = create_api_key
    b = a.bot_user
    create_team_user team: @t1, user: b
    Bot::Smooch.stubs(:search_for_similar_published_fact_checks).with('text', 'Foo', [@t1.id], 3, nil, nil, nil, false).returns([@pm1])

    authenticate_with_token a
    get :index, params: { filter: { type: 'text', query: 'Foo' } }
    assert_response :success
    assert_equal 1, json_response['data'].size
    assert_equal 1, json_response['meta']['record-count']
  end

  test "should request feed data" do
    Bot::Smooch.stubs(:search_for_similar_published_fact_checks)
             .with('text', 'Foo', [@t1.id, @t2.id], 3, nil, @f.id, false)
             .returns([@pm1, @pm2])
    authenticate_with_token @a
    get :index, params: { filter: { type: 'text', query: 'Foo', feed_id: @f.id } }
    assert_response :success
    assert_equal 2, json_response['data'].size
    assert_equal 2, json_response['meta']['record-count']
  end

  test "should keep order" do
    Sidekiq::Testing.fake! do
      authenticate_with_token @a

      Bot::Smooch.stubs(:search_for_similar_published_fact_checks).with('text', 'Foo', [@t1.id, @t2.id], 3, nil, @f.id, false).returns([@pm1, @pm2])
      get :index, params: { filter: { type: 'text', query: 'Foo', feed_id: @f.id } }
      assert_response :success
      assert_equal 'Foo', json_response['data'][0]['attributes']['organization']
      assert_equal 'Bar', json_response['data'][1]['attributes']['organization']

      Bot::Smooch.stubs(:search_for_similar_published_fact_checks).with('text', 'Foo', [@t1.id, @t2.id], 3, nil, @f.id, false).returns([@pm2, @pm1])
      get :index, params: { filter: { type: 'text', query: 'Foo', feed_id: @f.id } }
      assert_response :success
      assert_equal 'Bar', json_response['data'][0]['attributes']['organization']
      assert_equal 'Foo', json_response['data'][1]['attributes']['organization']

      Bot::Smooch.unstub(:search_for_similar_published_fact_checks)
    end
  end

  test "should return empty set if feed is not published" do
    authenticate_with_token @a
    @f.update_column(:published, false)
    get :index, params: { filter: { type: 'text', query: 'Foo', feed_id: @f.id } }
    assert_response :success
    assert_equal 0, json_response['data'].size
  end

  test "should return empty set if team is not sharing data with team" do
    authenticate_with_token @a
    FeedTeam.update_all(shared: false)
    get :index, params: { filter: { type: 'text', query: 'Foo', feed_id: @f.id } }
    assert_response :success
    assert_equal 0, json_response['data'].size
  end

  test "should return empty set if team has no access to feed" do
    authenticate_with_token @a
    @f.teams = []
    get :index, params: { filter: { type: 'text', query: 'Foo', feed_id: @f.id } }
    assert_response :success
    assert_equal 0, json_response['data'].size
  end

  test "should save request query" do
    Bot::Alegre.stubs(:request).returns({})
    Bot::Smooch.stubs(:search_for_similar_published_fact_checks)
             .with('text', 'Foo', [@t1.id, @t2.id], 3, nil, @f.id, false)
             .returns([@pm1, @pm2])
    Sidekiq::Testing.inline!
    authenticate_with_token @a
    assert_difference 'Request.count' do
      assert_difference 'Media.count' do
        get :index, params: { filter: { type: 'text', query: 'Foo', feed_id: @f.id } }
      end
    end
    assert_response :success
    assert_equal 2, json_response['data'].size
    assert_equal 2, json_response['meta']['record-count']
    Bot::Alegre.unstub(:request)
  end

  test "should save relationship between request and results" do
    Bot::Alegre.stubs(:request).returns({})
    Bot::Smooch.stubs(:search_for_similar_published_fact_checks)
           .with('text', 'Foo', [@t1.id, @t2.id], 3, nil, @f.id, false)
           .returns([@pm1, @pm2])
    Sidekiq::Testing.inline!
    authenticate_with_token @a
    assert_difference 'Request.count' do
      get :index, params: { filter: { type: 'text', query: 'Foo', feed_id: @f.id } }
    end
    assert_response :success
    Bot::Alegre.unstub(:request)
  end

  test "should not save request when skip_save_request is true" do
    Bot::Alegre.stubs(:request).returns({})
    Bot::Smooch.stubs(:search_for_similar_published_fact_checks)
           .with('text', 'Foo', [@t1.id, @t2.id], 3, nil, @f.id, false)
           .returns([@pm1, @pm2])
    Sidekiq::Testing.inline!
    authenticate_with_token @a
    assert_no_difference 'Request.count' do
      get :index, params: { filter: { type: 'text', query: 'Foo', feed_id: @f.id, skip_save_request: 'true' }}
    end
    assert_response :success
    Bot::Alegre.unstub(:request)
  end

  test "should parse the full query" do
    Bot::Smooch.unstub(:search_for_similar_published_fact_checks)
    Bot::Alegre.stubs(:request).returns({})
    Sidekiq::Testing.inline!
    authenticate_with_token @a
    get :index, params: { filter: { type: 'text', query: 'Foo, bar and test', feed_id: @f.id } }
    assert_response :success
    assert_equal 'Foo, bar and test', Media.last.quote
    Bot::Alegre.unstub(:request)
  end

  test "should return workspaces" do
    api_key = create_api_key skip_create_bot_user: true
    authenticate_with_token api_key
    get :index, params: {}
    assert_response :success
  end
end
