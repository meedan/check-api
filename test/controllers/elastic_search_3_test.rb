require_relative '../test_helper'

class ElasticSearch3Test < ActionController::TestCase
  def setup
    super
    setup_elasticsearch
  end

  test "should search with diacritics pt" do
    t = create_team
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "coração", "description":"vovô foi à são paulo"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m = create_media(account: create_valid_account, url: url)
    pm = create_project_media team: t, media: m, disable_es_callbacks: false
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
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "cañon", "description":"légion française"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m = create_media(account: create_valid_account, url: url)
    pm = create_project_media team: t, media: m, disable_es_callbacks: false
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
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "ﻻ", "description":"تْشِك"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m = create_media(account: create_valid_account, url: url)
    pm = create_project_media team: t, media: m, disable_es_callbacks: false
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
     pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
     url = 'http://test.com'
     response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "ﻻ", "description":"بِسْمِ ٱللهِ ٱلرَّحْمٰنِ ٱلرَّحِيمِ"}}'
     WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
     m = create_media(account: create_valid_account, url: url)
     pm = create_project_media team: t, media: m, disable_es_callbacks: false
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
    c = create_claim_media
    pm = create_project_media team: t, media: c, disable_es_callbacks: false
    m = create_valid_media
    create_project_media team: t, media: m, disable_es_callbacks: false
    i = create_uploaded_image
    create_project_media team: t, media: i, disable_es_callbacks: false
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
    m = create_valid_media
    pm = create_project_media team: t, media: m, disable_es_callbacks: false
    m2 = create_valid_media
    pm2 = create_project_media team: t, media: m2, disable_es_callbacks: false
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

  # Please add new tests to test/controllers/elastic_search_7_test.rb
end
