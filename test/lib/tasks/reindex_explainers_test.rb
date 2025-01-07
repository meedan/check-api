require_relative '../../test_helper'
require 'rake'

class ReindexExplainersTest < ActiveSupport::TestCase
  def setup
    super
    require 'sidekiq/testing'
    Sidekiq::Testing.inline!

    Rake.application.rake_require("tasks/data/reindex_explainers")
    Rake::Task.define_task(:environment)
    Rake::Task['check:data:reindex_explainers'].reenable

    @explainer_annotation_type = 'explainer'

    # Create an explainer ProjectMedia
    @explainer_pm = create_project_media
    create_annotation(annotation_type: @explainer_annotation_type, annotated: @explainer_pm)

    # Mock Alegre behavior
    Bot::Alegre.stubs(:query_async_with_params).returns("done")
    Bot::Alegre.stubs(:send_to_text_similarity_index_package).returns({})
  end

  def teardown
    super
    [@explainer_pm].each(&:destroy)
    Annotation.delete_all
    ProjectMedia.delete_all
    Bot::Alegre.unstub(:query_async_with_params)
    Bot::Alegre.unstub(:send_to_text_similarity_index_package)
  end

  test "should reindex explainers via rake task" do
    out, err = capture_io do
      Rake::Task['check:data:reindex_explainers'].invoke
    end
  
    Rake::Task['check:data:reindex_explainers'].reenable
  
    assert err.blank?, "Expected no errors, but got: #{err}"
    assert_match /Starting reindex of all explainers/, out
    assert_match /Found 1 explainers to reindex/, out
    assert_match /Successfully reindexed all explainers/, out
  end
end
