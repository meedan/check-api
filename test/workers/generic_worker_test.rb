require 'test_helper'

class GenericWorkerTest < ActiveSupport::TestCase
  def setup
    super
    require 'sidekiq/testing'
  end

  test "should schedule a job for any class" do
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p

    assert_nothing_raised do
      GenericWorker.perform_async('Tag', 'create!', annotated: pm, tag: 'test_tag', skip_check_ability: true)
    end
    assert_equal 1, GenericWorker.jobs.size
  end
end
