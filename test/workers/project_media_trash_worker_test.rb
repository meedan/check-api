require_relative '../test_helper'

class ProjectMediaTrashWorkerTest < ActiveSupport::TestCase
  def setup
    super
    require 'sidekiq/testing'
    Sidekiq::Testing.inline!
  end

  test "should destroy trashed items" do
    pm = create_project_media
    id = pm.id
    pm.archived = CheckArchivedFlags::FlagCodes::TRASHED
    pm.save!
    pm = ProjectMedia.find_by_id(id)
    assert_nil pm
  end
end
