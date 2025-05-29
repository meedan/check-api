require_relative '../test_helper'

class FeedTest < ActiveSupport::TestCase
  def setup
    super
    Feed.delete_all
  end

  test "should create feed" do
    assert_difference 'Feed.count' do
      create_feed
    end
  end

  test "should not create feed if logged in user" do
    user = create_user
    team = create_team
    with_current_user_and_team(user, team) do
      assert_raises StandardError do
        create_feed
      end
    end
  end

  test "should set user and team" do
    team = create_team
    user = create_user
    create_team_user team: team, user: user, role: 'admin'
    with_current_user_and_team(user, team) do
      feed = nil
      assert_difference 'FeedTeam.count' do
        feed = create_feed team: team
      end
      feed = feed.reload
      assert_equal user.id, feed.user_id
      assert_equal team.id, feed.team_id
      assert_equal [team.id], feed.feed_teams.map(&:team_id)
    end
  end

  test "should set tags" do
    tags = ['tag_a', 'tag_b']
    feed = create_feed tags: tags
    assert_equal tags, feed.reload.tags
  end

  test "should validate licenses" do
    assert_difference 'Feed.count' do
      create_feed licenses: [1, 2], discoverable: true
    end
    assert_difference 'Feed.count' do
      create_feed licenses: [1, 2], discoverable: false
    end

    assert_raises ActiveRecord::RecordInvalid do
      create_feed licenses: [], discoverable: true
    end
    assert_raises ActiveRecord::RecordInvalid do
      create_feed licenses: [1, 4], discoverable: true
    end

    assert_nothing_raised do
      create_feed licenses: [], discoverable: false
    end
    assert_nothing_raised do
      create_feed licenses: [1, 4], discoverable: false
    end
  end

  test "should have a list that belong to feed teams" do
    team = create_team
    media_saved_search = create_saved_search team: team
    Team.stubs(:current).returns(team)
    assert_difference 'Feed.count' do
      create_feed media_saved_search: media_saved_search, team: team
    end
    assert_raises ActiveRecord::RecordInvalid do
      create_feed media_saved_search: create_saved_search
    end
    Team.unstub(:current)
  end

  test "should have a article and/or media list that belong to feed teams" do
    team = create_team
    feed = create_feed team: team
    Team.stubs(:current).returns(team)

    media_saved_search = create_saved_search team: team, list_type: 'media'
    article_saved_search = create_saved_search team: team, list_type: 'article'

    feed.media_saved_search = media_saved_search
    feed.article_saved_search = article_saved_search
    feed.save!

    assert_equal media_saved_search, feed.media_saved_search
    assert_equal 'media', feed.media_saved_search.list_type

    assert_equal article_saved_search, feed.article_saved_search
    assert_equal 'article', feed.article_saved_search.list_type

    Team.unstub(:current)
  end

  test "should not associate saved_search with incorrect list_type" do
    team = create_team
    feed = create_feed team: team

    media_saved_search = create_saved_search team: team, list_type: 'media'
    feed.article_saved_search = media_saved_search

    assert_raises ActiveRecord::RecordInvalid do
      feed.save!
    end
  end

  test "should not create a duplicate FeedTeam with the same saved_search" do
    team = create_team
    media_saved_search = create_saved_search team: team
    Team.stubs(:current).returns(team)
    assert_difference 'Feed.count' do
      create_feed media_saved_search: media_saved_search, team: team
    end
    assert_raises ActiveRecord::RecordInvalid do
      create_feed media_saved_search: create_saved_search
    end
    Team.unstub(:current)
  end

  test "should get feed filters" do
    team = create_team
    media_saved_search = create_saved_search team: team, filters: { foo: 'bar' }
    Team.stubs(:current).returns(team)
    feed = create_feed media_saved_search: media_saved_search, team: team
    assert_equal({}, feed.reload.filters)
    Team.unstub(:current)
  end

  test "should have settings" do
    feed = create_feed settings: { foo: 'bar' }
    assert_equal 'bar', feed.reload.get_foo
    feed.set_bar = 'foo'
    feed.save!
    assert_equal 'foo', feed.reload.get_bar
  end

  test "should have teams" do
    team = create_team
    feed = create_feed team: nil
    feed.teams << team
    assert_equal [team], feed.reload.teams
  end

  test "should have name" do
    assert_raises ActiveRecord::RecordInvalid do
      create_feed name: nil
    end
  end

  test "should access feed" do
    user = create_user
    team1 = create_team
    create_team_user user: user, team: team1
    team2 = create_team
    feed1 = create_feed
    feed1.teams << team1
    feed2 = create_feed
    feed2.teams << team2

    a = Ability.new(user, team1)
    assert a.can?(:read, feed1)
    assert !a.can?(:read, feed2)

    a = Ability.new(user, team2)
    assert a.can?(:read, feed1)
    assert !a.can?(:read, feed2)
  end

  test "should get number of root requests" do
    feed = create_feed
    request = create_request feed: feed
    create_request feed: feed, request_id: request.id
    assert_equal 2, feed.requests_count
    assert_equal 1, feed.root_requests_count
  end

  test "should notify subscribers" do
    Sidekiq::Testing.inline!
    url = URI.join(random_url, "user/#{random_number}")
    WebMock.stub_request(:post, url)
    feed = create_feed published: true
    team = create_team
    feed.teams << team
    FeedTeam.update_all shared: true
    media = create_uploaded_image

    request = create_request feed: feed, media: media, webhook_url: url

    assert_not_nil request.reload.webhook_url
    assert_nil request.reload.last_called_webhook_at

    project_media = create_project_media team: team, media: media
    CheckSearch.any_instance.stubs(:medias).returns([project_media])
    publish_report(project_media)

    assert_nil request.reload.webhook_url
    assert_not_nil request.reload.last_called_webhook_at

    CheckSearch.any_instance.unstub(:medias)
  end

  test "should not delete feed if it has teams" do
    feed = create_feed
    feed_team = create_feed_team team: create_team, feed: feed
    assert_no_difference 'Feed.count' do
      assert_raises ActiveRecord::RecordNotDestroyed do
        feed.destroy!
      end
    end
    feed_team.destroy!
    assert_difference 'Feed.count', -1 do
      feed.reload.destroy!
    end
  end

  test "should delete invites when feed is deleted" do
    feed = create_feed
    feed_invitation1 = create_feed_invitation feed: feed
    feed_invitation2 = create_feed_invitation feed: feed
    assert_no_difference 'Feed.count' do
      feed_invitation1.destroy!
    end
    assert_difference 'FeedInvitation.count', -1 do
      feed.destroy!
    end
  end

  test "should create feed without data points" do
    feed = create_feed
    assert_equal [], feed.data_points
  end

  test "should create feed with valid data points" do
    feed = create_feed data_points: [1, 2]
    assert_equal [1, 2], feed.data_points
  end

  test "should not create feed with invalid data points" do
    assert_raises ActiveRecord::RecordInvalid do
      create_feed data_points: [0, 1]
    end
  end

  test "should not apply filters when medias are shared" do
    feed = create_feed data_points: [2], published: true
    assert_equal({}, feed.get_feed_filters(:media))
  end

  test "should return previous list" do
    team = create_team
    media_saved_search1 = create_saved_search team: team
    media_saved_search1 = create_saved_search team: team
    feed = create_feed team: team, media_saved_search: media_saved_search1
    feed.media_saved_search = media_saved_search1
    feed.save!
    assert_equal media_saved_search1, feed.saved_search_was
  end
end
