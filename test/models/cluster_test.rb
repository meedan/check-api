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

  test "should not create cluster if center is not present" do
    assert_no_difference 'Cluster.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_cluster project_media: nil
      end
    end
  end

  test "should not have two clusters with same center (Rails validation)" do
    pm = create_project_media
    create_cluster project_media: pm
    assert_no_difference 'Cluster.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_cluster project_media: pm
      end
    end
  end

  test "should not have two clusters with same center (database validation)" do
    pm = create_project_media
    create_cluster project_media: pm
    c = create_cluster
    assert_raises ActiveRecord::RecordNotUnique do
      c.update_column :project_media_id, pm.id
    end
  end

  test "should remove items from cluster when cluster is deleted" do
    c = create_cluster
    pm1 = create_project_media cluster: c
    pm2 = create_project_media cluster: c
    assert_equal c.id, pm1.reload.cluster_id
    assert_equal c.id, pm2.reload.cluster_id
    c.destroy!
    assert_nil pm1.reload.cluster_id
    assert_nil pm2.reload.cluster_id
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

  test "should not have the center belonging to another cluster" do
    pm = create_project_media
    c = create_cluster
    c.project_medias << pm
    assert_raises ActiveRecord::RecordInvalid do
      assert_no_difference 'Cluster.count' do
        create_cluster project_media: pm
      end
    end
  end

  test "should set cluster" do
    t = create_team
    pm1 = create_project_media team: t
    c = create_cluster
    c.project_medias << pm1
    pm2 = create_project_media team: t
    ProjectMedia.any_instance.stubs(:similar_items_ids_and_scores).returns({ pm1.id => { score: 0.9, context: {} }, random_number => { score: 0.8, context: { foo: 'bar' } } })
    assert_equal c, Bot::Alegre.set_cluster(pm2)
    ProjectMedia.any_instance.unstub(:similar_items_ids_and_scores)
  end

  # TODO: fix by Sawy
  # test "should get requests count" do
  #   create_annotation_type_and_fields('Smooch', { 'Data' => ['JSON', true] })
  #   ProjectMedia.any_instance.stubs(:requests_count).returns(2)
  #   Sidekiq::Testing.inline! do
  #     c = create_cluster
  #     2.times { c.project_medias << create_project_media }
  #     assert_equal 4, c.requests_count
  #     RequestStore.store[:skip_cached_field_update] = false
  #     pm = c.project_medias.last
  #     d = Dynamic.create! annotation_type: 'smooch', annotated: pm
  #     assert_equal 5, c.requests_count
  #     d.destroy!
  #     assert_equal 4, c.requests_count
  #   end
  #   ProjectMedia.any_instance.unstub(:requests_count)
  # end

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
    c1.project_medias << pm1

    # A cluster from another feed
    t2 = create_team
    f2 = create_feed
    f2.teams << t2
    pm2 = create_project_media team: t2
    c2 = create_cluster project_media: pm2
    c2.project_medias << pm2

    # A cluster from the same feed without any item from the team
    t3 = create_team
    f1.teams << t3
    pm3 = create_project_media team: t3
    c3 = create_cluster project_media: pm3
    c3.project_medias << pm3

    # A cluster from the same feed with an item from the team
    t4 = create_team
    f1.teams << t4
    pm4 = create_project_media team: t4
    c4 = create_cluster project_media: pm4
    c4.project_medias << pm4
    c4.project_medias << create_project_media(team: t1)

    a = Ability.new(u, t1)
    assert a.can?(:read, c1)
    assert !a.can?(:read, c2)
    assert a.can?(:read, c3)
    assert a.can?(:read, c4)
  end
end
