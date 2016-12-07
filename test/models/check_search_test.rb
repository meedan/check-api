require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class CheckSearchTest < ActiveSupport::TestCase
   def setup
     super
     require 'sidekiq/testing'
     Sidekiq::Testing.inline!
   end

   test "should search with keyword" do
     t = create_team
     p = create_project team: t
     pender_url = CONFIG['pender_host'] + '/api/medias'
     url = 'http://test.com'
     response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "search_title", "description":"search_desc"}}'
     WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
     m = create_media(account: create_valid_account, url: url, project_id: p.id)
     sleep 1
     result = CheckSearch.new({keyword: "non_exist_title"}.to_json, t)
     assert_empty result.medias
     result = CheckSearch.new({keyword: "search_title"}.to_json, t)
     assert_equal [m.id], result.medias.map(&:id)
     # overide title then search
     m.project_id = p.id
     m.information= {title: 'search_title_a', quote: 'search_quote'}.to_json
     m.save!
     sleep 1
     result = CheckSearch.new({keyword: "search_title_a"}.to_json, t)
     assert_equal [m.id], result.medias.map(&:id)
     # search in description and quote
     result = CheckSearch.new({keyword: "search_desc"}.to_json, t)
     assert_equal [m.id], result.medias.map(&:id)
     result = CheckSearch.new({keyword: "search_quote"}.to_json, t)
     assert_equal [m.id], result.medias.map(&:id)
     # add keyword to multiple medias
     m2 = create_valid_media project_id: p.id, information: {quote: 'search_quote'}.to_json
     sleep 1
     result = CheckSearch.new({keyword: "search_quote"}.to_json, t)
     assert_equal [m.id, m2.id].sort, result.medias.map(&:id).sort
   end

   test "should search with context" do
     t = create_team
     p = create_project team: t
     pender_url = CONFIG['pender_host'] + '/api/medias'
     url = 'http://test.com'
     response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "search_title", "description":"search_desc"}}'
     WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
     m = create_media(account: create_valid_account, url: url, project_id: p.id)
     keyword = {projects: [rand(40000...50000)]}.to_json
     sleep 1
     result = CheckSearch.new(keyword, t)
     assert_empty result.medias
     result = CheckSearch.new({projects: [p.id]}.to_json, t)
     assert_equal [m.id], result.medias.map(&:id)
     # add a new context to existing media
     p2 = create_project team: t
     create_project_media project: p2, media: m
     sleep 1
     result = CheckSearch.new({projects: [p.id]}.to_json, t)
     assert_equal [m.id].sort, result.medias.map(&:id).sort
     # add a new media to same context
     m2 = create_valid_media project_id: p.id
     sleep 1
     result = CheckSearch.new({projects: [p.id]}.to_json, t)
     assert_equal [m.id, m2.id].sort, result.medias.map(&:id).sort
   end

   test "should search with tags" do
     t = create_team
     p = create_project team: t
     info = {title: 'report title'}.to_json
     m = create_valid_media project_id: p.id, information: info
     m2 = create_valid_media project_id: p.id, information: info
     create_tag tag: 'sports', annotated: m, context: p, disable_es_callbacks: false
     create_tag tag: 'sports', annotated: m2, context: p, disable_es_callbacks: false
     create_tag tag: 'news', annotated: m, context: p, disable_es_callbacks: false
     sleep 1
     result = CheckSearch.new({tags: ['non_exist_tag']}.to_json, t)
     assert_empty result.medias
     result = CheckSearch.new({tags: ['sports']}.to_json, t)
     assert_equal [m.id, m2.id].sort, result.medias.map(&:id).sort
     result = CheckSearch.new({tags: ['news']}.to_json, t)
     assert_equal [m.id], result.medias.map(&:id)
   end

   test "should search with status" do
     t = create_team
     p = create_project team: t
     info = {title: 'report title'}.to_json
     m = create_valid_media project_id: p.id, information: info
     m2 = create_valid_media project_id: p.id, information: info
     create_status status: 'verified', annotated: m, context: p, disable_es_callbacks: false
     sleep 1
     result = CheckSearch.new({status: ['false']}.to_json, t)
     assert_empty result.medias
     result = CheckSearch.new({status: ['verified']}.to_json, t)
     assert_equal [m.id], result.medias.map(&:id)
     create_status status: 'false', annotated: m, context: p, disable_es_callbacks: false
     sleep 1
     result = CheckSearch.new({status: ['verified']}.to_json, t)
     assert_empty result.medias
   end

   test "should have unique id per params" do
     t = create_team
     s1 = CheckSearch.new({ keyword: 'foo' }.to_json, t)
     s2 = CheckSearch.new({ keyword: 'foo' }.to_json, t)
     s3 = CheckSearch.new({ keyword: 'bar' }.to_json, t)
     assert_equal s1.id, s2.id
     assert_not_equal s1.id, s3.id
   end

   test "should search keyword and tags" do
     t = create_team
     p = create_project team: t
     p2 = create_project team: t
     info = {title: 'report_title'}.to_json
     m = create_valid_media project_id: p.id, information: info
     create_project_media project: p2, media: m
     m.project_id = p2.id
     m.information= info
     m.save!
     create_tag tag: 'sports', annotated: m, context: p, disable_es_callbacks: false
     create_tag tag: 'sports', annotated: m, context: p2, disable_es_callbacks: false
     sleep 1
     result = CheckSearch.new({keyword: 'report_title', tags: ['sports']}.to_json, t)
     assert_equal [m.id, m.id], result.medias.map(&:id)
   end

   test "should search keyword and context" do
     t = create_team
     p = create_project team: t
     info = {title: 'report_title'}.to_json
     m = create_valid_media project_id: p.id, information: info
     sleep 1
     result = CheckSearch.new({keyword: 'report_title', projects: [p.id]}.to_json, t)
     assert_equal [m.id], result.medias.map(&:id)
   end

   test "should search keyword and status" do
     t = create_team
     p = create_project team: t
     info = {title: 'report_title'}.to_json
     m = create_valid_media project_id: p.id, information: info
     create_status status: 'verified', annotated: m, context: p, disable_es_callbacks: false
     sleep 1
     result = CheckSearch.new({keyword: 'report_title', status: ['verified']}.to_json, t)
     assert_equal [m.id], result.medias.map(&:id)
   end

  test "should search tags and context" do
    t = create_team
    p = create_project team: t
    info = {title: 'report_title'}.to_json
    m = create_valid_media project_id: p.id, information: info
    create_tag tag: 'sports', annotated: m, context: p, disable_es_callbacks: false
    sleep 1
    result = CheckSearch.new({projects: [p.id], tags: ['sports']}.to_json, t)
    assert_equal [m.id], result.medias.map(&:id)
  end

  test "should search context and status" do
    t = create_team
    p = create_project team: t
    info = {title: 'report_title'}.to_json
    m = create_valid_media project_id: p.id, information: info
    create_status status: 'verified', annotated: m, context: p, disable_es_callbacks: false
    sleep 1
    result = CheckSearch.new({projects: [p.id], status: ['verified']}.to_json, t)
    assert_equal [m.id], result.medias.map(&:id)
  end

  test "should search keyword tags and context" do
    t = create_team
    p = create_project team: t
    info = {title: 'report_title'}.to_json
    m = create_valid_media project_id: p.id, information: info
    create_tag tag: 'sports', annotated: m, context: p, disable_es_callbacks: false
    sleep 1
    result = CheckSearch.new({keyword: 'report_title', tags: ['sports'], projects: [p.id]}.to_json, t)
    assert_equal [m.id], result.medias.map(&:id)
  end

  test "should search keyword context and status" do
    t = create_team
    p = create_project team: t
    info = {title: 'report_title'}.to_json
    m = create_valid_media project_id: p.id, information: info
    create_status status: 'verified', annotated: m, context: p, disable_es_callbacks: false
    sleep 1
    result = CheckSearch.new({keyword: 'report_title', status: ['verified'], projects: [p.id]}.to_json, t)
    assert_equal [m.id], result.medias.map(&:id)
  end

  test "should search tags context and status" do
    t = create_team
    p = create_project team: t
    info = {title: 'report_title'}.to_json
    m = create_valid_media project_id: p.id, information: info
    create_tag tag: 'sports', annotated: m, context: p, disable_es_callbacks: false
    create_status status: 'verified', annotated: m, context: p, disable_es_callbacks: false
    sleep 1
    result = CheckSearch.new({tags: ['sports'], status: ['verified'], projects: [p.id]}.to_json, t)
    assert_equal [m.id], result.medias.map(&:id)
  end

  test "should search keyword tags and status" do
    t = create_team
    p = create_project team: t
    info = {title: 'report_title'}.to_json
    m = create_valid_media project_id: p.id, information: info
    create_tag tag: 'sports', annotated: m, context: p, disable_es_callbacks: false
    create_status status: 'verified', annotated: m, context: p, disable_es_callbacks: false
    sleep 1
    result = CheckSearch.new({keyword: 'report_title', tags: ['sports'], status: ['verified']}.to_json, t)
    assert_equal [m.id], result.medias.map(&:id)
  end

  test "should search keyword tags context and status" do
    t = create_team
    p = create_project team: t
    info = {title: 'report_title'}.to_json
    m = create_valid_media project_id: p.id, information: info
    create_tag tag: 'sports', annotated: m, context: p, disable_es_callbacks: false
    create_status status: 'verified', annotated: m, context: p, disable_es_callbacks: false
    sleep 1
    result = CheckSearch.new({keyword: 'report_title', tags: ['sports'], status: ['verified'], projects: [p.id]}.to_json, t)
    assert_equal [m.id], result.medias.map(&:id)
  end

  test "should seach keyword in comments" do
    t = create_team
    p = create_project team: t
    m = create_valid_media project_id: p.id
    create_comment text: 'add_comment', annotated: m, context: p, disable_es_callbacks: false
    sleep 1
    result = CheckSearch.new({keyword: 'add_comment', projects: [p.id]}.to_json, t)
    assert_equal [m.id], result.medias.map(&:id)
  end

  test "should sort results by recent activities" do
    t = create_team
    p = create_project team: t
    info = {title: 'search_sort'}.to_json
    m1 = create_valid_media project_id: p.id, information: info
    m2 = create_valid_media project_id: p.id, information: info
    m3 = create_valid_media project_id: p.id, information: info
    create_comment text: 'search_sort', annotated: m1, context: p, disable_es_callbacks: false
    sleep 1
    # sort with keywords
    result = CheckSearch.new({keyword: 'search_sort', projects: [p.id]}.to_json, t)
    assert_equal [m3.id, m2.id, m1.id], result.medias.map(&:id)
    result = CheckSearch.new({keyword: 'search_sort', projects: [p.id], sort: 'recent_activity'}.to_json, t)
    assert_equal [m1.id, m3.id, m2.id], result.medias.map(&:id)
    # sort with keywords and tags
    create_tag tag: 'sorts', annotated: m3, context: p, disable_es_callbacks: false
    create_tag tag: 'sorts', annotated: m2, context: p, disable_es_callbacks: false
    sleep 1
    result = CheckSearch.new({tags: ["sorts"], projects: [p.id], sort: 'recent_activity'}.to_json, t)
    assert_equal [m2.id, m3.id], result.medias.map(&:id)
    result = CheckSearch.new({keyword: 'search_sort', tags: ["sorts"], projects: [p.id], sort: 'recent_activity'}.to_json, t)
    assert_equal [m2.id, m3.id], result.medias.map(&:id)
    create_status status: 'verified', annotated: m3, context: p, disable_es_callbacks: false
    create_status status: 'verified', annotated: m2, context: p, disable_es_callbacks: false
    create_status status: 'verified', annotated: m1, context: p, disable_es_callbacks: false
    create_status status: 'false', annotated: m1, context: p, disable_es_callbacks: false
    sleep 1
    # sort with keywords, tags and status
    result = CheckSearch.new({status: ["verified"], projects: [p.id], sort: 'recent_activity'}.to_json, t)
    assert_equal [m2.id, m3.id], result.medias.map(&:id)
    result = CheckSearch.new({keyword: 'search_sort', tags: ["sorts"], status: ["verified"], projects: [p.id], sort: 'recent_activity'}.to_json, t)
    assert_equal [m2.id, m3.id], result.medias.map(&:id)
    result = CheckSearch.new({keyword: 'search_sort', tags: ["sorts"], status: ["verified"], projects: [p.id]}.to_json, t)
    assert_equal [m3.id, m2.id], result.medias.map(&:id)
  end

  test "should sort results asc and desc" do
    t = create_team
    p = create_project team: t
    info = {title: 'search_sort'}.to_json
    m1 = create_valid_media project_id: p.id, information: info
    m2 = create_valid_media project_id: p.id, information: info
    m3 = create_valid_media project_id: p.id, information: info
    create_tag tag: 'sorts', annotated: m3, context: p, disable_es_callbacks: false
    create_tag tag: 'sorts', annotated: m1, context: p, disable_es_callbacks: false
    create_tag tag: 'sorts', annotated: m2, context: p, disable_es_callbacks: false
    sleep 1
    result = CheckSearch.new({keyword: 'search_sort', tags: ["sorts"], projects: [p.id]}.to_json, t)
    assert_equal [m3.id, m2.id, m1.id], result.medias.map(&:id)
    result = CheckSearch.new({keyword: 'search_sort', tags: ["sorts"], projects: [p.id], sort_type: 'asc'}.to_json, t)
    assert_equal [m1.id, m2.id, m3.id], result.medias.map(&:id)
    result = CheckSearch.new({keyword: 'search_sort', tags: ["sorts"], projects: [p.id], sort: 'recent_activity'}.to_json, t)
    assert_equal [m2.id, m1.id, m3.id], result.medias.map(&:id)
    result = CheckSearch.new({keyword: 'search_sort', tags: ["sorts"], projects: [p.id], sort: 'recent_activity', sort_type: 'asc'}.to_json, t)
    assert_equal [m3.id, m1.id, m2.id], result.medias.map(&:id)
  end

  test "should search annotations for multiple projects" do
    t = create_team
    p = create_project team: t
    pender_url = CONFIG['pender_host'] + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "search_title", "description":"search_desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m = create_media(account: create_valid_account, url: url, project_id: p.id)
    p2 = create_project team: t
    p3 = create_project team: t
    create_project_media project: p2, media: m
    create_project_media project: p3, media: m
    sleep 1
    result = CheckSearch.new({keyword: 'search_title'}.to_json, t)
    assert_equal [m.id, m.id, m.id], result.medias.map(&:id)
  end

  test "should search keyword with AND operator" do
    t = create_team
    p = create_project team: t
    m1 = create_valid_media project_id: p.id, information: {title: 'keyworda'}.to_json
    m2 = create_valid_media project_id: p.id, information: {title: 'keywordb'}.to_json
    m3 = create_valid_media project_id: p.id, information: {title: 'keyworda and keywordb'}.to_json
    sleep 1
    result = CheckSearch.new({keyword: 'keyworda'}.to_json, t)
    assert_equal 2, result.medias.count
    result = CheckSearch.new({keyword: 'keyworda and keywordb'}.to_json, t)
    assert_equal 1, result.medias.count
  end

  test "should search for multi-word tag" do
    t = create_team
    p = create_project team: t
    info = {title: 'report title'}.to_json
    m = create_valid_media project_id: p.id, information: info
    create_tag tag: 'iron maiden', annotated: m, context: p, disable_es_callbacks: false
    m2 = create_valid_media project_id: p.id, information: info
    create_tag tag: 'iron', annotated: m2, context: p, disable_es_callbacks: false
    sleep 1
    result = CheckSearch.new({tags: ['iron maiden']}.to_json, t)
    assert_equal [m.id], result.medias.map(&:id)
    result = CheckSearch.new({tags: ['iron']}.to_json, t)
    assert_equal [m2.id, m.id].sort, result.medias.map(&:id).sort
  end

  test "should search for hashtag" do
    t = create_team
    p = create_project team: t
    info = {title: 'report title'}.to_json

    m = create_valid_media project_id: p.id, information: info
    create_tag tag: '#monkey', annotated: m, context: p, disable_es_callbacks: false

    m2 = create_valid_media project_id: p.id, information: info
    create_tag tag: 'monkey', annotated: m2, context: p, disable_es_callbacks: false
    sleep 1

    result = CheckSearch.new({tags: ['monkey']}.to_json, t)
    assert_equal [m2.id, m.id].sort, result.medias.map(&:id).sort

    result = CheckSearch.new({tags: ['#monkey']}.to_json, t)
    assert_equal [m2.id, m.id].sort, result.medias.map(&:id).sort
  end

  test "should search with project and status" do
    t = create_team
    p = create_project team: t
    pender_url = CONFIG['pender_host'] + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "search_title", "description":"search_desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m = create_media(account: create_valid_account, url: url, project_id: p.id)
    create_status annotated: m, context: p, status: 'in_progress', disable_es_callbacks: false
    url = 'http://test2.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "search_title", "description":"search_desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m2 = create_media(account: create_valid_account, url: url, project_id: p.id)
    create_status annotated: m2, context: p, status: 'in_progress', disable_es_callbacks: false
    sleep 1
    result = CheckSearch.new({projects: [p.id], status: ["in_progress"]}.to_json, t)
    assert_equal 2, result.medias.count
  end

  test "should include tag and status in recent activity sort" do
    t = create_team
    p = create_project team: t
    pender_url = CONFIG['pender_host'] + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "search_title", "description":"search_desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m1 = create_media(account: create_valid_account, url: url, project_id: p.id)
    url = 'http://test2.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "search_title", "description":"search_desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m2 = create_media(account: create_valid_account, url: url, project_id: p.id)
    create_status annotated: m1, context: p, status: 'in_progress', disable_es_callbacks: false
    sleep 1
    result = CheckSearch.new({projects: [p.id], sort: "recent_activity"}.to_json, t)
    assert_equal [m1.id, m2.id], result.medias.map(&:id)
    create_tag annotated: m2, context: p, tag: 'in_progress', disable_es_callbacks: false
    sleep 1
    result = CheckSearch.new({projects: [p.id], sort: "recent_activity"}.to_json, t)
    assert_equal [m2.id, m1.id], result.medias.map(&:id)
  end

  test "should include notes in recent activity sort" do
    t = create_team
    p = create_project team: t
    pender_url = CONFIG['pender_host'] + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "search_title", "description":"search_desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m1 = create_media(account: create_valid_account, url: url, project_id: p.id)
    url = 'http://test2.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "search_title", "description":"search_desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m2 = create_media(account: create_valid_account, url: url, project_id: p.id)
    create_comment annotated: m1, context: p, text: 'add comment', disable_es_callbacks: false
    sleep 1
    result = CheckSearch.new({keyword: 'search_title', projects: [p.id], sort: "recent_activity"}.to_json, t)
    assert_equal [m1.id, m2.id], result.medias.map(&:id)
    result = CheckSearch.new({keyword: 'search_title', projects: [p.id], sort: "recent_activity", sort_type: 'asc'}.to_json, t)
    assert_equal [m2.id, m1.id], result.medias.map(&:id)
  end

  test "should search for hashtag in keywords" do
    t = create_team
    p = create_project team: t

    info = {title: 'report title'}.to_json
    m = create_valid_media project_id: p.id, information: info

    info2 = {title: 'report #title'}.to_json
    m2 = create_valid_media project_id: p.id, information: info2

    sleep 1
    result = CheckSearch.new({keyword: '#title'}.to_json, t)
    assert_equal [m2.id], result.medias.map(&:id)

    result = CheckSearch.new({keyword: 'title'}.to_json, t)
    assert_equal [m.id], result.medias.map(&:id)
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
    m = create_media(account: create_valid_account, url: url, project_id: p.id)
    create_status status: 'in_progress', annotated: m, context: p, disable_es_callbacks: false
    sleep 1
    result = CheckSearch.new({projects: [p.id], status: ['in_progress'], sort: "recent_activity"}.to_json, t)
    assert_equal 1, result.number_of_results
  end

  test "should load all items sorted" do
    pm1 = create_project_media
    pm2 = create_project_media
    sleep 1
    assert_equal [pm1.id, pm2.id], MediaSearch.all_sorted().map(&:id).map(&:to_i)
    assert_equal [pm2.id, pm1.id], MediaSearch.all_sorted('desc').map(&:id).map(&:to_i)
  end

end
