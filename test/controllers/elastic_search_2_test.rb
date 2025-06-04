require_relative '../test_helper'

class ElasticSearch2Test < ActionController::TestCase
  def setup
    super
    setup_elasticsearch
  end

  test "should destroy elasticseach project media" do
    t = create_team
    pm = create_project_media team: t, disable_es_callbacks: false
    sleep 1
    id = get_es_id(pm)
    assert_not_nil $repository.find(id)
    Sidekiq::Testing.inline! do
      pm.destroy
      sleep 1
      assert_raise Elasticsearch::Persistence::Repository::DocumentNotFound do
        result = $repository.find(id)
      end
    end
  end

  test "should update elasticsearch after refresh pender data" do
    create_verification_status_stuff
    RequestStore.store[:skip_cached_field_update] = false
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url = random_url
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: '{"type":"media","data":{"url":"' + url + '","type":"item","title":"org_title"}}')
    WebMock.stub_request(:get, pender_url).with({ query: { url: url, refresh: '1' } }).to_return(body: '{"type":"media","data":{"url":"' + url + '","type":"item","title":"new_title"}}')
    t = create_team
    t2 = create_team
    m = create_media url: url
    pm = create_project_media team: t, media: m, disable_es_callbacks: false
    pm2 = create_project_media team: t2, media: m, disable_es_callbacks: false
    sleep 1
    ms = $repository.find(get_es_id(pm))
    assert_equal 'org_title', pm.title
    assert_equal 'org_title', ms['title']
    ms2 = $repository.find(get_es_id(pm2))
    assert_equal pm2.title, 'org_title'
    assert_equal ms2['title'], 'org_title'
    Sidekiq::Testing.inline! do
      # Update title
      pm2.reload; pm2.disable_es_callbacks = false
      create_claim_description project_media: pm2, description: 'overridden_title'
      pm.reload; pm.disable_es_callbacks = false
      pm.refresh_media = true
      pm.save!
      pm2.reload; pm2.disable_es_callbacks = false
      pm2.refresh_media = true
      pm2.save!
    end
    sleep 2
    ms2 = $repository.find(get_es_id(pm2))
    assert_equal 'overridden_title', ms2['title']
    ms = $repository.find(get_es_id(pm))
    assert_equal 'new_title', ms['title']
    assert_equal 'new_title', pm.reload.title
  end

  test "should add or destroy es for annotations in background" do
    Sidekiq::Testing.fake!
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    with_current_user_and_team(u, t) do
      pm = create_project_media team: t, disable_es_callbacks: false
      # add tag
      ElasticSearchWorker.clear
      t = create_tag annotated: pm, disable_es_callbacks: false
      assert_equal 2, ElasticSearchWorker.jobs.size
      # destroy tag
      ElasticSearchWorker.clear
      t.destroy
    assert_equal 2, ElasticSearchWorker.jobs.size
    end
  end

  test "should update status in background" do
    m = create_valid_media
    Sidekiq::Testing.fake! do
      Sidekiq::Worker.clear_all
      ElasticSearchWorker.clear
      assert_equal 0, ElasticSearchWorker.jobs.size
      pm = create_project_media media: m, disable_es_callbacks: false
      assert ElasticSearchWorker.jobs.size > 0
    end
  end

  [:asc, :desc].each do |order|
    test "should sort by item title #{order}" do
      RequestStore.store[:skip_cached_field_update] = false
      pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
      url = 'http://test.com'
      response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "b-item"}}'
      WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
      l = create_media(account: create_valid_account, url: url)
      i = create_uploaded_image file: 'c-item.png'
      v = create_uploaded_video file: 'd-item.mp4'
      a = create_uploaded_audio file: 'e-item.mp3'
      t = create_team
      pm1 = create_project_media team: t, quote: 'a-item', disable_es_callbacks: false
      pm2 = create_project_media team: t, media: l, disable_es_callbacks: false
      pm3 = create_project_media team: t, media: i, disable_es_callbacks: false
      pm3.analysis = { file_title: 'c-item' }; pm3.save
      pm4 = create_project_media team: t, media: v, disable_es_callbacks: false
      pm4.analysis = { file_title: 'd-item' }; pm4.save
      pm5 = create_project_media team: t, media: a, disable_es_callbacks: false
      pm5.analysis = { file_title: 'e-item' }; pm5.save
      sleep 2
      orders = {asc: [pm1, pm2, pm3, pm4, pm5], desc: [pm5, pm4, pm3, pm2, pm1]}
      query = { keyword: 'item', sort: 'title', sort_type: order.to_s }
      result = CheckSearch.new(query.to_json, nil, t.id)
      assert_equal 5, result.medias.count
      assert_equal orders[order.to_sym].map(&:id), result.medias.map(&:id)
      query = { sort: 'title', sort_type: order.to_s }
      result = CheckSearch.new(query.to_json, nil, t.id)
      assert_equal 5, result.medias.count
      assert_equal orders[order.to_sym].map(&:id), result.medias.map(&:id)
      # update analysis
      pm3.analysis = { file_title: 'f-item' }
      pm6 = create_project_media team: t, quote: 'DUPPER-item', disable_es_callbacks: false
      sleep 2
      orders = {asc: [pm1, pm2, pm4, pm6, pm5, pm3], desc: [pm3, pm5, pm6, pm4, pm2, pm1]}
      result = CheckSearch.new(query.to_json, nil, t.id)
      assert_equal 6, result.medias.count
      assert_equal orders[order.to_sym].map(&:id), result.medias.map(&:id)
    end
  end

  test "should search by source" do
    t = create_team
    s = create_source team: t
    s2 = create_source team: t
    s3 = create_source team: t
    pm = create_project_media team: t, source: s, disable_es_callbacks: false, skip_autocreate_source: false
    pm2 = create_project_media team: t, source: s, disable_es_callbacks: false, skip_autocreate_source: false
    pm3 = create_project_media team: t, source: s2, disable_es_callbacks: false, skip_autocreate_source: false
    sleep 2
    result = CheckSearch.new({ sources: [s.id] }.to_json, nil, t.id)
    assert_equal [pm.id, pm2.id], result.medias.map(&:id).sort
    result = CheckSearch.new({ sources: [s2.id] }.to_json, nil, t.id)
    assert_equal [pm3.id], result.medias.map(&:id)
    result = CheckSearch.new({ sources: [s.id, s2.id] }.to_json, nil, t.id)
    assert_equal [pm.id, pm2.id, pm3.id], result.medias.map(&:id).sort
    result = CheckSearch.new({ sources: [s3.id] }.to_json, nil, t.id)
    assert_empty result.medias
    result = CheckSearch.new({ sources: [s2.id], show: ['claims'] }.to_json, nil, t.id)
    assert_equal [pm3.id], result.medias.map(&:id)
  end

  test "should search trash and unconfirmed items" do
    t = create_team
    pm = create_project_media team: t, disable_es_callbacks: false
    pm2 = create_project_media team: t, archived: CheckArchivedFlags::FlagCodes::TRASHED, disable_es_callbacks: false
    pm3 = create_project_media team: t, archived: CheckArchivedFlags::FlagCodes::TRASHED, disable_es_callbacks: false
    pm4 = create_project_media team: t, archived: CheckArchivedFlags::FlagCodes::UNCONFIRMED, disable_es_callbacks: false
    sleep 2
    assert_equal [pm2, pm3], pm.check_search_trash.medias.sort
    assert_equal [pm, pm4], t.check_search_team.medias.sort
  end

  test "should adjust ES window size" do
    t = create_team
    u = create_user
    pm = create_project_media quote: 'claim a', disable_es_callbacks: false
    sleep 2
    create_team_user team: t, user: u, role: 'admin'
    with_current_user_and_team(u ,t) do
      assert_nothing_raised do
        query = 'query Search { search(query: "{\"keyword\":\"claim\",\"eslimit\":20000,\"esoffset\":0}") {medias(first:20){edges{node{dbid}}}}}'
        post :create, params: { query: query }
        assert_response :success
        query = 'query Search { search(query: "{\"keyword\":\"claim\",\"eslimit\":10000,\"esoffset\":20}") {medias(first:20){edges{node{dbid}}}}}'
        post :create, params: { query: query }
        assert_response :success
      end
    end
  end

  # Please add new tests to test/controllers/elastic_search_7_test.rb
end
