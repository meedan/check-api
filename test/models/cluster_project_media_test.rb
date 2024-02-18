require_relative '../test_helper'

class ClusterProjectMediaTest < ActiveSupport::TestCase
  def setup
    super
    ClusterProjectMedia.delete_all
  end

  test "should create cluster project media" do
    assert_difference 'ClusterProjectMedia.count' do
      create_cluster_project_media
    end
  end

  test "should validate cluster and project media exists" do
    c = create_cluster
    pm = create_project_media
    assert_raises ActiveRecord::RecordInvalid do
      ClusterProjectMedia.create!(cluster: nil, project_media: pm)
    end
    assert_raises ActiveRecord::RecordInvalid do
      ClusterProjectMedia.create!(cluster: c, project_media: nil)
    end
  end
end
