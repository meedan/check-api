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

  test "should verify n + 1 for deduplicated TiplineRequest(CV2-5464)" do
    t = create_team
    pm = create_project_media team: t
    pm2 = create_project_media team: t
    pm3 = create_project_media team: t
    create_relationship source_id: pm.id, target_id: pm2.id, relationship_type: Relationship.confirmed_type
    [pm, pm2, pm3].each do |ass|
      create_tipline_request team_id: t.id, associated: ass
    end
    assert_queries(4, '=') {
      pm.get_deduplicated_tipline_requests
    }
    # Should add a new item for related_items_ids and got same queries count
    create_relationship source_id: pm.id, target_id: pm3.id, relationship_type: Relationship.confirmed_type
    [pm, pm2, pm3].each do |ass|
      create_tipline_request team_id: t.id, associated: ass
    end
    assert_queries(4, '=') {
      pm.get_deduplicated_tipline_requests
    }
  end
end
