require_relative '../test_helper'

class FeedTeamTest < ActiveSupport::TestCase
  def setup
    super
    FeedTeam.delete_all
  end

  test "should create feed team" do
    f = create_feed
    t = create_team
    assert_difference 'FeedTeam.count' do
      f.teams << t
    end
  end

  test "should not create feed team if logged in user" do
    u = create_user
    t = create_team
    f = create_feed
    with_current_user_and_team u, t do
      assert_raises StandardError do
        f.teams << t
      end
    end
  end

  test "should have a list that belong to feed teams" do
    t = create_team
    f = create_feed
    ss = create_saved_search team: t
    ft = nil
    assert_difference 'FeedTeam.count' do
      ft = create_feed_team media_saved_search: ss, team_id: t.id, feed: f
    end
    assert_nothing_raised do
      ss.destroy
    end
    assert_nil ft.reload.media_saved_search_id
    assert_raises ActiveRecord::RecordInvalid do
      create_feed_team media_saved_search: create_saved_search, feed: f
    end
  end

  test "should get filters" do
    t = create_team
    ss = create_saved_search team: t, filters: { foo: 'bar'}
    ft = create_feed_team team_id: t.id, media_saved_search_id: ss.id
    assert_equal 'bar', ft.reload.filters['foo']
  end

  test "should have settings" do
    ft = create_feed_team settings: { foo: 'bar' }
    assert_equal 'bar', ft.reload.get_foo
    ft.set_bar = 'foo'
    ft.save!
    assert_equal 'foo', ft.reload.get_bar
  end

  test "should have a team and a feed" do
    t = create_team
    f = create_feed
    ft = create_feed_team team: t, feed: f
    assert_equal t, ft.reload.team
    assert_equal f, ft.reload.feed
  end

  test "should set requests filters" do
    ft = create_feed_team
    ft.requests_filters = { foo: 'bar' }
    ft.save!
    assert_equal 'bar', ft.reload.get_requests_filters[:foo]
  end

  test "should delete invitations when leaving feed" do
    u = create_user
    ft = create_feed_team
    create_team_user user: u, team: ft.team, role: 'admin'
    create_feed_invitation feed: ft.feed
    fi = create_feed_invitation email: u.email, feed: ft.feed
    assert_not_nil FeedInvitation.find_by_id(fi.id)
    User.current = u
    assert_difference 'FeedInvitation.count', -1 do
      ft.destroy!
    end
    User.current = nil
    assert_nil FeedInvitation.find_by_id(fi.id)
  end

  test "should return previous list" do
    t = create_team
    ss1 = create_saved_search team: t
    ss2 = create_saved_search team: t
    ft = create_feed_team team: t, media_saved_search: ss1
    ft.media_saved_search = ss2
    ft.save!
    assert_equal ss1, ft.saved_search_was
  end
end
