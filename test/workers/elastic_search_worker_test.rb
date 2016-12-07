require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class ElasticSearchWorkerTest < ActiveSupport::TestCase

  test "should create media search in background" do
    es_queue = Sidekiq::Queue.new("ElasticSearchWorker")
    p = create_project
    m = create_valid_media
    assert_equal 0, es_queue.size
    #pm = create_project_media project: p, media: m
    #assert_equal 1, es_queue.size
    #ElasticSearchWorker::Worker.drain
    #assert_equal 0, es_queue.size
  end
end
