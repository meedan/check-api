require_relative '../test_helper'

class ElasticSearch3Test < ActionController::TestCase
  def setup
    super
    setup_elasticsearch
  end

  test "should search with diacritics pt" do
    t = create_team
    p = create_project team: t
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
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
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
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
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
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
     pender_url = CONFIG['pender_url_private'] + '/api/medias'
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

  test "should search in project sources" do
    t = create_team
    p = create_project team: t
    s = create_source name: 'search_source_title', slogan: 'search_source_desc'
    ps = create_project_source project: p, source: s, disable_es_callbacks: false
    ps2 = create_project_source project: p, name: 'search_source_title', disable_es_callbacks: false
    create_tag tag: 'sports', annotated: ps, disable_es_callbacks: false
    create_tag tag: 'sports', annotated: ps2, disable_es_callbacks: false
    create_tag tag: 'news', annotated: ps, disable_es_callbacks: false
    create_comment text: 'add_comment', annotated: ps, disable_es_callbacks: false
    sleep 10
    Team.current = t
    result = CheckSearch.new({ show: ['sources'] }.to_json)
    assert_equal [ps.id, ps2.id], result.project_sources.map(&:id).sort
    # search with keyword
    result = CheckSearch.new({keyword: "non_exist_title", show: ['sources'] }.to_json)
    assert_empty result.sources
    result = CheckSearch.new({keyword: "search_source_title", show: ['sources'] }.to_json)
    assert_equal [ps2.id, ps.id].sort, result.sources.map(&:id).sort
    # search in description
    result = CheckSearch.new({keyword: "search_source_desc", show: ['sources'] }.to_json)
    assert_equal [ps.id], result.sources.map(&:id)
    # search with tags
    result = CheckSearch.new({tags: ['non_exist_tag'], show: ['sources'] }.to_json)
    assert_empty result.sources
    result = CheckSearch.new({tags: ['sports'], show: ['sources'] }.to_json)
    assert_equal [ps.id, ps2.id].sort, result.sources.map(&:id).sort
    result = CheckSearch.new({tags: ['news'], show: ['sources'] }.to_json)
    assert_equal [ps.id], result.sources.map(&:id)
    # search with tags as keywords
    result = CheckSearch.new({keyword: 'news', show: ['sources'] }.to_json)
    assert_equal [ps.id], result.sources.map(&:id)
    # search in comments
    result = CheckSearch.new({keyword: 'add_comment', projects: [p.id], show: ['sources'] }.to_json)
    assert_equal [ps.id], result.sources.map(&:id)
  end

  test "should search keyword in accounts in project sources" do
    t = create_team
    p = create_project team: t
    url = random_url
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: '{"type":"media","data":{"username": "account_username", "url":"' + url + '","type":"profile"}}')
    ps = create_project_source project: p, name: 'New source', url: url, disable_es_callbacks: false
    sleep 10
    Team.current = t
    result = CheckSearch.new({keyword: 'account_username', projects: [p.id], show: ['sources'] }.to_json)
    assert_equal [ps.id], result.sources.map(&:id)
  end

  test "should sort results by recent activities in project sources" do
    t = create_team
    p = create_project team: t
    info = {title: 'search_sort'}.to_json
    ps1 = create_project_source project: p, name: 'search_sort', disable_es_callbacks: false ; sleep 1
    ps2 = create_project_source project: p, name: 'search_sort', disable_es_callbacks: false ; sleep 1
    ps3 = create_project_source project: p, name: 'search_sort', disable_es_callbacks: false ; sleep 1
    create_comment text: 'search_sort', annotated: ps1, disable_es_callbacks: false ; sleep 1
    # sort with keywords
    Team.current = t
    result = CheckSearch.new({keyword: 'search_sort', projects: [p.id], show: ['sources'] }.to_json)
    assert_equal [ps1.id, ps3.id, ps2.id], result.sources.map(&:id)
    result = CheckSearch.new({keyword: 'search_sort', projects: [p.id], sort: 'recent_activity', show: ['sources'] }.to_json)
    assert_equal [ps1.id, ps3.id, ps2.id], result.sources.map(&:id)
    # sort with keywords and tags
    create_tag tag: 'sorts', annotated: ps3, disable_es_callbacks: false ; sleep 1
    create_tag tag: 'sorts', annotated: ps2, disable_es_callbacks: false ; sleep 1
    result = CheckSearch.new({tags: ["sorts"], projects: [p.id], sort: 'recent_activity', show: ['sources'] }.to_json)
    assert_equal [ps2.id, ps3.id], result.sources.map(&:id).sort
    result = CheckSearch.new({keyword: 'search_sort', tags: ["sorts"], projects: [p.id], sort: 'recent_activity', show: ['sources'] }.to_json)
    assert_equal [ps2.id, ps3.id], result.sources.map(&:id)
    # sort with keywords and tags
    result = CheckSearch.new({keyword: 'search_sort', tags: ["sorts"], projects: [p.id], sort: 'recent_activity', show: ['sources'] }.to_json)
    assert_equal [ps2.id, ps3.id], result.sources.map(&:id)
    result = CheckSearch.new({keyword: 'search_sort', tags: ["sorts"], projects: [p.id], show: ['sources'] }.to_json)
    assert_equal [ps2.id, ps3.id], result.sources.map(&:id)
  end

  test "should filter by medias or sources or archived" do
    ft = create_field_type field_type: 'image_path', label: 'Image Path'
    at = create_annotation_type annotation_type: 'reverse_image', label: 'Reverse Image'
    create_field_instance annotation_type_object: at, name: 'reverse_image_path', label: 'Reverse Image', field_type_object: ft, optional: false
    create_bot name: 'Check Bot'
    t = create_team
    p = create_project team: t
    s = create_source
    create_project_source project: p, source: s, disable_es_callbacks: false
    c = create_claim_media
    pm = create_project_media project: p, media: c, disable_es_callbacks: false
    m = create_valid_media
    create_project_media project: p, media: m, disable_es_callbacks: false
    i = create_uploaded_image
    create_project_media project: p, media: i, disable_es_callbacks: false
    sleep 10
    Team.current = t
    result = CheckSearch.new({}.to_json)
    assert_equal 0, result.sources.count
    assert_equal 3, result.medias.count
    # filter by claims
    result = CheckSearch.new({ show: ['claims'] }.to_json)
    assert_equal 0, result.sources.count
    assert_equal 1, result.medias.count
    # filter by links
    result = CheckSearch.new({ show: ['links'] }.to_json)
    assert_equal 0, result.sources.count
    assert_equal 1, result.medias.count
    # filter by images
    result = CheckSearch.new({ show: ['images'] }.to_json)
    assert_equal 0, result.sources.count
    assert_equal 1, result.medias.count
    result = CheckSearch.new({ show: ['sources'] }.to_json)
    assert_equal p.sources.count, result.sources.count
    assert_equal 0, result.medias.count
    result = CheckSearch.new({ show: ['sources', 'claims', 'links', 'images'] }.to_json)
    assert_equal p.sources.count, result.sources.count
    assert_equal 3, result.medias.count
    result = CheckSearch.new({ show: ['sources', 'claims'] }.to_json)
    assert_equal p.sources.count, result.sources.count
    assert_equal 1, result.medias.count
    # filter by archived
    pm.archived = true
    pm.save!
    result = CheckSearch.new({ archived: 1 }.to_json)
    assert_equal 1, result.medias.count
    result = CheckSearch.new({ archived: 0 }.to_json)
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
    sleep 5
    # search by tags
    result = CheckSearch.new({tags: ['test']}.to_json)
    assert_equal [pm.id, pm2.id].sort, result.medias.map(&:id).sort
    result = CheckSearch.new({tags: ['Test']}.to_json)
    assert_equal [pm.id, pm2.id].sort, result.medias.map(&:id).sort
    # search by tags as keyword
    result = CheckSearch.new({keyword: 'test'}.to_json)
    assert_equal [pm.id, pm2.id].sort, result.medias.map(&:id).sort
    result = CheckSearch.new({keyword: 'Test'}.to_json)
    assert_equal [pm.id, pm2.id].sort, result.medias.map(&:id).sort
  end

  # Please add new tests to test/controllers/elastic_search_7_test.rb
end
