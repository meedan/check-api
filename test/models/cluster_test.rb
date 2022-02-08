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
end 
