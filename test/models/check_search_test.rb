require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class CheckSearchTest < ActiveSupport::TestCase

  test "should search with keyword" do
    t = create_team
    p = create_project team: t
    pender_url = CONFIG['pender_host'] + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "search_title", "description":"search_desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m = create_media(account: create_valid_account, url: url, project_id: p.id)
    result = CheckSearch.new({keyword: "non_exist_title"}.to_json, t)
    assert_empty result.search_result
    result = CheckSearch.new({keyword: "search_title"}.to_json, t)
    assert_equal [m.id], result.search_result.map(&:id)
    # overide title then search
    m.project_id = p.id
    m.information= {title: 'search_title_a', quote: 'search_quote'}.to_json
    m.save!
    result = CheckSearch.new({keyword: "search_title_a"}.to_json, t)
    assert_equal [m.id], result.search_result.map(&:id)
    # search in description and quote
    result = CheckSearch.new({keyword: "search_desc"}.to_json, t)
    assert_equal [m.id], result.search_result.map(&:id)
    result = CheckSearch.new({keyword: "search_quote"}.to_json, t)
    assert_equal [m.id], result.search_result.map(&:id)
    # add keyword to multiple medias
    m2 = create_valid_media project_id: p.id, information: {quote: 'search_quote'}.to_json
    result = CheckSearch.new({keyword: "search_quote"}.to_json, t)
    assert_equal [m.id, m2.id].sort, result.search_result.map(&:id).sort
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
    result = CheckSearch.new(keyword, t)
    assert_empty result.search_result
    result = CheckSearch.new({projects: [p.id]}.to_json, t)
    assert_equal [m.id], result.search_result.map(&:id)
    # add another media to same context
    info = {title: 'search_title'}.to_json
    m2 = create_valid_media project_id: p.id, information: info
    result = CheckSearch.new({projects: [p.id]}.to_json, t)
    assert_equal [m.id, m2.id].sort, result.search_result.map(&:id).sort
  end

  test "should search with tags" do
    t = create_team
    p = create_project team: t
    info = {title: 'report title'}.to_json
    m = create_valid_media project_id: p.id, information: info
    m2 = create_valid_media project_id: p.id, information: info
    create_tag tag: 'sports', annotated: m, context: p
    create_tag tag: 'sports', annotated: m2, context: p
    create_tag tag: 'news', annotated: m, context: p
    result = CheckSearch.new({tags: ['non_exist_tag']}.to_json, t)
    assert_empty result.search_result
    result = CheckSearch.new({tags: ['sports']}.to_json, t)
    assert_equal [m.id, m2.id].sort, result.search_result.map(&:id).sort
    result = CheckSearch.new({tags: ['news']}.to_json, t)
    assert_equal [m.id], result.search_result.map(&:id)
  end

  test "should search with status" do
    t = create_team
    p = create_project team: t
    info = {title: 'report title'}.to_json
    m = create_valid_media project_id: p.id, information: info
    m2 = create_valid_media project_id: p.id, information: info
    create_status status: 'verified', annotated: m, context: p
    result = CheckSearch.new({status: ['false']}.to_json, t)
    assert_empty result.search_result
    result = CheckSearch.new({status: ['verified']}.to_json, t)
    assert_equal [m.id], result.search_result.map(&:id)
    create_status status: 'false', annotated: m, context: p
    result = CheckSearch.new({status: ['verified']}.to_json, t)
    assert_empty result.search_result
  end

  test "should search keyword and tags" do
    t = create_team
    p = create_project team: t
    info = {title: 'report_title'}.to_json
    m = create_valid_media project_id: p.id, information: info
    create_tag tag: 'sports', annotated: m, context: p
    result = CheckSearch.new({keyword: 'report_title', tags: ['sports']}.to_json, t)
    assert_equal [m.id], result.search_result.map(&:id)
  end

  test "should search keyword and context" do
    t = create_team
    p = create_project team: t
    info = {title: 'report_title'}.to_json
    m = create_valid_media project_id: p.id, information: info
    result = CheckSearch.new({keyword: 'report_title', projects: [p.id]}.to_json, t)
    assert_equal [m.id], result.search_result.map(&:id)
  end

  test "should search keyword and status" do
    t = create_team
    p = create_project team: t
    info = {title: 'report_title'}.to_json
    m = create_valid_media project_id: p.id, information: info
    create_status status: 'verified', annotated: m, context: p
    result = CheckSearch.new({keyword: 'report_title', status: ['verified']}.to_json, t)
    assert_equal [m.id], result.search_result.map(&:id)
  end

  test "should search tags and context" do
    t = create_team
    p = create_project team: t
    info = {title: 'report_title'}.to_json
    m = create_valid_media project_id: p.id, information: info
    create_tag tag: 'sports', annotated: m, context: p
    result = CheckSearch.new({projects: [p.id], tags: ['sports']}.to_json, t)
    assert_equal [m.id], result.search_result.map(&:id)
  end

  test "should search context and status" do
    t = create_team
    p = create_project team: t
    info = {title: 'report_title'}.to_json
    m = create_valid_media project_id: p.id, information: info
    create_status status: 'verified', annotated: m, context: p
    result = CheckSearch.new({projects: [p.id], status: ['verified']}.to_json, t)
    assert_equal [m.id], result.search_result.map(&:id)
  end

  test "should search keyword tags and context" do
    t = create_team
    p = create_project team: t
    info = {title: 'report_title'}.to_json
    m = create_valid_media project_id: p.id, information: info
    create_tag tag: 'sports', annotated: m, context: p
    result = CheckSearch.new({keyword: 'report_title', tags: ['sports'], projects: [p.id]}.to_json, t)
    assert_equal [m.id], result.search_result.map(&:id)
  end

  test "should search keyword context and status" do
    t = create_team
    p = create_project team: t
    info = {title: 'report_title'}.to_json
    m = create_valid_media project_id: p.id, information: info
    create_status status: 'verified', annotated: m, context: p
    result = CheckSearch.new({keyword: 'report_title', status: ['verified'], projects: [p.id]}.to_json, t)
    assert_equal [m.id], result.search_result.map(&:id)
  end

  test "should search tags context and status" do
    t = create_team
    p = create_project team: t
    info = {title: 'report_title'}.to_json
    m = create_valid_media project_id: p.id, information: info
    create_tag tag: 'sports', annotated: m, context: p
    create_status status: 'verified', annotated: m, context: p
    result = CheckSearch.new({tags: ['sports'], status: ['verified'], projects: [p.id]}.to_json, t)
    assert_equal [m.id], result.search_result.map(&:id)
  end

  test "should search keyword tags and status" do
    t = create_team
    p = create_project team: t
    info = {title: 'report_title'}.to_json
    m = create_valid_media project_id: p.id, information: info
    create_tag tag: 'sports', annotated: m, context: p
    create_status status: 'verified', annotated: m, context: p
    result = CheckSearch.new({keyword: 'report_title', tags: ['sports'], status: ['verified']}.to_json, t)
    assert_equal [m.id], result.search_result.map(&:id)
  end

  test "should search keyword tags context and status" do
    t = create_team
    p = create_project team: t
    info = {title: 'report_title'}.to_json
    m = create_valid_media project_id: p.id, information: info
    create_tag tag: 'sports', annotated: m, context: p
    create_status status: 'verified', annotated: m, context: p
    result = CheckSearch.new({keyword: 'report_title', tags: ['sports'], status: ['verified'], projects: [p.id]}.to_json, t)
    assert_equal [m.id], result.search_result.map(&:id)
  end

