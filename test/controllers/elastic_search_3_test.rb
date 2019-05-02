require_relative '../test_helper'

class ElasticSearch3Test < ActionController::TestCase
  def setup
    super
    @controller = Api::V1::GraphqlController.new
    @url = 'https://www.youtube.com/user/MeedanTube'
    require 'sidekiq/testing'
    Sidekiq::Testing.inline!
    User.unstub(:current)
    Team.current = nil
    User.current = nil
    MediaSearch.delete_index
    MediaSearch.create_index
    Rails.stubs(:env).returns('development')
    RequestStore.store[:disable_es_callbacks] = false
    create_translation_status_stuff
    create_verification_status_stuff(false)
    sleep 2
  end

  def teardown
    super
    Rails.unstub(:env)
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
    assert_equal [ps2.id, ps.id], result.sources.map(&:id)
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
    assert_equal [ps3.id, ps2.id, ps1.id], result.sources.map(&:id)
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
    assert_equal [ps3.id, ps2.id], result.sources.map(&:id)
  end

  test "should filter by medias or sources" do
    ft = create_field_type field_type: 'image_path', label: 'Image Path'
    at = create_annotation_type annotation_type: 'reverse_image', label: 'Reverse Image'
    create_field_instance annotation_type_object: at, name: 'reverse_image_path', label: 'Reverse Image', field_type_object: ft, optional: false
    create_bot name: 'Check Bot'
    t = create_team
    p = create_project team: t
    s = create_source
    create_project_source project: p, source: s, disable_es_callbacks: false
    c = create_claim_media
    create_project_media project: p, media: c, disable_es_callbacks: false
    m = create_valid_media
    create_project_media project: p, media: m, disable_es_callbacks: false
    i = create_uploaded_image
    create_project_media project: p, media: i, disable_es_callbacks: false
    sleep 10
    Team.current = t
    result = CheckSearch.new({}.to_json)
    assert_equal 0, result.sources.count
    assert_equal 3, result.medias.count
    result = CheckSearch.new({ show: ['medias'] }.to_json)
    assert_equal 0, result.sources.count
    assert_equal 3, result.medias.count
    result = CheckSearch.new({ show: ['sources'] }.to_json)
    assert_equal p.sources.count, result.sources.count
    assert_equal 0, result.medias.count
    result = CheckSearch.new({ show: ['sources', 'medias'] }.to_json)
    assert_equal p.sources.count, result.sources.count
    assert_equal 3, result.medias.count
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

  test "should index and sort by deadline" do
    create_verification_status_stuff
    at = DynamicAnnotation::AnnotationType.where(annotation_type: 'verification_status').last
    ft = DynamicAnnotation::FieldType.where(field_type: 'timestamp').last || create_field_type(field_type: 'timestamp', label: 'Timestamp')
    create_field_instance annotation_type_object: at, name: 'deadline', label: 'Deadline', field_type_object: ft, optional: true
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'editor'
    p = create_project team: t

    t.set_status_target_turnaround = 10.hours ; t.save!
    pm1 = create_project_media project: p, disable_es_callbacks: false
    sleep 5

    t.set_status_target_turnaround = 5.hours ; t.save!
    pm2 = create_project_media project: p, disable_es_callbacks: false
    sleep 5

    t.set_status_target_turnaround = 15.hours ; t.save!
    pm3 = create_project_media project: p, disable_es_callbacks: false
    sleep 5

    search = {
      sort: [
        {
          'dynamics.deadline': {
            order: 'asc',
            nested: {
              path: 'dynamics',
            }
          }
        }
      ],
      query: {
        match_all: {}
      }
    }

    pms = []
    MediaSearch.search(search).results.each do |r|
      pms << r.annotated_id if r.annotated_type == 'ProjectMedia'
    end
    assert_equal [pm2.id, pm1.id, pm3.id], pms
  end

  # https://errbit.test.meedan.com/apps/581a76278583c6341d000b72/problems/5c920b8bf023ba001b5fffbb
  test "should filter by custom sort and other parameters" do
    create_verification_status_stuff
    at = DynamicAnnotation::AnnotationType.where(annotation_type: 'verification_status').last
    ft = DynamicAnnotation::FieldType.where(field_type: 'timestamp').last || create_field_type(field_type: 'timestamp', label: 'Timestamp')
    create_field_instance annotation_type_object: at, name: 'deadline', label: 'Deadline', field_type_object: ft, optional: true
    query = { sort: 'deadline', sort_type: 'asc' }

    result = CheckSearch.new(query.to_json)
    assert_equal 0, result.medias.count

    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'editor'
    p = create_project team: t

    t.set_status_target_turnaround = 10.hours ; t.save!
    pm1 = create_project_media project: p, disable_es_callbacks: false
    sleep 5

    t.set_status_target_turnaround = 5.hours ; t.save!
    pm2 = create_project_media project: p, disable_es_callbacks: false
    sleep 5

    t.set_status_target_turnaround = 15.hours ; t.save!
    pm3 = create_project_media project: p, disable_es_callbacks: false
    sleep 5

    result = CheckSearch.new(query.to_json)
    assert_equal 3, result.medias.count
    assert_equal [pm2.id, pm1.id, pm3.id], result.medias.map(&:id)
  end

  test "should index and sort by most requested" do
    p = create_project

    pm1 = create_project_media project: p, disable_es_callbacks: false
    2.times { create_dynamic_annotation annotation_type: 'smooch', annotated: pm1, disable_es_callbacks: false }
    sleep 5

    pm2 = create_project_media project: p, disable_es_callbacks: false
    4.times { create_dynamic_annotation annotation_type: 'smooch', annotated: pm2, disable_es_callbacks: false }
    sleep 5

    pm3 = create_project_media project: p, disable_es_callbacks: false
    1.times { create_dynamic_annotation annotation_type: 'smooch', annotated: pm3, disable_es_callbacks: false }
    sleep 5

    pm4 = create_project_media project: p, disable_es_callbacks: false
    3.times { create_dynamic_annotation annotation_type: 'smooch', annotated: pm4, disable_es_callbacks: false }
    sleep 5

    order = [pm3, pm1, pm4, pm2]
    orders = {asc: order, desc: order.reverse}
    orders.keys.each do |order|
      search = {
        sort: [
          {
            'dynamics.smooch': {
              order: order,
              nested: {
                path: 'dynamics',
              }
            }
          }
        ],
        query: {
          match_all: {}
        }
      }
      pms = []
      MediaSearch.search(search).results.each do |r|
        pms << r.annotated_id if r.annotated_type == 'ProjectMedia'
      end
      assert_equal orders[order.to_sym].map(&:id), pms
    end
  end

  [:asc, :desc].each do |order|
    test "should filter and sort by most requested #{order}" do
      p = create_project

      query = { sort: 'smooch', sort_type: order.to_s }

      result = CheckSearch.new(query.to_json)
      assert_equal 0, result.medias.count

      pm1 = create_project_media project: p, disable_es_callbacks: false
      2.times { create_dynamic_annotation annotation_type: 'smooch', annotated: pm1, disable_es_callbacks: false }
      pm2 = create_project_media project: p, disable_es_callbacks: false
      4.times { create_dynamic_annotation annotation_type: 'smooch', annotated: pm2, disable_es_callbacks: false }
      pm3 = create_project_media project: p, disable_es_callbacks: false
      1.times { create_dynamic_annotation annotation_type: 'smooch', annotated: pm3, disable_es_callbacks: false }
      pm4 = create_project_media project: p, disable_es_callbacks: false
      3.times { create_dynamic_annotation annotation_type: 'smooch', annotated: pm4, disable_es_callbacks: false }
      pm5 = create_project_media project: p, disable_es_callbacks: false
      sleep 5

      orders = {asc: [pm3, pm1, pm4, pm2, pm5], desc: [pm2, pm4, pm1, pm3, pm5]}
      result = CheckSearch.new(query.to_json)
      assert_equal 5, result.medias.count
      assert_equal orders[order.to_sym].map(&:id), result.medias.map(&:id)
    end
  end

  test "should decrease elasticsearch smooch when annotations is removed" do
    p = create_project
    pm = create_project_media project: p, disable_es_callbacks: false
    s1 = create_dynamic_annotation annotation_type: 'smooch', annotated: pm, disable_es_callbacks: false
    s2 = create_dynamic_annotation annotation_type: 'smooch', annotated: pm, disable_es_callbacks: false
    sleep 3

    result = MediaSearch.find(get_es_id(pm))
    assert_equal [2], result['dynamics'].select { |d| d.has_key?('smooch')}.map { |s| s['smooch']}
    s1.destroy
    sleep 1

    result = MediaSearch.find(get_es_id(pm))
    assert_equal [1], result['dynamics'].select { |d| d.has_key?('smooch')}.map { |s| s['smooch']}
  end
end
