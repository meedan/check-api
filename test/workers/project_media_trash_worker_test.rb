require_relative '../test_helper'

class ProjectMediaTrashWorkerTest < ActiveSupport::TestCase
  def setup
    require 'sidekiq/testing'
    Sidekiq::Testing.inline!
    Team.current = User.current = nil
  end

  test "should destroy trashed items" do
    pm = create_project_media
    id = pm.id
    pm.archived = CheckArchivedFlags::FlagCodes::TRASHED
    pm.save!
    pm = ProjectMedia.find_by_id(id)
    assert_nil pm
  end

  test "should notify error when destroy item" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'collaborator'
    with_current_user_and_team(u, t) do
      pm = create_project_media
      pm.archived = CheckArchivedFlags::FlagCodes::TRASHED
      pm.save!
    end
  end
end