=begin
  test "should seach keyword in comments" do
    t = create_team
    p = create_project team: t
    m = create_valid_media project_id: p.id
    create_comment text: 'add_comment', annotated: m, context: p
    result = CheckSearch.new({keyword: 'add_comment', projects: [p.id]}.to_json, t)
    assert_equal [m.id], result.search_result.map(&:id)
  end
=end

  test "should sort results by recent activities" do
    t = create_team
    p = create_project team: t
    info = {title: 'search_sort'}.to_json
    m1 = create_valid_media project_id: p.id, information: info
    m2 = create_valid_media project_id: p.id, information: info
    m3 = create_valid_media project_id: p.id, information: info
    #create_comment text: 'search_sort', annotated: m1, context: p
    # sort with keywords
    result = CheckSearch.new({keyword: 'search_sort', projects: [p.id]}.to_json, t)
    assert_equal [m3.id, m2.id, m1.id], result.search_result.map(&:id)
    result = CheckSearch.new({keyword: 'search_sort', projects: [p.id], sort: 'recent_activity'}.to_json, t)
    assert_equal [m3.id, m2.id, m1.id], result.search_result.map(&:id)
    #assert_equal [m1.id, m3.id, m2.id], result.search_result.map(&:id)
    # sort with keywords and tags
    create_tag tag: 'sorts', annotated: m3, context: p
    create_tag tag: 'sorts', annotated: m2, context: p
    result = CheckSearch.new({tags: ["sorts"], projects: [p.id], sort: 'recent_activity'}.to_json, t)
    assert_equal [m2.id, m3.id], result.search_result.map(&:id)
    result = CheckSearch.new({keyword: 'search_sort', tags: ["sorts"], projects: [p.id], sort: 'recent_activity'}.to_json, t)
    assert_equal [m2.id, m3.id], result.search_result.map(&:id)
    create_status status: 'verified', annotated: m3, context: p
    create_status status: 'verified', annotated: m2, context: p
    create_status status: 'verified', annotated: m1, context: p
    create_status status: 'false', annotated: m1, context: p
    # sort with keywords, tags and status
    result = CheckSearch.new({status: ["verified"], projects: [p.id], sort: 'recent_activity'}.to_json, t)
    assert_equal [m2.id, m3.id], result.search_result.map(&:id)
    result = CheckSearch.new({keyword: 'search_sort', tags: ["sorts"], status: ["verified"], projects: [p.id], sort: 'recent_activity'}.to_json, t)
    assert_equal [m2.id, m3.id], result.search_result.map(&:id)
    result = CheckSearch.new({keyword: 'search_sort', tags: ["sorts"], status: ["verified"], projects: [p.id]}.to_json, t)
    assert_equal [m3.id, m2.id], result.search_result.map(&:id)
  end

  test "should sort results asc and desc" do
    t = create_team
    p = create_project team: t
    info = {title: 'search_sort'}.to_json
    m1 = create_valid_media project_id: p.id, information: info
    m2 = create_valid_media project_id: p.id, information: info
    m3 = create_valid_media project_id: p.id, information: info
    create_tag tag: 'sorts', annotated: m3, context: p
    create_tag tag: 'sorts', annotated: m1, context: p
    create_tag tag: 'sorts', annotated: m2, context: p
    result = CheckSearch.new({keyword: 'search_sort', tags: ["sorts"], projects: [p.id]}.to_json, t)
    assert_equal [m3.id, m2.id, m1.id], result.search_result.map(&:id)
    result = CheckSearch.new({keyword: 'search_sort', tags: ["sorts"], projects: [p.id], sort_type: 'asc'}.to_json, t)
    assert_equal [m1.id, m2.id, m3.id], result.search_result.map(&:id)
    result = CheckSearch.new({keyword: 'search_sort', tags: ["sorts"], projects: [p.id], sort: 'recent_activity'}.to_json, t)
    assert_equal [m2.id, m1.id, m3.id], result.search_result.map(&:id)
    result = CheckSearch.new({keyword: 'search_sort', tags: ["sorts"], projects: [p.id], sort: 'recent_activity', sort_type: 'asc'}.to_json, t)
    assert_equal [m3.id, m1.id, m2.id], result.search_result.map(&:id)
  end

end
