require_relative '../test_helper'

class ClusterTest < ActiveSupport::TestCase
  def setup
    super
    Cluster.delete_all
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
    c = create_cluster
    pm1 = create_project_media cluster: c
    pm2 = create_project_media cluster: c
    assert_equal [pm1, pm2].sort, c.reload.items.sort
  end

  test "should remove items from cluster when cluster is deleted" do
    c = create_cluster
    pm1 = create_project_media cluster: c
    pm2 = create_project_media cluster: c
    assert_equal [c.id], pm1.reload.cluster_ids
    assert_equal [c.id], pm2.reload.cluster_ids
    c.destroy!
    assert_empty pm1.reload.cluster_ids
    assert_empty pm2.reload.cluster_ids
  end

  test "should cache number of items in the cluster" do
    c = create_cluster
    assert_equal 0, c.reload.size
    pm1 = create_project_media cluster: c
    assert_equal 1, c.reload.size
    pm2 = create_project_media cluster: c
    assert_equal 2, c.reload.size
    pm1.destroy!
    assert_equal 1, c.reload.size
    pm2.destroy!
    assert_equal 0, c.reload.size
  end

  test "should get requests count" do
    RequestStore.store[:skip_cached_field_update] = false
    t = create_team
    Sidekiq::Testing.inline! do
      c = create_cluster
      pm = create_project_media team: t
      2.times { create_tipline_request(team_id: t.id, associated: pm) }
      pm2 = create_project_media team: t
      2.times { create_tipline_request(team_id: t.id, associated: pm2) }
      c.project_medias << pm
      c.project_medias << pm2
      assert_equal 4, c.requests_count
      assert_equal 4, c.requests_count(true)
      d = create_tipline_request team_id: t.id, associated: pm
      assert_equal 5, c.requests_count
      assert_equal 5, c.requests_count(true)
      d.destroy!
      assert_equal 4, c.requests_count
      assert_equal 4, c.requests_count(true)
    end
  end

  test "should get teams that fact-checked the item" do
    c = create_cluster
    assert_kind_of Hash, c.get_names_of_teams_that_fact_checked_it
  end

  test "should get claim descriptions" do
    c = create_cluster
    pm1 = create_project_media
    cd1 = create_claim_description project_media: pm1
    c.project_medias << pm1
    pm2 = create_project_media
    cd2 = create_claim_description project_media: pm2
    c.project_medias << pm2
    assert_equal [cd1, cd2], c.claim_descriptions.sort
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
end
