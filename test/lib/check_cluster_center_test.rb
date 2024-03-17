require_relative '../test_helper'

class CheckClusterCenterTest < ActiveSupport::TestCase
  test "should get cluster center" do
    Sidekiq::Testing.fake!
    RequestStore.store[:skip_cached_field_update] = false
    team_a = create_team name: 'A - First team'
    team_b = create_team name: 'B - Second team'
    center = create_project_media team: team_a
    new_pm = create_project_media team: team_b
    ProjectMedia.where(id: [center.id, new_pm.id]).update_all(updated_at: Time.now)
    # Nothing match so should sort by Alphabetical team name
    assert_equal center.id, CheckClusterCenter.replace_or_keep_cluster_center(center.reload, new_pm.reload)
    # Match based on updated_at condition
    center.updated_at = Time.now - 1.month
    center.save!
    assert_equal new_pm.id, CheckClusterCenter.replace_or_keep_cluster_center(center.reload, new_pm.reload)
    # Still should match based on updated_at
    2.times { create_tipline_request(team_id: team_a.id, associated: center) }
    2.times { create_tipline_request(team_id: team_b.id, associated: new_pm) }
    assert_equal new_pm.id, CheckClusterCenter.replace_or_keep_cluster_center(center.reload, new_pm.reload)
    # Should match by requests_count
    create_tipline_request team_id: team_a.id, associated: center
    assert_equal center.id, CheckClusterCenter.replace_or_keep_cluster_center(center.reload, new_pm.reload)
    # Still should match based on requests_count
    cd_1 = create_claim_description project_media: center
    cd_2 = create_claim_description project_media: new_pm
    assert_equal center.id, CheckClusterCenter.replace_or_keep_cluster_center(center.reload, new_pm.reload)
    # Should match based on Claim
    cd_1.destroy!
    assert_equal new_pm.id, CheckClusterCenter.replace_or_keep_cluster_center(center.reload, new_pm.reload)
    # Should match based on Fact-Check
    publish_report(center)
    assert_equal center.id, CheckClusterCenter.replace_or_keep_cluster_center(center.reload, new_pm.reload)
    # Should match based on Claim
    publish_report(new_pm)
    assert_equal new_pm.id, CheckClusterCenter.replace_or_keep_cluster_center(center.reload, new_pm.reload)
  end
end
