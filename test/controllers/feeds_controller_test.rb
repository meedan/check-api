require_relative '../test_helper'

class FeedsControllerTest < ActionController::TestCase
  def setup
    @controller = Api::V2::FeedsController.new
    super
    RequestStore.store[:skip_cached_field_update] = false
    create_verification_status_stuff
    @a = create_api_key
    @b = create_bot_user
    @b.api_key = @a
    @b.save!
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
    Bot::Smooch.stubs(:search_for_similar_published_fact_checks).with('text', 'Foo', [@t1.id, @t2.id], nil).returns([@pm1, @pm2])
  end

  def teardown
    Bot::Smooch.unstub(:search_for_similar_published_fact_checks)
  end

  test "should not request feed data if not authenticated" do
    get :index, params: {}
    assert_response 401
  end

  test "should request feed data" do
    authenticate_with_token @a
    get :index, params: { filter: { type: 'text', query: 'Foo' } }
    assert_response :success
    assert_equal 2, json_response['data'].size
    assert_equal 2, json_response['meta']['record-count']
  end

  test "should keep order" do
    authenticate_with_token @a

    Bot::Smooch.stubs(:search_for_similar_published_fact_checks).returns([@pm1, @pm2])
    get :index, params: { filter: { type: 'text', query: 'Foo' } }
    assert_response :success
    assert_equal 'Foo', json_response['data'][0]['attributes']['organization']
    assert_equal 'Bar', json_response['data'][1]['attributes']['organization']

    Bot::Smooch.stubs(:search_for_similar_published_fact_checks).returns([@pm2, @pm1])
    get :index, params: { filter: { type: 'text', query: 'Foo' } }
    assert_response :success
    assert_equal 'Bar', json_response['data'][0]['attributes']['organization']
    assert_equal 'Foo', json_response['data'][1]['attributes']['organization']
  end
end
