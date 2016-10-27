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
    result = CheckSearch.new({keyword: "non_exist_title"}.to_json)
    assert_empty result.search_result
    result = CheckSearch.new({keyword: "search_title"}.to_json)
    assert_equal [m.id], result.search_result.map(&:id)
    # overide title then search
    m.project_id = p.id
    m.information= {title: 'search_title_a', quote: 'search_quote'}.to_json
    m.save!
    result = CheckSearch.new({keyword: "search_title_a"}.to_json)
    assert_equal [m.id], result.search_result.map(&:id)
    # search in description and quote
    result = CheckSearch.new({keyword: "search_desc"}.to_json)
    assert_equal [m.id], result.search_result.map(&:id)
    result = CheckSearch.new({keyword: "search_quote"}.to_json)
    assert_equal [m.id], result.search_result.map(&:id)
    # add keyword to multiple medias
    m2 = create_valid_media project_id: p.id, information: {quote: 'search_quote'}.to_json
    result = CheckSearch.new({keyword: "search_quote"}.to_json)
    assert_equal [m.id, m2.id].sort, result.search_result.map(&:id).sort
  end

  test "should search with context" do
    t = create_team
    p = create_project team: t
    info = {title: 'search_title'}.to_json
    m = create_valid_media project_id: p.id, information: info
    keyword = {projects: [rand(40000...50000)]}.to_json
    result = CheckSearch.new(keyword)
    assert_empty result.search_result
    result = CheckSearch.new({projects: [p.id]}.to_json)
    assert_equal [m.id], result.search_result.map(&:id)
    # add another media to same context
    m2 = create_valid_media project_id: p.id, information: info
    result = CheckSearch.new({projects: [p.id]}.to_json)
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
    result = CheckSearch.new({tags: ['non_exist_tag']}.to_json)
    assert_empty result.search_result
    result = CheckSearch.new({tags: ['sports']}.to_json)
    assert_equal [m.id, m2.id].sort, result.search_result.map(&:id).sort
    result = CheckSearch.new({tags: ['news']}.to_json)
    assert_equal [m.id], result.search_result.map(&:id)
  end

  test "should search with status" do
    t = create_team
    p = create_project team: t
    info = {title: 'report title'}.to_json
    m = create_valid_media project_id: p.id, information: info
    m2 = create_valid_media project_id: p.id, information: info
    create_status status: 'verified', annotated: m, context: p
    result = CheckSearch.new({status: ['false']}.to_json)
    assert_empty result.search_result
    result = CheckSearch.new({status: ['verified']}.to_json)
    assert_equal [m.id], result.search_result.map(&:id)
    create_status status: 'false', annotated: m, context: p
    result = CheckSearch.new({status: ['verified']}.to_json)
    assert_empty result.search_result
  end
=begin
  test "should search keyword and tags" do
    t = create_team
    p = create_project team: t
    info = {title: 'report_title'}.to_json
    m = create_valid_media project_id: p.id, information: info
    create_tag tag: 'sports', annotated: m, context: p
    result = CheckSearch.new({keyword: 'report_title', tags: ['sports']}.to_json)
    assert_equal [m.id], result.search_result.map(&:id)
  end

  test "should search keyword and context" do
    t = create_team
    p = create_project team: t
    info = {title: 'report_title'}.to_json
    m = create_valid_media project_id: p.id, information: info
    result = CheckSearch.new({keyword: 'report_title', projects: [p.id]}.to_json)
    assert_equal [m.id], result.search_result.map(&:id)
  end

  test "should search keyword and status" do
    t = create_team
    p = create_project team: t
    info = {title: 'report_title'}.to_json
    m = create_valid_media project_id: p.id, information: info
    create_status status: 'verified', annotated: m, context: p
    result = CheckSearch.new({keyword: 'report_title', status: ['verified']}.to_json)
    assert_equal [m.id], result.search_result.map(&:id)
  end

  test "should search tags and context" do
    t = create_team
    p = create_project team: t
    info = {title: 'report_title'}.to_json
    m = create_valid_media project_id: p.id, information: info
    create_tag tag: 'sports', annotated: m, context: p
    result = CheckSearch.new({projects: [p.id], tags: ['sports']}.to_json)
    assert_equal [m.id], result.search_result.map(&:id)
  end

  test "should search context and status" do
    t = create_team
    p = create_project team: t
    info = {title: 'report_title'}.to_json
    m = create_valid_media project_id: p.id, information: info
    create_status status: 'verified', annotated: m, context: p
    result = CheckSearch.new({projects: [p.id], status: ['verified']}.to_json)
    assert_equal [m.id], result.search_result.map(&:id)
  end

  test "should search keyword tags and context" do
    t = create_team
    p = create_project team: t
    info = {title: 'report_title'}.to_json
    m = create_valid_media project_id: p.id, information: info
    create_tag tag: 'sports', annotated: m, context: p
    result = CheckSearch.new({keyword: 'report_title', tags: ['sports'], projects: [p.id]}.to_json)
    assert_equal [m.id], result.search_result.map(&:id)
  end

  test "should search keyword context and status" do
    t = create_team
    p = create_project team: t
    info = {title: 'report_title'}.to_json
    m = create_valid_media project_id: p.id, information: info
    create_status status: 'verified', annotated: m, context: p
    result = CheckSearch.new({keyword: 'report_title', status: ['verified'], projects: [p.id]}.to_json)
    assert_equal [m.id], result.search_result.map(&:id)
  end

  test "should search tags context and status" do
    t = create_team
    p = create_project team: t
    info = {title: 'report_title'}.to_json
    m = create_valid_media project_id: p.id, information: info
    create_tag tag: 'sports', annotated: m, context: p
    create_status status: 'verified', annotated: m, context: p
    result = CheckSearch.new({tags: ['sports'], status: ['verified'], projects: [p.id]}.to_json)
    assert_equal [m.id], result.search_result.map(&:id)
  end

  test "should search keyword tags and status" do
    t = create_team
    p = create_project team: t
    info = {title: 'report_title'}.to_json
    m = create_valid_media project_id: p.id, information: info
    create_tag tag: 'sports', annotated: m, context: p
    create_status status: 'verified', annotated: m, context: p
    result = CheckSearch.new({keyword: 'report_title', tags: ['sports'], status: ['verified']}.to_json)
    assert_equal [m.id], result.search_result.map(&:id)
  end

  test "should search keyword tags context and status" do
    t = create_team
    p = create_project team: t
    info = {title: 'report_title'}.to_json
    m = create_valid_media project_id: p.id, information: info
    create_tag tag: 'sports', annotated: m, context: p
    create_status status: 'verified', annotated: m, context: p
    result = CheckSearch.new({keyword: 'report_title', tags: ['sports'], status: ['verified'], projects: [p.id]}.to_json)
    assert_equal [m.id], result.search_result.map(&:id)
  end
=end
end
