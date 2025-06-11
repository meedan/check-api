require_relative '../test_helper'

class FeedTeamTest < ActiveSupport::TestCase
  def setup
    super
    FeedTeam.delete_all
  end

  test "should create feed team" do
    feed = create_feed
    team = create_team
    assert_difference 'FeedTeam.count' do
      feed.teams << team
    end
  end

  test "should not create feed team if logged in user" do
    user = create_user
    team = create_team
    feed = create_feed
    with_current_user_and_team user, team do
      assert_raises StandardError do
        feed.teams << team
      end
    end
  end

  test "should have a article and/or media list that belong to feed teams" do
    team = create_team
    feed = create_feed
    media_saved_search = create_saved_search team: team, list_type: 'media'
    article_saved_search = create_saved_search team: team, list_type: 'article'
    feed_team = create_feed_team media_saved_search: media_saved_search, article_saved_search: article_saved_search, team_id: team.id, feed: feed
    assert_equal media_saved_search, feed_team.media_saved_search
    assert_equal article_saved_search, feed_team.article_saved_search
  end

  test "should not associate saved_search with incorrect list_type" do
    team = create_team
    feed = create_feed
    media_saved_search = create_saved_search team: team, list_type: 'media'
    article_saved_search = create_saved_search team: team, list_type: 'article'

    assert_raises ActiveRecord::RecordInvalid do
      create_feed_team article_saved_search: media_saved_search, team_id: team.id, feed: feed
    end

    assert_raises ActiveRecord::RecordInvalid do
      create_feed_team media_saved_search: article_saved_search, team_id: team.id, feed: feed
    end
  end

  test "should not create a duplicate FeedTeam with the same saved_search" do
    team = create_team
    feed = create_feed
    media_saved_search = create_saved_search team: team
    assert_difference 'FeedTeam.count' do
      create_feed_team media_saved_search: media_saved_search, team_id: team.id, feed: feed
    end
    assert_raises ActiveRecord::RecordInvalid do
      create_feed_team media_saved_search: create_saved_search, feed: feed
    end
  end

  test "should get filters" do
    team = create_team
    media_saved_search = create_saved_search team: team, filters: { foo: 'bar'}
    feed_team = create_feed_team team_id: team.id, media_saved_search_id: media_saved_search.id
    assert_equal 'bar', feed_team.reload.filters['foo']
  end

  test "should have settings" do
    feed_team = create_feed_team settings: { foo: 'bar' }
    assert_equal 'bar', feed_team.reload.get_foo
    feed_team.set_bar = 'foo'
    feed_team.save!
    assert_equal 'foo', feed_team.reload.get_bar
  end

  test "should have a team and a feed" do
    team = create_team
    feed = create_feed
    feed_team = create_feed_team team: team, feed: feed
    assert_equal team, feed_team.reload.team
    assert_equal feed, feed_team.reload.feed
  end

  test "should set requests filters" do
    feed_team = create_feed_team
    feed_team.requests_filters = { foo: 'bar' }
    feed_team.save!
    assert_equal 'bar', feed_team.reload.get_requests_filters[:foo]
  end

  test "should delete invitations when leaving feed" do
    user = create_user
    feed_team = create_feed_team
    create_team_user user: user, team: feed_team.team, role: 'admin'
    create_feed_invitation feed: feed_team.feed
    feed_invitation =create_feed_invitation email: user.email, feed: feed_team.feed
    assert_not_nil FeedInvitation.find_by_id(feed_invitation.id)
    User.current = user
    assert_difference 'FeedInvitation.count', -1 do
      feed_team.destroy!
    end
    User.current = nil
    assert_nil FeedInvitation.find_by_id(feed_invitation.id)
  end

  test "should return previous media list" do
    team = create_team
    media_saved_search1 = create_saved_search team: team
    media_saved_search2 = create_saved_search team: team
    feed_team = create_feed_team team: team, media_saved_search: media_saved_search1
    feed_team.media_saved_search = media_saved_search2
    feed_team.save!
    assert_equal media_saved_search1, feed_team.media_saved_search_was
  end

  test "should return previous article list" do
    team = create_team
    article_saved_search1 = create_saved_search team: team, list_type: 'article'
    article_saved_search2 = create_saved_search team: team, list_type: 'article'
    feed_team = create_feed_team team: team, article_saved_search: article_saved_search1
    feed_team.article_saved_search = article_saved_search2
    feed_team.save!
    assert_equal article_saved_search1, feed_team.article_saved_search_was
  end
end
