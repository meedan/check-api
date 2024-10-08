require_relative '../test_helper'

class ProjectGroupTest < ActiveSupport::TestCase
  def setup
    require 'sidekiq/testing'
    super
    ProjectGroup.delete_all
  end

  test "should create project group" do
    assert_difference 'ProjectGroup.count' do
      create_project_group
    end
  end

  test "should not create project group if title is not present" do
    assert_no_difference 'ProjectGroup.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_project_group title: nil
      end
    end
  end

  test "should not create project group if team is not present" do
    assert_no_difference 'ProjectGroup.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_project_group team: nil
      end
    end
  end

  test "should belong to team" do
    t = create_team
    pg = create_project_group team: t
    assert_equal t, pg.reload.team
    assert_equal [pg], t.reload.project_groups
  end

  test "should have project medias" do
    t = create_team
    pg = create_project_group team: t
    p = create_project team: t
    pm = ProjectMedia.create! team: t, project: p, quote: random_string
    create_project_media
    p.project_group = pg
    p.save!
    assert_equal [pm], pg.reload.project_medias
  end
end
