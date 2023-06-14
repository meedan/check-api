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

  # TODO: fix by sawy (change permission check)
  # test "should not create feed if logged in user" do
  #   u = create_user
  #   t = create_team
  #   create_team_user team: t, user: u, role: 'admin'
  #   with_current_user_and_team(u, t) do
  #     assert_raises StandardError do
  #       create_feed
  #     end
  #   end
  # end

  # TODO: fix by sawy
  # test "should have filters" do
  #   f = create_feed filters: { foo: 'bar' }
  #   assert_equal 'bar', f.reload.filters['foo']
  # end

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

  test "should have name and description" do
    assert_raises ActiveRecord::RecordInvalid do
      create_feed name: nil
    end
    assert_raises ActiveRecord::RecordInvalid do
      create_feed description: nil
    end
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

  test "should get number of root requests" do
    f = create_feed
    r = create_request feed: f
    create_request feed: f, request_id: r.id
    assert_equal 2, f.requests_count
    assert_equal 1, f.root_requests_count
  end

  # TODO: fix by sawy
  # test "should notify subscribers" do
  #   Sidekiq::Testing.inline!
  #   url = URI.join(random_url, "user/#{random_number}")
  #   WebMock.stub_request(:post, url)
  #   f = create_feed published: true
  #   t = create_team
  #   f.teams << t
  #   FeedTeam.update_all shared: true
  #   m = create_uploaded_image

  #   r = create_request feed: f, media: m, webhook_url: url

  #   assert_not_nil r.reload.webhook_url
  #   assert_nil r.reload.last_called_webhook_at

  #   pm = create_project_media team: t, media: m
  #   CheckSearch.any_instance.stubs(:medias).returns([pm])
  #   publish_report(pm)

  #   assert_nil r.reload.webhook_url
  #   assert_not_nil r.reload.last_called_webhook_at

  #   CheckSearch.any_instance.unstub(:medias)
  # end
end
