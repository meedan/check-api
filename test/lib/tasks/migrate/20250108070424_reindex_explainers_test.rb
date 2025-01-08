require_relative '../../../test_helper'
require 'rake'

class ReindexExplainersTest < ActiveSupport::TestCase
  def setup
    Rake.application.rake_require('tasks/migrate/20250108070424_reindex_explainers')
    Rake::Task.define_task(:environment)
    Rake::Task['check:migrate:reindex_explainers'].reenable

    @explainer = create_explainer
    Explainer.stubs(:update_paragraphs_in_alegre).returns(true)
    Rails.cache.write('check:migrate:reindex_explainers:last_migrated_id', 0)
  end

  def teardown
    [@explainer].each(&:destroy)
    Rails.cache.delete('check:migrate:reindex_explainers:last_migrated_id')
    Explainer.unstub(:update_paragraphs_in_alegre)
  end

  test "should reindex explainers via rake task" do
    out, err = capture_io do
      Rake::Task['check:migrate:reindex_explainers'].invoke
    end

    Rake::Task['check:migrate:reindex_explainers'].reenable

    assert err.blank?, "Expected no errors, but got: #{err}"

    assert_match /Starting reindex of all explainers/, out
    assert_match /Successfully reindexed explainer with ID #{@explainer.id}/, out
    assert_match /Successfully reindexed all explainers/, out
  end
end
