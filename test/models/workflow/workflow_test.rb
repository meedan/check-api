require_relative '../../test_helper'

class Workflow::WorkflowTest < ActiveSupport::TestCase
  test "should have list of workflows" do
    assert_includes Workflow::Workflow.workflows, Workflow::TranslationStatus
  end

  test "should have list of workflow ids" do
    assert_includes Workflow::Workflow.workflow_ids, 'translation_status'
  end

  test "should have a default workflow" do
    create_translation_status_stuff
    create_verification_status_stuff(false)
    t = create_team
    pm = create_project_media
    ts = pm.annotations.where(annotation_type: 'translation_status').last.load
    vs = pm.annotations.where(annotation_type: 'verification_status').last.load
    stub_config('default_workflow', 'verification_status') do
      assert_equal 'undetermined', pm.last_status
      assert_equal vs, pm.last_status_obj
      assert_equal 'verification_status', pm.default_media_status_type
      assert_equal t.get_media_verification_statuses, t.get_media_statuses
    end
    stub_config('default_workflow', 'translation_status') do
      assert_equal 'pending', pm.last_status
      assert_equal ts, pm.last_status_obj
      assert_equal 'translation_status', pm.default_media_status_type
      assert_equal t.get_media_translation_statuses, t.get_media_statuses
    end
  end
end
