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

  test "should have medias count" do
    RequestStore.store[:skip_cached_field_update] = false
    t = create_team
    pg = create_project_group team: t
    assert_equal 0, pg.medias_count
    p1 = create_project team: t
    p1.project_group = pg
    p1.save!
    assert_equal 0, p1.medias_count
    create_project_media project: p1
    assert_equal 1, p1.medias_count
    create_project_media project: p1
    assert_equal 2, p1.medias_count
    p2 = create_project team: t
    p2.project_group = pg
    p2.save!
    assert_equal 0, p2.medias_count
    create_project_media project: p2
    assert_equal 1, p2.medias_count
    assert_equal 3, pg.reload.medias_count
  end
end
