require_relative '../test_helper'

class ElasticSearch4Test < ActionController::TestCase
  def setup
    super
    setup_elasticsearch
  end

  test "should search with multiple filters" do
    t = create_team
    p = create_project team: t
    p2 = create_project team: t
    info = {title: 'report_title'}.to_json
    m = create_valid_media
    m2 = create_valid_media
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    pm.metadata = info
    pm2 = create_project_media project: p2, media: m2, disable_es_callbacks: false
    pm2.metadata = info
    create_tag tag: 'sports', annotated: pm, disable_es_callbacks: false
    create_tag tag: 'sports', annotated: pm2, disable_es_callbacks: false
    create_status status: 'verified', annotated: pm, disable_es_callbacks: false
    sleep 1
    # keyword & tags
    Team.current = t
    result = CheckSearch.new({keyword: 'report_title', tags: ['sports']}.to_json)
    assert_equal [pm.id, pm2.id], result.medias.map(&:id)
    # keyword & context
    result = CheckSearch.new({keyword: 'report_title', projects: [p.id]}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
    # keyword & status
    result = CheckSearch.new({keyword: 'report_title', verification_status: ['verified']}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
    # tags & context
    result = CheckSearch.new({projects: [p.id], tags: ['sports']}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
    # status & context
    result = CheckSearch.new({projects: [p.id], verification_status: ['verified']}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
    # keyword & tags & context
    result = CheckSearch.new({keyword: 'report_title', tags: ['sports'], projects: [p.id]}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
    # keyword & status & context
    result = CheckSearch.new({keyword: 'report_title', verification_status: ['verified'], projects: [p.id]}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
    # tags & context & status
    result = CheckSearch.new({tags: ['sports'], verification_status: ['verified'], projects: [p.id]}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
    # keyword & tags & status
    result = CheckSearch.new({keyword: 'report_title', tags: ['sports'], verification_status: ['verified']}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
    # keyword & tags & context & status
    result = CheckSearch.new({keyword: 'report_title', tags: ['sports'], verification_status: ['verified'], projects: [p.id]}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
    # search keyword in comments
    create_comment text: 'add_comment', annotated: pm, disable_es_callbacks: false
    sleep 1
    result = CheckSearch.new({keyword: 'add_comment', projects: [p.id]}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
  end

  test "should sort results by recent activities and recent added" do
    t = create_team
    p = create_project team: t
    quote = 'search_sort'
    m1 = create_claim_media quote: 'search_sort'
    m2 = create_claim_media quote: 'search_sort'
    m3 = create_claim_media quote: 'search_sort'
    pm1 = create_project_media project: p, media: m1, disable_es_callbacks: false
    pm2 = create_project_media project: p, media: m2, disable_es_callbacks: false
    pm3 = create_project_media project: p, media: m3, disable_es_callbacks: false
    create_comment text: 'search_sort', annotated: pm1, disable_es_callbacks: false
    sleep 5
    # sort with keywords
    Team.current = t
    result = CheckSearch.new({keyword: 'search_sort', projects: [p.id]}.to_json)
    assert_equal [pm1.id, pm3.id, pm2.id], result.medias.map(&:id)
    result = CheckSearch.new({keyword: 'search_sort', projects: [p.id], sort: 'recent_activity'}.to_json)
    assert_equal [pm1.id, pm3.id, pm2.id], result.medias.map(&:id)
    # sort with keywords and tags
    create_tag tag: 'sorts', annotated: pm3, disable_es_callbacks: false
    create_tag tag: 'sorts', annotated: pm2, disable_es_callbacks: false
    sleep 5
    result = CheckSearch.new({tags: ["sorts"], projects: [p.id], sort: 'recent_activity'}.to_json)
    assert_equal [pm2.id, pm3.id], result.medias.map(&:id).sort
    result = CheckSearch.new({keyword: 'search_sort', tags: ["sorts"], projects: [p.id], sort: 'recent_activity'}.to_json)
    assert_equal [pm2.id, pm3.id], result.medias.map(&:id)
    create_status status: 'verified', annotated: pm3, disable_es_callbacks: false
    create_status status: 'verified', annotated: pm2, disable_es_callbacks: false
    create_status status: 'verified', annotated: pm1, disable_es_callbacks: false
    create_status status: 'false', annotated: pm1, disable_es_callbacks: false
    sleep 5
    # sort with keywords, tags and status
    result = CheckSearch.new({verification_status: ["verified"], projects: [p.id], sort: 'recent_activity'}.to_json)
    assert_equal [pm2.id, pm3.id], result.medias.map(&:id)
    result = CheckSearch.new({keyword: 'search_sort', tags: ["sorts"], verification_status: ["verified"], projects: [p.id], sort: 'recent_activity'}.to_json)
    assert_equal [pm2.id, pm3.id], result.medias.map(&:id)
    result = CheckSearch.new({keyword: 'search_sort', tags: ["sorts"], verification_status: ["verified"], projects: [p.id]}.to_json)
    assert_equal [pm2.id, pm3.id], result.medias.map(&:id)
    # sort asc and desc by created_date
    result = CheckSearch.new({keyword: 'search_sort', tags: ["sorts"], projects: [p.id], sort: 'recent_added'}.to_json)
    assert_equal [pm3.id, pm2.id], result.medias.map(&:id)
    result = CheckSearch.new({keyword: 'search_sort', tags: ["sorts"], projects: [p.id], sort: 'recent_added', sort_type: 'asc'}.to_json)
    assert_equal [pm2.id, pm3.id], result.medias.map(&:id)
  end

  test "should search annotations for multiple projects" do
    t = create_team
    p = create_project team: t
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "search_title", "description":"search_desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    url2 = 'http://test2.com'
    response = '{"type":"media","data":{"url":"' + url2 + '/normalized","type":"item", "title": "search_title", "description":"search_desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url2 } }).to_return(body: response)
    m = create_media(account: create_valid_account, url: url)
    m2 = create_media(account: create_valid_account, url: url2)
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    p2 = create_project team: t
    pm2 = create_project_media project: p2, media: m2, disable_es_callbacks: false
    sleep 1
    Team.current = t
    result = CheckSearch.new({keyword: 'search_title'}.to_json)
    assert_equal [pm2.id, pm.id], result.medias.map(&:id)
  end

  test "should search for multi-word tag" do
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p, disable_es_callbacks: false
    create_tag tag: 'iron maiden', annotated: pm, disable_es_callbacks: false
    pm2 = create_project_media project: p, disable_es_callbacks: false
    create_tag tag: 'iron', annotated: pm2, disable_es_callbacks: false
    sleep 5
    Team.current = t
    result = CheckSearch.new({tags: ['iron maiden']}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
    result = CheckSearch.new({tags: ['iron']}.to_json)
    assert_equal [pm2.id, pm.id].sort, result.medias.map(&:id).sort
    # load all items sorted
    assert_equal [pm.id, pm2.id], MediaSearch.all_sorted().keep_if {|x| x.annotated_type == 'ProjectMedia'}.map(&:annotated_id).map(&:to_i)
    assert_equal [pm2.id, pm.id], MediaSearch.all_sorted('desc').keep_if {|x| x.annotated_type == 'ProjectMedia'}.map(&:annotated_id).map(&:to_i)
  end

  test "should search for hashtag" do
    t = create_team
    p = create_project team: t
    info = {title: 'report title'}.to_json
    m = create_valid_media
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    pm.metadata = info
    create_tag tag: '#monkey', annotated: pm, disable_es_callbacks: false
    info2 = {title: 'report #title'}.to_json
    m2 = create_valid_media
    pm2 = create_project_media project: p, media: m2, disable_es_callbacks: false
    pm2.metadata = info2
    create_tag tag: 'monkey', annotated: pm2, disable_es_callbacks: false
    sleep 10
    Team.current = t
    result = CheckSearch.new({tags: ['monkey']}.to_json)
    assert_equal [pm2.id, pm.id].sort, result.medias.map(&:id).sort
    result = CheckSearch.new({tags: ['#monkey']}.to_json)
    assert_equal [pm2.id, pm.id].sort, result.medias.map(&:id).sort
    # search for hashtag in keywords
    result = CheckSearch.new({keyword: '#title'}.to_json)
    assert_equal [pm2.id], result.medias.map(&:id)
    result = CheckSearch.new({keyword: 'title'}.to_json)
    assert result.medias.map(&:id).include?(pm.id)
  end

  test "should include tag status and comments in recent activity sort" do
    t = create_team
    p = create_project team: t
    pm1  = create_project_media project: p, disable_es_callbacks: false
    sleep 1
    pm2  = create_project_media project: p, disable_es_callbacks: false
    sleep 1
    pm3  = create_project_media project: p, disable_es_callbacks: false
    sleep 1
    create_status annotated: pm1, status: 'in_progress', disable_es_callbacks: false
    sleep 1
    Team.current = t
    result = CheckSearch.new({projects: [p.id], sort: "recent_activity"}.to_json)
    assert_equal [pm1.id, pm3.id, pm2.id], result.medias.map(&:id)
    create_tag annotated: pm3, tag: 'in_progress', disable_es_callbacks: false
    sleep 1
    result = CheckSearch.new({projects: [p.id], sort: "recent_activity"}.to_json)
    assert_equal [pm3.id, pm1.id, pm2.id], result.medias.map(&:id)
    # include notes in recent activity sort
    create_comment annotated: pm1, text: 'add comment', disable_es_callbacks: false
    sleep 1
    result = CheckSearch.new({projects: [p.id], sort: "recent_activity"}.to_json)
    assert_equal [pm1.id, pm3.id, pm2.id], result.medias.map(&:id)
    result = CheckSearch.new({projects: [p.id], sort: "recent_activity", sort_type: 'asc'}.to_json)
    assert_equal [pm2.id, pm3.id, pm1.id], result.medias.map(&:id)
    # should sort by recent activity with project and status filters
    result = CheckSearch.new({projects: [p.id], verification_status: ['in_progress'], sort: "recent_activity"}.to_json)
    assert_equal 1, result.project_medias.count
  end

  test "should always hit ElasticSearch" do
    c = create_claim_media
    c2 = create_claim_media
    m = create_valid_media
    t1 = create_team
    p1a = create_project team: t1
    p1b = create_project team: t1
    pm1a = create_project_media project: p1a, media: c, disable_es_callbacks: false
    ps1a = create_project_source project: p1a, disable_es_callbacks: false
    sleep 1
    pm1b = create_project_media project: p1b, media: c2, disable_es_callbacks: false

    t2 = create_team
    p2a = create_project team: t2
    p2b = create_project team: t2
    pm2a = create_project_media project: p2a, media: m, disable_es_callbacks: false
    sleep 1
    pm2b = create_project_media project: p2b, disable_es_callbacks: false

    Team.current = t1
    assert_equal [pm1b, pm1a], CheckSearch.new('{}').medias
    assert_equal [], CheckSearch.new('{}').sources
    assert_equal p1a.project_sources.sort, CheckSearch.new({ projects: [p1a.id], show: ['sources']}.to_json).sources.sort
    assert_equal 2, CheckSearch.new('{}').project_medias.count
    assert_equal 1, CheckSearch.new({ projects: [p1a.id], show: ['claims']}.to_json).project_medias.count
    assert_equal [pm1a], CheckSearch.new({ projects: [p1a.id] }.to_json).medias
    assert_equal 1, CheckSearch.new({ projects: [p1a.id] }.to_json).project_medias.count
    assert_equal [pm1a, pm1b], CheckSearch.new({ sort_type: 'ASC' }.to_json).medias
    assert_equal 2, CheckSearch.new({ sort_type: 'ASC' }.to_json).project_medias.count
    Team.current = nil

    Team.current = t2
    assert_equal [pm2b, pm2a], CheckSearch.new('{}').medias
    assert_equal 2, CheckSearch.new('{}').project_medias.count
    assert_equal [pm2a], CheckSearch.new({ projects: [p2a.id] }.to_json).medias
    assert_equal 1, CheckSearch.new({ projects: [p2a.id] }.to_json).project_medias.count
    assert_equal [pm2a, pm2b], CheckSearch.new({ sort_type: 'ASC' }.to_json).medias
    assert_equal 2, CheckSearch.new({ sort_type: 'ASC' }.to_json).project_medias.count
    Team.current = nil
  end

  # Please add new tests to test/controllers/elastic_search_7_test.rb
end
