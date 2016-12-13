require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class ElasticSearchWorkerTest < ActiveSupport::TestCase
  def setup
    super
    require 'sidekiq/testing'
    Sidekiq::Testing.fake!
  end

  test "should update media search in background" do
    t = create_team
    p = create_project team: t
    m = create_valid_media project_id: p.id
    assert_equal 3, ElasticSearchWorker.jobs.size
    ElasticSearchWorker.drain
    assert_equal 0, ElasticSearchWorker.jobs.size
    m.project_id = p.id
    m.information = {title: 'report_title'}.to_json
    m.save!
    assert_equal 2, ElasticSearchWorker.jobs.size
    ElasticSearchWorker.drain
    assert_equal 0, ElasticSearchWorker.jobs.size
    create_status context: p, annotated: m, status: 'false', disable_es_callbacks: false
    assert_equal 1, ElasticSearchWorker.jobs.size
    ElasticSearchWorker.drain
    assert_equal 0, ElasticSearchWorker.jobs.size
  end

  test "should add comment search in background" do
    t = create_team
    p = create_project team: t
    m = create_valid_media project_id: p.id
    ElasticSearchWorker.drain
    assert_equal 0, ElasticSearchWorker.jobs.size
    create_comment context: p, annotated: m, disable_es_callbacks: false
    assert_equal 1, ElasticSearchWorker.jobs.size
    ElasticSearchWorker.drain
    assert_equal 0, ElasticSearchWorker.jobs.size
  end

   test "should add tag search in background" do
    t = create_team
    p = create_project team: t
    m = create_valid_media project_id: p.id
    ElasticSearchWorker.drain
    assert_equal 0, ElasticSearchWorker.jobs.size
    create_tag context: p, annotated: m, disable_es_callbacks: false
    assert_equal 1, ElasticSearchWorker.jobs.size
    ElasticSearchWorker.drain
    assert_equal 0, ElasticSearchWorker.jobs.size
  end

end
