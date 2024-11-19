require_relative '../test_helper'

class ClusterTest < ActiveSupport::TestCase
  def setup
    Sidekiq::Testing.fake!
    Cluster.delete_all
    User.current = Team.current = nil
  end

  def teardown
  end

  test "should create cluster" do
    assert_difference 'Cluster.count' do
      create_cluster
    end
  end

  test "should have a center" do
    pm = create_project_media
    c = create_cluster project_media: pm
    assert_equal pm, c.reload.center
  end

  test "should have items" do
    pm = create_project_media
    c = create_cluster project_media: pm
    pm1 = create_project_media cluster: c
    pm2 = create_project_media cluster: c
    assert_equal [pm, pm1, pm2].sort, c.reload.items.sort
  end

  test "should access cluster" do
    u = create_user
    t1 = create_team
    f1 = create_feed
    f1.teams << t1
    create_team_user user: u, team: t1

    # A cluster whose center is from the same team
    pm1 = create_project_media team: t1
    c1 = create_cluster project_media: pm1

    # A cluster from another feed
    t2 = create_team
    f2 = create_feed
    f2.teams << t2
    pm2 = create_project_media team: t2
    c2 = create_cluster project_media: pm2

    # A cluster from the same feed without any item from the team
    t3 = create_team
    f1.teams << t3
    pm3 = create_project_media team: t3
    c3 = create_cluster project_media: pm3

    # A cluster from the same feed with an item from the team
    t4 = create_team
    f1.teams << t4
    pm4 = create_project_media team: t4
    c4 = create_cluster project_media: pm4
    c4.project_medias << create_project_media(team: t1)

    a = Ability.new(u, t1)
    assert a.can?(:read, c1.feed)
    assert a.can?(:read, c1)
    assert !a.can?(:read, c2.feed)
    assert !a.can?(:read, c2)
    assert !a.can?(:read, c3.feed)
    assert !a.can?(:read, c3)
    assert !a.can?(:read, c4.feed)
    assert !a.can?(:read, c4)
  end

  test "should return size" do
    c = create_cluster
    assert_equal 1, c.size
    c.project_medias << create_project_media
    assert_equal 2, c.size
  end

  test "should return full URL to cluster" do
    c = create_cluster
    assert_match /^http/, c.full_url
  end

  test "should return team names" do
    t1 = create_team name: 'Foo'
    t2 = create_team name: 'Bar'
    c = create_cluster
    c.update_column :team_ids, [t1.id, t2.id]
    assert_equal ['Foo', 'Bar'], c.team_names
  end

  test "should return ratings" do
    c = create_cluster
    c.project_medias << create_project_media
    assert_equal ['Unstarted'], c.ratings
  end
end
