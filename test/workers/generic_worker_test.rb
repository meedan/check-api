require 'test_helper'

class GenericWorkerTest < ActiveSupport::TestCase
  def setup
    require 'sidekiq/testing'
    WebMock.disable_net_connect! allow: /http:\/\/bot|#{CheckConfig.get('elasticsearch_host')}|#{CheckConfig.get('storage_endpoint')}/
    Sidekiq::Worker.clear_all
  end

  def teardown
  end

  test "should run a job, without raising an error, for a method that takes no parameters" do
    Sidekiq::Testing.inline!

    assert_difference 'Blank.count' do
      GenericWorker.perform_async('Blank', 'create!')
    end
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
    pm = create_project_media team: t
    project_media_id = pm.id
    tags_json = ['one', 'two'].to_json
    assert_difference "Tag.where(annotation_type: 'tag').count", 2 do
      GenericWorker.perform_async('Tag', 'create_project_media_tags', project_media_id, tags_json, user_id: pm.user_id)
    end
    tags_json = [''].to_json
    assert_nothing_raised do
      assert_no_difference "Tag.where(annotation_type: 'tag').count" do
        GenericWorker.perform_async('Tag', 'create_project_media_tags', project_media_id, tags_json, user_id: pm.user_id)
      end
    end
  end

  test "should schedule a job, without raising an error, for a method that takes no parameters" do
    Sidekiq::Testing.fake!

    assert_nothing_raised do
      GenericWorker.perform_async('Media', 'types')
    end

    assert_equal 1, GenericWorker.jobs.size
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
    pm = create_project_media team: t
    project_media_id = pm.id
    tags_json = ['one', 'two'].to_json
    assert_nothing_raised do
      GenericWorker.perform_async('Tag', 'create_project_media_tags', project_media_id, tags_json, user_id: pm.user_id)
    end
    assert_equal 1, GenericWorker.jobs.size
  end
end
