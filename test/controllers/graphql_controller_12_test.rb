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
end
