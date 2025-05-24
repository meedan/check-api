require_relative '../test_helper'

class GenericWorkerHelpersTest < ActionView::TestCase
  def setup
    require 'sidekiq/testing'
    Sidekiq::Worker.clear_all
  end

  def teardown
  end

  test "should run a job async, without raising an error, for a method that takes a hash as a parameter" do
    Sidekiq::Testing.inline!

    assert_difference "Team.where(name: 'BackgroundTeam', slug: 'background-team').count" do
      Team.run_later('create!', name: 'BackgroundTeam', slug: 'background-team')
    end
  end

  test "should run a job in a specified time, without raising an error, for a method that takes standalone parameters" do
    Sidekiq::Testing.inline!

    team = create_team
    pm = create_project_media team: team

    project_media_id = pm.id
    tags_json = ['one', 'two', 'three'].to_json

    Tag.run_later_in(0.second, 'create_project_media_tags', project_media_id, tags_json, user_id: pm.user_id)

    assert_equal 3, pm.annotations('tag').count
  end
end
