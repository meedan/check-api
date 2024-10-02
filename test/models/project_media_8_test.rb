require_relative '../test_helper'

class ProjectMedia8Test < ActiveSupport::TestCase
  def setup
    require 'sidekiq/testing'
    Sidekiq::Worker.clear_all
  end

  def teardown
  end

  test "when creating an item with tag/tags, after_create :create_tags_in_background callback should create tags in the background" do
    Sidekiq::Testing.inline!

    team = create_team
    project = create_project team: team
    pm = create_project_media project: project, tags: ['one']

    assert_equal 1, pm.annotations('tag').count
  end

  test "when creating an item with multiple tags, after_create :create_tags_in_background callback should only schedule one job" do
    Sidekiq::Testing.fake!

    team = create_team
    project = create_project team: team

    assert_nothing_raised do
      create_project_media project: project, tags: ['one', 'two', 'three']
    end
    assert_equal 1, GenericWorker.jobs.size
  end

  test "when creating an item with multiple tags, after_create :create_tags_in_background callback should not create duplicate tags" do
    Sidekiq::Testing.inline!

    team = create_team
    project = create_project team: team
    pm = create_project_media project: project, tags: ['one', 'one', '#one']

    assert_equal 1, pm.annotations('tag').count
  end
end
