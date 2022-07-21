require_relative '../test_helper'

class ProjectMediaCacheWorkerTest < ActiveSupport::TestCase
  def setup
    super
    require 'sidekiq/testing'
    RequestStore.store[:skip_cached_field_update] = false
    Sidekiq::Testing.inline!
  end

  test "should cache data" do
    pm = create_project_media
    assert_queries(10, '>') { ProjectMediaCacheWorker.perform_async(pm.id) }
    assert_queries(2, '=') { ProjectMediaCacheWorker.perform_async(pm.id) }
  end
end
