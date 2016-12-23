require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class ElasticSearchWorkerTest < ActiveSupport::TestCase
  def setup
    super
    require 'sidekiq/testing'
    Sidekiq::Testing.fake!
  end

  test "should update media search in background" do
    ElasticSearchWorker.drain
    t = create_team
    p = create_project team: t
    pender_url = CONFIG['pender_host'] + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "test media", "description":"add desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m = create_media(account: create_valid_account, url: url, project_id: p.id)
    assert_equal 2, ElasticSearchWorker.jobs.size
  end

  test "should add comment search in background" do
    t = create_team
    p = create_project team: t
    m = create_valid_media project_id: p.id
    ElasticSearchWorker.drain
    assert_equal 0, ElasticSearchWorker.jobs.size
    create_comment context: p, annotated: m, disable_es_callbacks: false
    assert_equal 1, ElasticSearchWorker.jobs.size
  end

  test "should add tag search in background" do
    t = create_team
    p = create_project team: t
    m = create_valid_media project_id: p.id
    ElasticSearchWorker.drain
    assert_equal 0, ElasticSearchWorker.jobs.size
    create_tag context: p, annotated: m, disable_es_callbacks: false
    assert_equal 1, ElasticSearchWorker.jobs.size
  end

  test "should update title or description in background" do
    t = create_team
    p = create_project team: t
    m = create_valid_media project_id: p.id
    ElasticSearchWorker.drain
    assert_equal 0, ElasticSearchWorker.jobs.size
    m.project_id = p.id
    m.information = {title: 'title', description: 'description'}.to_json
    m.save!
    assert_equal 1, ElasticSearchWorker.jobs.size
  end

  test "should update status in background" do
    t = create_team
    p = create_project team: t
    m = create_valid_media project_id: p.id
    ElasticSearchWorker.drain
    create_status context: p, annotated: m, status: 'false', disable_es_callbacks: false
    assert_equal 1, ElasticSearchWorker.jobs.size
  end

end
