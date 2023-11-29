require_relative '../test_helper'

class ElasticSearch3Test < ActionController::TestCase
  def setup
    super
    setup_elasticsearch
  end

  test "should search with diacritics pt" do
    t = create_team
    p = create_project team: t
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "coração", "description":"vovô foi à são paulo"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m = create_media(account: create_valid_account, url: url)
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    sleep 1
    Team.current = t
    result = CheckSearch.new({keyword: "coração"}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
    # search in description
    result = CheckSearch.new({keyword: "vovô foi à são paulo"}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
    result = CheckSearch.new({keyword: "vovo foi a sao paulo"}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
  end

  test "should search with diacritics FR" do
    t = create_team
    p = create_project team: t
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "cañon", "description":"légion française"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m = create_media(account: create_valid_account, url: url)
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    sleep 1
    Team.current = t
    result = CheckSearch.new({keyword: "cañon"}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
    result = CheckSearch.new({keyword: "canon"}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
    # search in description
    result = CheckSearch.new({keyword: "légion française"}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
    result = CheckSearch.new({keyword: "legion francaise"}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
  end

  test "should search with diacritics AR" do
    t = create_team
    p = create_project team: t
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "ﻻ", "description":"تْشِك"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m = create_media(account: create_valid_account, url: url)
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    sleep 1
    Team.current = t
    result = CheckSearch.new({keyword: "ﻻ"}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
    result = CheckSearch.new({keyword: "لا"}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
    # search in description
    result = CheckSearch.new({keyword: "تْشِك"}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
    result = CheckSearch.new({keyword: "تشك"}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
  end

  test "should search arabic #6066" do
     t = create_team
     p = create_project team: t
     pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
     url = 'http://test.com'
     response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "ﻻ", "description":"بِسْمِ ٱللهِ ٱلرَّحْمٰنِ ٱلرَّحِيمِ"}}'
     WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
     m = create_media(account: create_valid_account, url: url)
     pm = create_project_media project: p, media: m, disable_es_callbacks: false
     sleep 1
     Team.current = t
     result = CheckSearch.new({keyword: "بسم"}.to_json)
     assert_equal [pm.id], result.medias.map(&:id)
     result = CheckSearch.new({keyword: "بسم الله"}.to_json)
     assert_equal [pm.id], result.medias.map(&:id)
  end

  test "should filter by medias or archived" do
    RequestStore.store[:skip_delete_for_ever] = true
    ft = create_field_type field_type: 'image_path', label: 'Image Path'
    at = create_annotation_type annotation_type: 'reverse_image', label: 'Reverse Image'
    create_field_instance annotation_type_object: at, name: 'reverse_image_path', label: 'Reverse Image', field_type_object: ft, optional: false
    create_bot name: 'Check Bot'
    t = create_team
    p = create_project team: t
    c = create_claim_media
    pm = create_project_media project: p, media: c, disable_es_callbacks: false
    m = create_valid_media
    create_project_media project: p, media: m, disable_es_callbacks: false
    i = create_uploaded_image
    create_project_media project: p, media: i, disable_es_callbacks: false
    sleep 2
    Team.current = t
    result = CheckSearch.new({}.to_json)
    assert_equal 3, result.medias.count
    # filter by claims
    result = CheckSearch.new({ show: ['claims'] }.to_json)
    assert_equal 1, result.medias.count
    # filter by links
    result = CheckSearch.new({ show: ['weblink'] }.to_json)
    assert_equal 1, result.medias.count
    # filter by images
    result = CheckSearch.new({ show: ['images'] }.to_json)
    assert_equal 1, result.medias.count
    result = CheckSearch.new({ show: ['claims', 'weblink', 'images'] }.to_json)
    assert_equal 3, result.medias.count
    # filter by archived
    pm.archived = CheckArchivedFlags::FlagCodes::TRASHED
    pm.save!
    sleep 2
    result = CheckSearch.new({ archived: CheckArchivedFlags::FlagCodes::TRASHED }.to_json)
    assert_equal 1, result.medias.count
    result = CheckSearch.new({ archived: CheckArchivedFlags::FlagCodes::NONE }.to_json)
    assert_equal 2, result.medias.count
    Team.current = nil
  end

  test "should search case-insensitive tags" do
    t = create_team
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    m2 = create_valid_media
    pm2 = create_project_media project: p, media: m2, disable_es_callbacks: false
    create_tag tag: 'test', annotated: pm, disable_es_callbacks: false
    create_tag tag: 'Test', annotated: pm2, disable_es_callbacks: false
    sleep 2
    # search by tags
    result = CheckSearch.new({tags: ['test']}.to_json, nil, t.id)
    assert_equal [pm.id, pm2.id].sort, result.medias.map(&:id).sort
    result = CheckSearch.new({tags: ['Test']}.to_json, nil, t.id)
    assert_equal [pm.id, pm2.id].sort, result.medias.map(&:id).sort
    # search by tags as keyword
    result = CheckSearch.new({keyword: 'test'}.to_json, nil, t.id)
    assert_equal [pm.id, pm2.id].sort, result.medias.map(&:id).sort
    result = CheckSearch.new({keyword: 'Test'}.to_json, nil, t.id)
    assert_equal [pm.id, pm2.id].sort, result.medias.map(&:id).sort
  end

  test "should sort by cluster_published_reports_count" do
    RequestStore.store[:skip_cached_field_update] = false
    t = create_team
    t2 = create_team
    f = create_feed
    f.teams << t
    f.teams << t2
    FeedTeam.update_all(shared: true)
    pm1 = create_project_media team: t
    c1 = create_cluster project_media: pm1
    c1.project_medias << pm1
    pm2 = create_project_media team: t
    c2 = create_cluster project_media: pm2
    c2.project_medias << pm2
    pm2_t2 = create_project_media team: t2
    c1.project_medias << pm2_t2
    publish_report(pm2)
    publish_report(pm2_t2)
    publish_report(pm1)
    sleep 2
    Team.stubs(:current).returns(t)
    query = { clusterize: true, feed_id: f.id, sort: 'cluster_published_reports_count' }
    result = CheckSearch.new(query.to_json)
    assert_equal [pm1.id, pm2.id], result.medias.map(&:id)
    query[:sort_type] = 'asc'
    result = CheckSearch.new(query.to_json)
    assert_equal [pm2.id, pm1.id], result.medias.map(&:id)
    # filter by published_by filter `cluster_published_reports`
    query = { clusterize: true, feed_id: f.id, cluster_published_reports: [t.id, t2.id]}
    result = CheckSearch.new(query.to_json)
    assert_equal [pm1.id, pm2.id], result.medias.map(&:id).sort
    query = { clusterize: true, feed_id: f.id, cluster_published_reports: [t2.id]}
    result = CheckSearch.new(query.to_json)
    assert_equal [pm1.id], result.medias.map(&:id)
    Team.unstub(:current)
  end

  test "should sort by cluster_first_item_at" do
    t = create_team
    f = create_feed
    f.teams << t
    FeedTeam.update_all(shared: true)
    Time.stubs(:now).returns(Time.new - 2.week)
    pm1 = create_project_media team: t
    c1 = create_cluster project_media: pm1
    c1.project_medias << pm1
    Time.stubs(:now).returns(Time.new - 1.week)
    pm2 = create_project_media team: t
    c2 = create_cluster project_media: pm2
    c2.project_medias << pm2
    Time.stubs(:now).returns(Time.new - 3.week)
    pm3 = create_project_media team: t
    c3 = create_cluster project_media: pm3
    c3.project_medias << pm3
    Time.unstub(:now)
    sleep 2
    Team.stubs(:current).returns(t)
    query = { clusterize: true, feed_id: f.id, sort: 'cluster_first_item_at' }
    result = CheckSearch.new(query.to_json)
    assert_equal [pm2.id, pm1.id, pm3.id], result.medias.map(&:id)
    query[:sort_type] = 'asc'
    result = CheckSearch.new(query.to_json)
    assert_equal [pm3.id, pm1.id, pm2.id], result.medias.map(&:id)
    Team.unstub(:current)
  end

  test "should sort by clusters requests count" do
    RequestStore.store[:skip_cached_field_update] = false
    create_annotation_type_and_fields('Smooch', { 'Data' => ['JSON', false] })
    t = create_team
    f = create_feed
    f.teams << t
    FeedTeam.update_all(shared: true)
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    pm1 = create_project_media team: t
    pm1_1 = create_project_media team: t
    pm2 = create_project_media team: t
    create_dynamic_annotation annotation_type: 'smooch', annotated: pm1
    create_dynamic_annotation annotation_type: 'smooch', annotated: pm2
    c1 = create_cluster project_media: pm1
    c2 = create_cluster project_media: pm2
    c1.project_medias << pm1
    c1.project_medias << pm1_1
    c2.project_medias << pm2
    sleep 2
    with_current_user_and_team(u, t) do
      create_dynamic_annotation annotation_type: 'smooch', annotated: pm1
      create_dynamic_annotation annotation_type: 'smooch', annotated: pm1_1
      sleep 2
      es1 = $repository.find(get_es_id(pm1))
      es2 = $repository.find(get_es_id(pm2))
      assert_equal c1.requests_count(true), es1['cluster_requests_count']
      assert_equal c2.requests_count(true), es2['cluster_requests_count']
      query = { clusterize: true, feed_id: f.id, sort: 'cluster_requests_count' }
      result = CheckSearch.new(query.to_json)
      assert_equal [pm1.id, pm2.id], result.medias.map(&:id)
      query[:sort_type] = 'asc'
      result = CheckSearch.new(query.to_json)
      assert_equal [pm2.id, pm1.id], result.medias.map(&:id)
    end
  end

  test "should sort by cluster_size" do
    t = create_team
    f = create_feed 
    f.teams << t
    FeedTeam.update_all(shared: true)
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    pm1 = create_project_media team: t
    pm1_1 = create_project_media team: t
    pm1_2 = create_project_media team: t
    pm2 = create_project_media team: t
    pm2_1 = create_project_media team: t
    pm2_2 = create_project_media team: t
    pm2_3 = create_project_media team: t
    pm3 = create_project_media team: t
    pm3_1 = create_project_media team: t
    c1 = create_cluster project_media: pm1
    c2 = create_cluster project_media: pm2
    c3 = create_cluster project_media: pm3
    c1.project_medias << pm1
    c1.project_medias << pm1_1
    c1.project_medias << pm1_2
    c2.project_medias << pm2
    c2.project_medias << pm2_1
    c2.project_medias << pm2_2
    c2.project_medias << pm2_3
    c3.project_medias << pm3
    c3.project_medias << pm3_1
    sleep 2
    with_current_user_and_team(u, t) do
      query = { clusterize: true, feed_id: f.id, sort: 'cluster_size' }
      result = CheckSearch.new(query.to_json)
      assert_equal [pm2.id, pm1.id, pm3.id], result.medias.map(&:id)
      query[:sort_type] = 'asc'
      result = CheckSearch.new(query.to_json)
      assert_equal [pm3.id, pm1.id, pm2.id], result.medias.map(&:id)
    end
  end
  # Please add new tests to test/controllers/elastic_search_7_test.rb
end
