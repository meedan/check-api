require 'test_helper'

class GenericWorkerTest < ActiveSupport::TestCase
  def setup
    super
    require 'sidekiq/testing'
  end

  test "should schedule a job for a method that takes a hash: Tag creation" do
    Sidekiq::Testing.inline!

    t = create_team
    p = create_project team: t
    pm = create_project_media project: p

    assert_nothing_raised do
      GenericWorker.perform_async('Tag', 'create!', annotated_type: 'ProjectMedia' , annotated_id: pm.id, tag: 'test_tag', skip_check_ability: true, user_id: pm.user_id)
    end
  end

  test "should schedule a job for a method that takes a hash: Team creation" do
    Sidekiq::Testing.inline!

    assert_nothing_raised do
      GenericWorker.perform_async('Team', 'create!', name: 'BackgroundTeam', slug: 'background-team')
    end
  end

  test "should schedule a job for a method that takes standalone parameters" do
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
end
