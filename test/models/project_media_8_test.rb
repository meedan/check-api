require_relative '../test_helper'

class ProjectMedia8Test < ActiveSupport::TestCase
  def setup
    super
    require 'sidekiq/testing'
  end

  test "create tags when project media id and tags are present" do
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p

    ProjectMedia.create_tags_in_background(project_media_id: pm.id, tags_json: ['one', 'two'].to_json)
  end

  test "does not raise an error when no project media is sent" do
    ProjectMedia.create_tags_in_background(project_media_id: nil, tags_json: ['one', 'two'].to_json)
  end

  test "when creating an item with tag/tags, tags should be created in the background" do
    Sidekiq::Testing.inline!

    t = create_team
    p = create_project team: t
    assert_nothing_raised do
      create_project_media project: p, tags: ['one']
    end
  end

  test "when creating an item with multiple tags, only one job should be scheduled" do
    Sidekiq::Testing.fake!

    t = create_team
    p = create_project team: t
    assert_nothing_raised do
      create_project_media project: p, tags: ['one', 'two', 'three']
    end
    assert_equal 1, GenericWorker.jobs.size
  end
end
