require_relative '../../test_helper'

class Workflow::WorkflowTest < ActiveSupport::TestCase
  test "should have list of workflows" do
    assert_includes Workflow::Workflow.workflows, Workflow::VerificationStatus
  end

  test "should have list of workflow ids" do
    assert_includes Workflow::Workflow.workflow_ids, 'verification_status'
  end

  test "should have a default workflow" do
    create_verification_status_stuff
    t = create_team
    pm = create_project_media
    vs = pm.annotations.where(annotation_type: 'verification_status').last.load
    stub_configs({ 'default_project_media_workflow' => 'verification_status' }) do
      assert_equal 'undetermined', pm.last_status
      assert_equal vs, pm.last_status_obj
      assert_equal 'verification_status', pm.default_project_media_status_type
      assert_equal t.get_media_verification_statuses, t.get_media_statuses
    end
  end
end
