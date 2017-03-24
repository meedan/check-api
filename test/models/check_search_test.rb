require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class CheckSearchTest < ActiveSupport::TestCase
   def setup
     super
     require 'sidekiq/testing'
     Sidekiq::Testing.inline!
   end

   def teardown
     super
     Team.unstub(:current)
   end

   test "should search with keyword" do
     t = create_team
     p = create_project team: t
     pender_url = CONFIG['pender_host'] + '/api/medias'
     url = 'http://test.com'
     response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "search_title", "description":"search_desc"}}'
     WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
     m = create_media(account: create_valid_account, url: url)
     pm = create_project_media project: p, media: m, disable_es_callbacks: false
     sleep 1
     Team.stubs(:current).returns(t)
     result = CheckSearch.new({keyword: "non_exist_title"}.to_json)
     assert_empty result.medias
     result = CheckSearch.new({keyword: "search_title"}.to_json)
     assert_equal [pm.id], result.medias.map(&:id)
     # overide title then search
     pm.embed= {title: 'search_title_a'}.to_json
     sleep 1
     result = CheckSearch.new({keyword: "search_title_a"}.to_json)
     assert_equal [pm.id], result.medias.map(&:id)
     # search in description
     result = CheckSearch.new({keyword: "search_desc"}.to_json)
     assert_equal [pm.id], result.medias.map(&:id)
     # add keyword to multiple medias
     m2 = create_valid_media
     pm2 = create_project_media project: p, media: m2, disable_es_callbacks: false
     pm2.embed= {description: 'search_desc'}.to_json
     sleep 1
     result = CheckSearch.new({keyword: "search_desc"}.to_json)
     assert_equal [pm.id, pm2.id].sort, result.medias.map(&:id).sort
     # search in quote
     m = create_claim_media quote: 'search_quote'
     pm = create_project_media project: p, media: m, disable_es_callbacks: false
     sleep 1
     result = CheckSearch.new({keyword: "search_quote"}.to_json)
     assert_equal [pm.id], result.medias.map(&:id)
   end

   test "should search with context" do
     t = create_team
     p = create_project team: t
     pender_url = CONFIG['pender_host'] + '/api/medias'
     url = 'http://test.com'
     response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "search_title", "description":"search_desc"}}'
     WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
     m = create_media(account: create_valid_account, url: url)
     pm = create_project_media project: p, media: m, disable_es_callbacks: false
     keyword = {projects: [rand(40000...50000)]}.to_json
     sleep 1
     Team.stubs(:current).returns(t)
     result = CheckSearch.new(keyword)
     assert_empty result.medias
     result = CheckSearch.new({projects: [p.id]}.to_json)
     assert_equal [pm.id], result.medias.map(&:id)
     # add a new context to existing media
     p2 = create_project team: t
     pm2 = create_project_media project: p2, media: m, disable_es_callbacks: false
     sleep 1
     result = CheckSearch.new({projects: [p.id]}.to_json)
     assert_equal [pm.id].sort, result.medias.map(&:id).sort
     # add a new media to same context
     m2 = create_valid_media
     pm2 = create_project_media project: p, media: m2, disable_es_callbacks: false
     sleep 1
     result = CheckSearch.new({projects: [p.id]}.to_json)
     assert_equal [pm.id, pm2.id].sort, result.medias.map(&:id).sort
   end

   test "should search with tags" do
     t = create_team
     p = create_project team: t
     m = create_valid_media
     pm = create_project_media project: p, media: m, disable_es_callbacks: false
     m2 = create_valid_media
     pm2 = create_project_media project: p, media: m2, disable_es_callbacks: false
     create_tag tag: 'sports', annotated: pm, disable_es_callbacks: false
     create_tag tag: 'sports', annotated: pm2, disable_es_callbacks: false
     create_tag tag: 'news', annotated: pm, disable_es_callbacks: false
     sleep 1
     Team.stubs(:current).returns(t)
     result = CheckSearch.new({tags: ['non_exist_tag']}.to_json)
     assert_empty result.medias
     result = CheckSearch.new({tags: ['sports']}.to_json)
     assert_equal [pm.id, pm2.id].sort, result.medias.map(&:id).sort
     result = CheckSearch.new({tags: ['news']}.to_json)
     assert_equal [pm.id], result.medias.map(&:id)
   end

   test "should search with status" do
     t = create_team
     p = create_project team: t
     m = create_valid_media
     pm = create_project_media project: p, media: m, disable_es_callbacks: false
     m2 = create_valid_media
     pm2 = create_project_media project: p, media: m2, disable_es_callbacks: false
     create_status status: 'verified', annotated: pm, disable_es_callbacks: false
     sleep 1
     Team.stubs(:current).returns(t)
     result = CheckSearch.new({status: ['false']}.to_json)
     assert_empty result.medias
     result = CheckSearch.new({status: ['verified']}.to_json)
     assert_equal [pm.id], result.medias.map(&:id)
     create_status status: 'false', annotated: pm, disable_es_callbacks: false
     sleep 1
     result = CheckSearch.new({status: ['verified']}.to_json)
     assert_empty result.medias
   end

   test "should have unique id per params" do
     t = create_team
     Team.stubs(:current).returns(t)
     s1 = CheckSearch.new({ keyword: 'foo' }.to_json)
     s2 = CheckSearch.new({ keyword: 'foo' }.to_json)
     s3 = CheckSearch.new({ keyword: 'bar' }.to_json)
     assert_equal s1.id, s2.id
     assert_not_equal s1.id, s3.id
   end

   test "should search keyword and tags" do
     t = create_team
     p = create_project team: t
     p2 = create_project team: t
     info = {title: 'report_title'}.to_json
     m = create_valid_media
     pm = create_project_media project: p, media: m, disable_es_callbacks: false
     pm.embed= info
     pm2 = create_project_media project: p2, media: m, disable_es_callbacks: false
     pm2.embed= info
     create_tag tag: 'sports', annotated: pm, disable_es_callbacks: false
     create_tag tag: 'sports', annotated: pm2, disable_es_callbacks: false
     sleep 1
     Team.stubs(:current).returns(t)
     result = CheckSearch.new({keyword: 'report_title', tags: ['sports']}.to_json)
     assert_equal [pm2.id, pm.id], result.medias.map(&:id)
   end

   test "should search keyword and context" do
     t = create_team
     p = create_project team: t
     info = {title: 'report_title'}.to_json
     m = create_valid_media
     pm = create_project_media project: p, media: m, disable_es_callbacks: false
     pm.embed= info
     sleep 1
     Team.stubs(:current).returns(t)
     result = CheckSearch.new({keyword: 'report_title', projects: [p.id]}.to_json)
     assert_equal [pm.id], result.medias.map(&:id)
   end

   test "should search keyword and status" do
     t = create_team
     p = create_project team: t
     info = {title: 'report_title'}.to_json
     m = create_valid_media
     pm = create_project_media project: p, media: m, disable_es_callbacks: false
     pm.embed= info
     create_status status: 'verified', annotated: pm, disable_es_callbacks: false
     sleep 1
     Team.stubs(:current).returns(t)
     result = CheckSearch.new({keyword: 'report_title', status: ['verified']}.to_json)
     assert_equal [pm.id], result.medias.map(&:id)
   end

  test "should search tags and context" do
    t = create_team
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    create_tag tag: 'sports', annotated: pm, disable_es_callbacks: false
    sleep 1
    Team.stubs(:current).returns(t)
    result = CheckSearch.new({projects: [p.id], tags: ['sports']}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
  end

  test "should search context and status" do
    t = create_team
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    create_status status: 'verified', annotated: pm, disable_es_callbacks: false
    sleep 1
    Team.stubs(:current).returns(t)
    result = CheckSearch.new({projects: [p.id], status: ['verified']}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
  end

  test "should search keyword tags and context" do
    t = create_team
    p = create_project team: t
    info = {title: 'report_title'}.to_json
    m = create_valid_media
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    pm.embed= info
    create_tag tag: 'sports', annotated: pm, disable_es_callbacks: false
    sleep 1
    Team.stubs(:current).returns(t)
    result = CheckSearch.new({keyword: 'report_title', tags: ['sports'], projects: [p.id]}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
  end

  test "should search keyword context and status" do
    t = create_team
    p = create_project team: t
    info = {title: 'report_title'}.to_json
    m = create_valid_media
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    pm.embed= info
    create_status status: 'verified', annotated: pm, disable_es_callbacks: false
    sleep 1
    Team.stubs(:current).returns(t)
    result = CheckSearch.new({keyword: 'report_title', status: ['verified'], projects: [p.id]}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
  end

  test "should search tags context and status" do
    t = create_team
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    create_tag tag: 'sports', annotated: pm, disable_es_callbacks: false
    create_status status: 'verified', annotated: pm, disable_es_callbacks: false
    sleep 1
    Team.stubs(:current).returns(t)
    result = CheckSearch.new({tags: ['sports'], status: ['verified'], projects: [p.id]}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
  end

  test "should search keyword tags and status" do
    t = create_team
    p = create_project team: t
    info = {title: 'report_title'}.to_json
    m = create_valid_media
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    pm.embed= info
    create_tag tag: 'sports', annotated: pm, disable_es_callbacks: false
    create_status status: 'verified', annotated: pm, disable_es_callbacks: false
    sleep 1
    Team.stubs(:current).returns(t)
    result = CheckSearch.new({keyword: 'report_title', tags: ['sports'], status: ['verified']}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
  end

  test "should search keyword tags context and status" do
    t = create_team
    p = create_project team: t
    info = {title: 'report_title'}.to_json
    m = create_valid_media
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    pm.embed= info
    create_tag tag: 'sports', annotated: pm, disable_es_callbacks: false
    create_status status: 'verified', annotated: pm, disable_es_callbacks: false
    sleep 1
    Team.stubs(:current).returns(t)
    result = CheckSearch.new({keyword: 'report_title', tags: ['sports'], status: ['verified'], projects: [p.id]}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
  end

  test "should seach keyword in comments" do
    t = create_team
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    create_comment text: 'add_comment', annotated: pm, disable_es_callbacks: false
    sleep 1
    Team.stubs(:current).returns(t)
    result = CheckSearch.new({keyword: 'add_comment', projects: [p.id]}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
  end

  test "should sort results by recent activities" do
    t = create_team
    p = create_project team: t
    info = {title: 'search_sort'}.to_json
    m1 = create_valid_media
    pm1 = create_project_media project: p, media: m1, disable_es_callbacks: false
    pm1.embed= info
    m2 = create_valid_media
    pm2 = create_project_media project: p, media: m2, disable_es_callbacks: false
    pm2.embed= info
    m3 = create_valid_media
    pm3 = create_project_media project: p, media: m3, disable_es_callbacks: false
    pm3.embed= info
    create_comment text: 'search_sort', annotated: pm1, disable_es_callbacks: false
    sleep 1
    # sort with keywords
    Team.stubs(:current).returns(t)
    result = CheckSearch.new({keyword: 'search_sort', projects: [p.id]}.to_json)
    assert_equal [pm3.id, pm2.id, pm1.id], result.medias.map(&:id)
    result = CheckSearch.new({keyword: 'search_sort', projects: [p.id], sort: 'recent_activity'}.to_json)
    assert_equal [pm1.id, pm3.id, pm2.id], result.medias.map(&:id)
    # sort with keywords and tags
    create_tag tag: 'sorts', annotated: pm3, disable_es_callbacks: false
    create_tag tag: 'sorts', annotated: pm2, disable_es_callbacks: false
    sleep 1
    result = CheckSearch.new({tags: ["sorts"], projects: [p.id], sort: 'recent_activity'}.to_json)
    assert_equal [pm2.id, pm3.id], result.medias.map(&:id)
    result = CheckSearch.new({keyword: 'search_sort', tags: ["sorts"], projects: [p.id], sort: 'recent_activity'}.to_json)
    assert_equal [pm2.id, pm3.id], result.medias.map(&:id)
    create_status status: 'verified', annotated: pm3, disable_es_callbacks: false
    create_status status: 'verified', annotated: pm2, disable_es_callbacks: false
    create_status status: 'verified', annotated: pm1, disable_es_callbacks: false
    create_status status: 'false', annotated: pm1, disable_es_callbacks: false
    sleep 1
    # sort with keywords, tags and status
    result = CheckSearch.new({status: ["verified"], projects: [p.id], sort: 'recent_activity'}.to_json)
    assert_equal [pm2.id, pm3.id], result.medias.map(&:id)
    result = CheckSearch.new({keyword: 'search_sort', tags: ["sorts"], status: ["verified"], projects: [p.id], sort: 'recent_activity'}.to_json)
    assert_equal [pm2.id, pm3.id], result.medias.map(&:id)
    result = CheckSearch.new({keyword: 'search_sort', tags: ["sorts"], status: ["verified"], projects: [p.id]}.to_json)
    assert_equal [pm3.id, pm2.id], result.medias.map(&:id)
  end

  test "should sort results asc and desc" do
    t = create_team
    p = create_project team: t
    info = {title: 'search_sort'}.to_json
    m1 = create_valid_media
    pm1 = create_project_media project: p, media: m1, disable_es_callbacks: false
    pm1.embed= info
    m2 = create_valid_media
    pm2 = create_project_media project: p, media: m2, disable_es_callbacks: false
    pm2.embed= info
    m3 = create_valid_media
    pm3 = create_project_media project: p, media: m3, disable_es_callbacks: false
    pm3.embed= info
    create_tag tag: 'sorts', annotated: pm3, disable_es_callbacks: false
    create_tag tag: 'sorts', annotated: pm1, disable_es_callbacks: false
    create_tag tag: 'sorts', annotated: pm2, disable_es_callbacks: false
    sleep 1
    Team.stubs(:current).returns(t)
    result = CheckSearch.new({keyword: 'search_sort', tags: ["sorts"], projects: [p.id]}.to_json)
    assert_equal [pm3.id, pm2.id, pm1.id], result.medias.map(&:id)
    result = CheckSearch.new({keyword: 'search_sort', tags: ["sorts"], projects: [p.id], sort_type: 'asc'}.to_json)
    assert_equal [pm1.id, pm2.id, pm3.id], result.medias.map(&:id)
    result = CheckSearch.new({keyword: 'search_sort', tags: ["sorts"], projects: [p.id], sort: 'recent_activity'}.to_json)
    assert_equal [pm2.id, pm1.id, pm3.id], result.medias.map(&:id)
    result = CheckSearch.new({keyword: 'search_sort', tags: ["sorts"], projects: [p.id], sort: 'recent_activity', sort_type: 'asc'}.to_json)
    assert_equal [pm3.id, pm1.id, pm2.id], result.medias.map(&:id)
  end

  test "should search annotations for multiple projects" do
    t = create_team
    p = create_project team: t
    pender_url = CONFIG['pender_host'] + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "search_title", "description":"search_desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m = create_media(account: create_valid_account, url: url)
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    p2 = create_project team: t
    p3 = create_project team: t
    pm2 = create_project_media project: p2, media: m, disable_es_callbacks: false
    pm3 = create_project_media project: p3, media: m, disable_es_callbacks: false
    sleep 1
    Team.stubs(:current).returns(t)
    result = CheckSearch.new({keyword: 'search_title'}.to_json)
    assert_equal [pm3.id, pm2.id, pm.id], result.medias.map(&:id)
  end

  test "should search keyword with AND operator" do
    t = create_team
    p = create_project team: t
    m1 = create_valid_media
    pm1 = create_project_media project: p, media: m1, disable_es_callbacks: false
    pm1.embed= {title: 'keyworda'}.to_json
    m2 = create_valid_media
    pm2 = create_project_media project: p, media: m2, disable_es_callbacks: false
    pm2.embed= {title: 'keywordb'}.to_json
    m3 = create_valid_media
    pm3 = create_project_media project: p, media: m3, disable_es_callbacks: false
    pm3.embed= {title: 'keyworda and keywordb'}.to_json
    sleep 1
    Team.stubs(:current).returns(t)
    result = CheckSearch.new({keyword: 'keyworda'}.to_json)
    assert_equal 2, result.medias.count
    result = CheckSearch.new({keyword: 'keyworda and keywordb'}.to_json)
    assert_equal 1, result.medias.count
  end

  test "should search for multi-word tag" do
    t = create_team
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    create_tag tag: 'iron maiden', annotated: pm, disable_es_callbacks: false
    m2 = create_valid_media
    pm2 = create_project_media project: p, media: m2, disable_es_callbacks: false
    create_tag tag: 'iron', annotated: pm2, disable_es_callbacks: false
    sleep 1
    Team.stubs(:current).returns(t)
    result = CheckSearch.new({tags: ['iron maiden']}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
    result = CheckSearch.new({tags: ['iron']}.to_json)
    assert_equal [pm2.id, pm.id].sort, result.medias.map(&:id).sort
  end

  test "should search for hashtag" do
    t = create_team
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    create_tag tag: '#monkey', annotated: pm, disable_es_callbacks: false

    m2 = create_valid_media
    pm2 = create_project_media project: p, media: m2, disable_es_callbacks: false
    create_tag tag: 'monkey', annotated: pm2, disable_es_callbacks: false
    sleep 1
    Team.stubs(:current).returns(t)

    result = CheckSearch.new({tags: ['monkey']}.to_json)
    assert_equal [pm2.id, pm.id].sort, result.medias.map(&:id).sort

    result = CheckSearch.new({tags: ['#monkey']}.to_json)
    assert_equal [pm2.id, pm.id].sort, result.medias.map(&:id).sort
  end

  test "should search with project and status" do
    t = create_team
    p = create_project team: t
    pender_url = CONFIG['pender_host'] + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "search_title", "description":"search_desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m = create_media(account: create_valid_account, url: url)
    pm  = create_project_media project: p, media: m, disable_es_callbacks: false
    create_status annotated: pm, status: 'in_progress', disable_es_callbacks: false
    url = 'http://test2.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "search_title", "description":"search_desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m2 = create_media(account: create_valid_account, url: url)
    pm2  = create_project_media project: p, media: m2, disable_es_callbacks: false
    create_status annotated: pm2, status: 'in_progress', disable_es_callbacks: false
    sleep 1
    Team.stubs(:current).returns(t)
    result = CheckSearch.new({projects: [p.id], status: ["in_progress"]}.to_json)
    assert_equal 2, result.medias.count
  end

  test "should include tag and status in recent activity sort" do
    t = create_team
    p = create_project team: t
    pender_url = CONFIG['pender_host'] + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "search_title", "description":"search_desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m1 = create_media(account: create_valid_account, url: url)
    pm1  = create_project_media project: p, media: m1, disable_es_callbacks: false
    url = 'http://test2.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "search_title", "description":"search_desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m2 = create_media(account: create_valid_account, url: url)
    pm2  = create_project_media project: p, media: m2, disable_es_callbacks: false
    create_status annotated: pm1, status: 'in_progress', disable_es_callbacks: false
    sleep 1
    Team.stubs(:current).returns(t)
    result = CheckSearch.new({projects: [p.id], sort: "recent_activity"}.to_json)
    assert_equal [pm1.id, pm2.id], result.medias.map(&:id)
    create_tag annotated: pm2, tag: 'in_progress', disable_es_callbacks: false
    sleep 1
    result = CheckSearch.new({projects: [p.id], sort: "recent_activity"}.to_json)
    assert_equal [pm2.id, pm1.id], result.medias.map(&:id)
  end

  test "should include notes in recent activity sort" do
    t = create_team
    p = create_project team: t
    pender_url = CONFIG['pender_host'] + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "search_title", "description":"search_desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m1 = create_media(account: create_valid_account, url: url)
    pm1  = create_project_media project: p, media: m1, disable_es_callbacks: false
    url = 'http://test2.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "search_title", "description":"search_desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m2 = create_media(account: create_valid_account, url: url)
    pm2  = create_project_media project: p, media: m2, disable_es_callbacks: false
    create_comment annotated: pm1, text: 'add comment', disable_es_callbacks: false
    sleep 1
    Team.stubs(:current).returns(t)
    result = CheckSearch.new({keyword: 'search_title', projects: [p.id], sort: "recent_activity"}.to_json)
    assert_equal [pm1.id, pm2.id], result.medias.map(&:id)
    result = CheckSearch.new({keyword: 'search_title', projects: [p.id], sort: "recent_activity", sort_type: 'asc'}.to_json)
    assert_equal [pm2.id, pm1.id], result.medias.map(&:id)
  end

  test "should search for hashtag in keywords" do
    t = create_team
    p = create_project team: t

    info = {title: 'report title'}.to_json
    m = create_valid_media
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    pm.embed= info
    info2 = {title: 'report #title'}.to_json
    m2 = create_valid_media
    pm2 = create_project_media project: p, media: m2, disable_es_callbacks: false
    pm2.embed= info2
    sleep 1
    Team.stubs(:current).returns(t)
    result = CheckSearch.new({keyword: '#title'}.to_json)
    assert_equal [pm2.id], result.medias.map(&:id)

    result = CheckSearch.new({keyword: 'title'}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
  end

  # test "should search annotations with non exist media and project" do
  #   t = create_team
  #   p = create_project team: t
  #   pender_url = CONFIG['pender_host'] + '/api/medias'
  #   url = 'http://test.com'
  #   response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "search_title", "description":"search_desc"}}'
  #   WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
  #   m = create_media(account: create_valid_account, url: url)
  #   pm = create_project_media project: p, media: m
  #   create_comment annotated: m, context: p, text: 'add comment'
  #   p2 = create_project team: t
  #   pm2 = create_project_media project: p2, media: m
  #   pm.delete
  #   result = CheckSearch.new({}.to_json, t)
  #   assert_equal 1, result.number_of_results
  #   pm2.delete
  #   result = CheckSearch.new({}.to_json, t)
  #   assert_equal 1, result.number_of_results
  #   m.delete
  #   result = CheckSearch.new({}.to_json, t)
  #   assert_equal 0, result.number_of_results
  # end

  test "should sort by recent activity with project and status filters" do
    t = create_team
    p = create_project team: t
    pender_url = CONFIG['pender_host'] + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "search_title", "description":"search_desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m = create_media(account: create_valid_account, url: url)
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    create_status status: 'in_progress', annotated: pm, disable_es_callbacks: false
    sleep 1
    Team.stubs(:current).returns(t)
    result = CheckSearch.new({projects: [p.id], status: ['in_progress'], sort: "recent_activity"}.to_json)
    assert_equal 1, result.number_of_results
  end

  test "should load all items sorted" do
    pm1 = create_project_media disable_es_callbacks: false
    pm2 = create_project_media disable_es_callbacks: false
    sleep 1
    assert_equal [pm1.id, pm2.id], MediaSearch.all_sorted().map(&:id).map(&:to_i)
    assert_equal [pm2.id, pm1.id], MediaSearch.all_sorted('desc').map(&:id).map(&:to_i)
  end

  test "should not hit ES when there are no filters" do
    t1 = create_team
    p1a = create_project team: t1
    p1b = create_project team: t1
    pm1a = create_project_media project: p1a
    sleep 1
    pm1b = create_project_media project: p1b
    
    t2 = create_team
    p2a = create_project team: t2
    p2b = create_project team: t2
    pm2a = create_project_media project: p2a
    sleep 1
    pm2b = create_project_media project: p2b
    
    Team.stubs(:current).returns(t1)
    assert_equal [pm1b, pm1a], CheckSearch.new('{}').medias
    assert_equal 2, CheckSearch.new('{}').number_of_results
    assert_equal [pm1a], CheckSearch.new({ projects: [p1a.id] }.to_json).medias
    assert_equal 1, CheckSearch.new({ projects: [p1a.id] }.to_json).number_of_results
    assert_equal [pm1a, pm1b], CheckSearch.new({ sort_type: 'ASC' }.to_json).medias
    assert_equal 2, CheckSearch.new({ sort_type: 'ASC' }.to_json).number_of_results
    Team.unstub(:current)

    Team.stubs(:current).returns(t2)
    assert_equal [pm2b, pm2a], CheckSearch.new('{}').medias
    assert_equal 2, CheckSearch.new('{}').number_of_results
    assert_equal [pm2a], CheckSearch.new({ projects: [p2a.id] }.to_json).medias
    assert_equal 1, CheckSearch.new({ projects: [p2a.id] }.to_json).number_of_results
    assert_equal [pm2a, pm2b], CheckSearch.new({ sort_type: 'ASC' }.to_json).medias
    assert_equal 2, CheckSearch.new({ sort_type: 'ASC' }.to_json).number_of_results
    Team.unstub(:current)
  end
end
