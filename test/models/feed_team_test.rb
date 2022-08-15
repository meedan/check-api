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

  test "should have filters" do
    ft = create_feed_team filters: { foo: 'bar' }
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
end
