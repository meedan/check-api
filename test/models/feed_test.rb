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
    u = create_user
    t = create_team
    with_current_user_and_team u, t do
      assert_raises StandardError do
        create_feed
      end
    end
  end

  test "should have filters" do
    f = create_feed filters: { foo: 'bar' }
    assert_equal 'bar', f.reload.filters['foo']
  end

  test "should have settings" do
    f = create_feed settings: { foo: 'bar' }
    assert_equal 'bar', f.reload.get_foo
    f.set_bar = 'foo'
    f.save!
    assert_equal 'foo', f.reload.get_bar
  end

  test "should have teams" do
    t = create_team
    f = create_feed
    f.teams << t
    assert_equal [t], f.reload.teams
  end

  test "should access feed" do
    u = create_user
    t1 = create_team
    create_team_user user: u, team: t1
    t2 = create_team
    f1 = create_feed
    f1.teams << t1
    f2 = create_feed
    f2.teams << t2

    a = Ability.new(u, t1)
    assert a.can?(:read, f1)
    assert !a.can?(:read, f2)

    a = Ability.new(u, t2)
    assert a.can?(:read, f1)
    assert !a.can?(:read, f2)
  end
end
