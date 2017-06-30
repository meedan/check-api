require_relative '../test_helper'

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
    m = create_media(account: create_valid_account, url: url)
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    assert_equal 1, ElasticSearchWorker.jobs.size
  end

  test "should add comment search in background" do
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p, disable_es_callbacks: false
    ElasticSearchWorker.drain
    assert_equal 0, ElasticSearchWorker.jobs.size
    create_comment annotated: pm, disable_es_callbacks: false
    assert_equal 1, ElasticSearchWorker.jobs.size
  end

  test "should add tag search in background" do
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p
    ElasticSearchWorker.drain
    assert_equal 0, ElasticSearchWorker.jobs.size
    create_tag annotated: pm, disable_es_callbacks: false
    assert_equal 1, ElasticSearchWorker.jobs.size
  end

  test "should update title or description in background" do
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p
    ElasticSearchWorker.drain
    assert_equal 0, ElasticSearchWorker.jobs.size
    pm.embed= {title: 'title', description: 'description'}.to_json
    assert_equal 1, ElasticSearchWorker.jobs.size
  end

  test "should update status in background" do
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p
    ElasticSearchWorker.drain
    create_status annotated: pm, status: 'false', disable_es_callbacks: false
    assert_equal 1, ElasticSearchWorker.jobs.size
  end

end
