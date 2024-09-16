require 'test_helper'

class GenericWorkerTest < ActiveSupport::TestCase
  def setup
    require 'sidekiq/testing'
    Sidekiq::Worker.clear_all
  end

  def teardown
  end

  test "should run a job, without raising an error, for a method that takes a hash as a parameter" do
    Sidekiq::Testing.inline!

    assert_difference "Team.where(name: 'BackgroundTeam', slug: 'background-team').count" do
      GenericWorker.perform_async('Team', 'create!', name: 'BackgroundTeam', slug: 'background-team')
    end
  end

  test "should run a job, without raising an error, for a method that takes standalone parameters" do
    Sidekiq::Testing.inline!

    t = create_team
    p = create_project team: t
    pm = create_project_media project: p

    project_media_id = pm.id
    tags_json = ['one', 'two'].to_json

    assert_nothing_raised do
      GenericWorker.perform_async('ProjectMedia', 'create_tags', project_media_id, tags_json, user_id: pm.user_id)
    end
  end

  test "should schedule a job, without raising an error, for a method that takes a hash as a parameter" do
    Sidekiq::Testing.fake!

    assert_nothing_raised do
      GenericWorker.perform_async('Team', 'create!', name: 'BackgroundTeam', slug: 'background-team')
    end

    assert_equal 1, GenericWorker.jobs.size
  end

  test "should schedule a job, without raising an error, for a method that takes standalone parameters" do
    Sidekiq::Testing.fake!

    t = create_team
    p = create_project team: t
    pm = create_project_media project: p

    project_media_id = pm.id
    tags_json = ['one', 'two'].to_json

    assert_nothing_raised do
      GenericWorker.perform_async('ProjectMedia', 'create_tags', project_media_id, tags_json, user_id: pm.user_id)
    end

    assert_equal 1, GenericWorker.jobs.size
  end
end
