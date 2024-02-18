require_relative '../test_helper'
require 'error_codes'
require 'sidekiq/testing'

class GraphqlController12Test < ActionController::TestCase
  def setup
    @controller = Api::V1::GraphqlController.new
    TestDynamicAnnotationTables.load!

    @u = create_user
    @t = create_team
    create_team_user team: @t, user: @u, role: 'admin'
  end

  def teardown
    User.unstub(:current)
    Team.unstub(:current)
    User.current = nil
    Team.current = nil
  end

  test "should list feed invitations for a feed" do
    f = create_feed team: @t
    fi = create_feed_invitation feed: f
    create_feed_invitation

    authenticate_with_user(@u)
    query = 'query { feed(id: "' + f.id.to_s + '") { feed_invitations(first: 10) { edges { node { id, dbid } } } } }'
    post :create, params: { query: query }
    assert_response :success
    assert_equal [fi.id], JSON.parse(@response.body)['data']['feed']['feed_invitations']['edges'].collect{ |edge| edge['node']['dbid'] }
  end

  test "should list feed invitations for a user" do
    fi = create_feed_invitation email: @u.email
    create_feed_invitation

    authenticate_with_user(@u)
    query = 'query { me { feed_invitations(first: 10) { edges { node { id, dbid } } } } }'
    post :create, params: { query: query }
    assert_response :success
    assert_equal [fi.id], JSON.parse(@response.body)['data']['me']['feed_invitations']['edges'].collect{ |edge| edge['node']['dbid'] }
  end

  test "should list teams for a feed" do
    t2 = create_team
    f = create_feed team: @t
    create_feed_team feed: f, team: t2
    create_feed_team

    authenticate_with_user(@u)
    query = 'query { feed(id: "' + f.id.to_s + '") { teams(first: 10) { edges { node { id, dbid } } } } }'
    post :create, params: { query: query }
    assert_response :success
    assert_equal [@t.id, t2.id].sort, JSON.parse(@response.body)['data']['feed']['teams']['edges'].collect{ |edge| edge['node']['dbid'] }.sort
  end

  test "should create feed invitation" do
    f = create_feed team: @t

    authenticate_with_user(@u)
    query = 'mutation { createFeedInvitation(input: { feed_id: ' + f.id.to_s + ', email: "' + random_email + '"}) { feed_invitation { id } } }'
    assert_difference 'FeedInvitation.count' do
      post :create, params: { query: query }
    end
    assert_response :success
  end

  test "should not create feed invitation" do
    f = create_feed

    authenticate_with_user(@u)
    query = 'mutation { createFeedInvitation(input: { feed_id: ' + f.id.to_s + ', email: "' + random_email + '"}) { feed_invitation { id } } }'
    assert_no_difference 'FeedInvitation.count' do
      post :create, params: { query: query }
    end
    assert_response 400
  end

  test "should destroy feed invitation" do
    f = create_feed team: @t
    fi = create_feed_invitation feed: f

    authenticate_with_user(@u)
    query = 'mutation { destroyFeedInvitation(input: { id: "' + fi.graphql_id + '" }) { deletedId } }'
    assert_difference 'FeedInvitation.count', -1 do
      post :create, params: { query: query }
    end
    assert_response :success
  end

  test "should not destroy feed invitation" do
    fi = create_feed_invitation

    authenticate_with_user(@u)
    query = 'mutation { destroyFeedInvitation(input: { id: "' + fi.graphql_id + '" }) { deletedId } }'
    assert_no_difference 'FeedInvitation.count' do
      post :create, params: { query: query }
    end
    assert_response 400
  end

  test "should accept feed invitation" do
    fi = create_feed_invitation email: @u.email

    authenticate_with_user(@u)
    query = 'mutation { acceptFeedInvitation(input: { id: ' + fi.id.to_s + ', team_id: ' + @t.id.to_s + ' }) { success } }'
    assert_difference 'FeedTeam.count' do
      post :create, params: { query: query }
    end
    assert_response :success
    assert JSON.parse(@response.body).dig('data', 'acceptFeedInvitation', 'success')
  end

  test "should not accept feed invitation if it's not the same email" do
    fi = create_feed_invitation

    authenticate_with_user(@u)
    query = 'mutation { acceptFeedInvitation(input: { id: ' + fi.id.to_s + ', team_id: ' + @t.id.to_s + ' }) { success } }'
    assert_no_difference 'FeedTeam.count' do
      post :create, params: { query: query }
    end
    assert_response :success
    assert_nil JSON.parse(@response.body).dig('data', 'acceptFeedInvitation', 'success')
  end

  test "should not accept feed invitation if it's not a member of the target workspace" do
    fi = create_feed_invitation email: @u.email

    authenticate_with_user(@u)
    query = 'mutation { acceptFeedInvitation(input: { id: ' + fi.id.to_s + ', team_id: ' + create_team.id.to_s + ' }) { success } }'
    assert_no_difference 'FeedTeam.count' do
      post :create, params: { query: query }
    end
    assert_response :success
    assert !JSON.parse(@response.body).dig('data', 'acceptFeedInvitation', 'success')
  end

  test "should reject feed invitation" do
    fi = create_feed_invitation email: @u.email

    authenticate_with_user(@u)
    query = 'mutation { rejectFeedInvitation(input: { id: ' + fi.id.to_s + ' }) { success } }'
    post :create, params: { query: query }
    assert_response :success
    assert JSON.parse(@response.body).dig('data', 'rejectFeedInvitation', 'success')
  end

  test "should not reject feed invitation if it's not the same email" do
    fi = create_feed_invitation

    authenticate_with_user(@u)
    query = 'mutation { rejectFeedInvitation(input: { id: ' + fi.id.to_s + ' }) { success } }'
    post :create, params: { query: query }
    assert_response :success
    assert !JSON.parse(@response.body).dig('data', 'rejectFeedInvitation', 'success')
  end

  test "should read feed invitation" do
    fi = create_feed_invitation email: @u.email

    authenticate_with_user(@u)
    query = 'query { feed_invitation(id: ' + fi.id.to_s + ') { id } }'
    post :create, params: { query: query }
    assert_response :success
    assert_not_nil JSON.parse(@response.body).dig('data', 'feed_invitation')
  end

  test "should not read feed invitation" do
    fi = create_feed_invitation

    authenticate_with_user(@u)
    query = 'query { feed_invitation(id: ' + fi.id.to_s + ') { dbid } }'
    post :create, params: { query: query }
    assert_response :success
    assert_nil JSON.parse(@response.body).dig('data', 'feed_invitation')
  end

  test "should read feed invitation based on feed ID and current user email" do
    fi = create_feed_invitation email: @u.email

    authenticate_with_user(@u)
    query = 'query { feed_invitation(feedId: ' + fi.feed_id.to_s + ') { id } }'
    post :create, params: { query: query }
    assert_response :success
    assert_not_nil JSON.parse(@response.body).dig('data', 'feed_invitation')
  end

  test "should not read feed invitation based on feed ID and current user email" do
    fi = create_feed_invitation

    authenticate_with_user(@u)
    query = 'query { feed_invitation(feedId: ' + fi.feed_id.to_s + ') { id } }'
    post :create, params: { query: query }
    assert_response :success
    assert_nil JSON.parse(@response.body).dig('data', 'feed_invitation')
  end

  test "should read feed team" do
    ft = create_feed_team team: @t

    authenticate_with_user(@u)
    query = 'query { feed_team(id: ' + ft.id.to_s + ') { id } }'
    post :create, params: { query: query }
    assert_response :success
    assert_not_nil JSON.parse(@response.body).dig('data', 'feed_team')
  end

  test "should not read feed team" do
    ft = create_feed_team

    authenticate_with_user(@u)
    query = 'query { feed_team(id: ' + ft.id.to_s + ') { id } }'
    post :create, params: { query: query }
    assert_response :success
    assert_nil JSON.parse(@response.body).dig('data', 'feed_team')
  end

  test "should read feed team based on feed ID and team slug" do
    ft = create_feed_team team: @t

    authenticate_with_user(@u)
    query = 'query { feed_team(feedId: ' + ft.feed_id.to_s + ', teamSlug: "' + @t.slug + '") { id } }'
    post :create, params: { query: query }
    assert_response :success
    assert_not_nil JSON.parse(@response.body).dig('data', 'feed_team')
  end

  test "should not read feed team based on feed ID and team slug" do
    ft = create_feed_team

    authenticate_with_user(@u)
    query = 'query { feed_team(feedId: ' + ft.feed_id.to_s + ', teamSlug: "' + ft.team.slug + '") { id } }'
    post :create, params: { query: query }
    assert_response :success
    assert_nil JSON.parse(@response.body).dig('data', 'feed_team')
  end

  test "should always apply team filter on search" do
    setup_elasticsearch
    t1 = create_team
    t2 = create_team
    pm1 = create_project_media team: t1, quote: 'Test 1', disable_es_callbacks: false
    pm2 = create_project_media team: t2, quote: 'Test 2', disable_es_callbacks: false
    sleep 2 # Wait for content to be indexed

    authenticate_with_user(@u)

    # ElasticSearch
    query = 'query { search(query: "{\"keyword\":\"Test\",\"operator\":\"or\"}") { number_of_results } }'
    post :create, params: { query: query, team: t1.slug }
    assert_response :success
    assert_equal 1, JSON.parse(@response.body).dig('data', 'search', 'number_of_results')

    # PostgreSQL
    query = 'query { search(query: "{\"operator\":\"or\"}") { number_of_results } }'
    post :create, params: { query: query, team: t1.slug }
    assert_response :success
    assert_equal 1, JSON.parse(@response.body).dig('data', 'search', 'number_of_results')
  end

  test "should set and get feed data points" do
    authenticate_with_user(@u)

    query = 'mutation { createFeed(input: { name: "' + random_string + '", dataPoints: [1, 2, 3], licenses: [] }) { feed { dbid, data_points } } }'
    assert_difference 'Feed.count' do
      post :create, params: { query: query, team: @t.slug }
    end
    assert_response :success

    feed = Feed.find(JSON.parse(@response.body).dig('data', 'createFeed', 'feed', 'dbid'))
    assert_equal [1, 2, 3].sort, feed.data_points.sort

    query = 'query { feed(id: ' + feed.id.to_s + ') { data_points } }'
    post :create, params: { query: query, team: @t.slug }
    assert_response :success
    assert_equal [1, 2, 3].sort, JSON.parse(@response.body).dig('data', 'feed', 'data_points').sort
  end

  test "should return me type after update user" do
    user = create_user
    authenticate_with_user(user)
    post :create, params: { query: 'query Query { me { id } }' }
    assert_response :success
    id = JSON.parse(@response.body)['data']['me']['id']
    query = 'mutation { updateUser(input: { clientMutationId: "1", id: "' + id + '", name: "update name" }) { user { dbid }, me { dbid } } }'
    post :create, params: { query: query }
    assert_response :success
    data = JSON.parse(@response.body)['data']['updateUser']['me']
    assert_equal user.id, data['dbid']
  end

  test "should ensure graphql introspection is disabled" do
    user = create_user
    authenticate_with_user(user)
    INTROSPECTION_QUERY = <<-GRAPHQL
      {
        __schema {
          queryType {
            name
          }
        }
      }
    GRAPHQL

    post :create, params: { query: INTROSPECTION_QUERY }
    assert_response :success
    response_body = JSON.parse(response.body)
    assert_equal response_body['errors'][0]['message'], "Field '__schema' doesn't exist on type 'Query'"
  end

  test "should return feed clusters" do
    n = random_number(5) # In order to avoid N + 1 query problems, we need to be sure that the number of SQL queries is the same regardless the number of clusters
    puts "Testing with #{n} clusters"
    f = create_feed team: @t
    n.times { create_cluster feed: f, team_ids: [@t.id], project_media: create_project_media(team: @t) }

    authenticate_with_user(@u)
    query = 'query { feed(id: "' + f.id.to_s + '") { clusters_count, clusters(first: 10) { edges { node { id, dbid, first_item_at, last_item_at, last_request_date, last_fact_check_date, center { id }, teams(first: 10) { edges { node { name, avatar } } } } } } } }'
    assert_queries 20, '<=' do
      post :create, params: { query: query }
    end
    assert_response :success
    assert_equal n, JSON.parse(@response.body)['data']['feed']['clusters']['edges'].size
  end
end
