require_relative '../test_helper'

class ProjectMedia8Test < ActiveSupport::TestCase
  def setup
    require 'sidekiq/testing'
    Sidekiq::Worker.clear_all
  end

  def teardown
  end

  test ":create_tags should create tags when project media id and tags are present" do
    team = create_team
    project = create_project team: team
    pm = create_project_media project: project

    project_media_id = pm.id
    tags_json = ['one', 'two'].to_json

    assert_nothing_raised do
      ProjectMedia.create_tags(project_media_id, tags_json)
    end
    assert_equal 2, pm.annotations('tag').count
  end

  test ":create_tags should not raise an error when no project media is sent" do
    project_media_id = nil
    tags_json = ['one', 'two'].to_json

    assert_nothing_raised do
      CheckSentry.expects(:notify).once
      ProjectMedia.create_tags(project_media_id, tags_json)
    end
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

  test "when using :run_later_in to schedule multiple tags creation, it should only schedule one job" do
    Sidekiq::Testing.fake!

    team = create_team
    project = create_project team: team
    pm = create_project_media project: project

    project_media_id = pm.id
    tags_json = ['one', 'two', 'three'].to_json

    ProjectMedia.run_later_in(0.second, 'create_tags', project_media_id, tags_json, user_id: pm.user_id)

    assert_equal 1, GenericWorker.jobs.size
  end

  test "when using :run_later_in to schedule multiple tags creation, tags should be created" do
    Sidekiq::Testing.inline!

    team = create_team
    project = create_project team: team
    pm = create_project_media project: project

    project_media_id = pm.id
    tags_json = ['one', 'two', 'three'].to_json

    ProjectMedia.run_later_in(0.second, 'create_tags', project_media_id, tags_json, user_id: pm.user_id)

    assert_equal 3, pm.annotations('tag').count
  end
end
