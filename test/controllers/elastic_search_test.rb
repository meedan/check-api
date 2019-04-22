require_relative '../test_helper'

class ElasticSearchTest < ActionController::TestCase
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

  test "should search media" do
    u = create_user
    p = create_project team: @team
    m1 = create_valid_media
    pm1 = create_project_media project: p, media: m1, disable_es_callbacks: false
    authenticate_with_user(u)
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "title_a", "description":"search_desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m2 = create_media(account: create_valid_account, url: url)
    pm2 = create_project_media project: p, media: m2, disable_es_callbacks: false
    sleep 10
    query = 'query Search { search(query: "{\"keyword\":\"title_a\",\"projects\":[' + p.id.to_s + ']}") { number_of_results, medias(first: 10) { edges { node { dbid } } } } }'
    post :create, query: query
    assert_response :success
    ids = []
    JSON.parse(@response.body)['data']['search']['medias']['edges'].each do |id|
      ids << id["node"]["dbid"]
    end
    assert_equal [pm2.id], ids
    create_comment text: 'title_a', annotated: pm1, disable_es_callbacks: false
    sleep 20
    query = 'query Search { search(query: "{\"keyword\":\"title_a\",\"sort\":\"recent_activity\",\"projects\":[' + p.id.to_s + ']}") { medias(first: 10) { edges { node { dbid, project_id } } } } }'
    post :create, query: query
    assert_response :success
    ids = []
    JSON.parse(@response.body)['data']['search']['medias']['edges'].each do |id|
      ids << id["node"]["dbid"]
    end
    assert_equal [pm1.id, pm2.id], ids.sort
  end

  test "should search media with multiple projects" do
    u = create_user
    p = create_project team: @team
    p2 = create_project team: @team
    authenticate_with_user(u)
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "title_a", "description":"search_desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m = create_media(account: create_valid_account, url: url)
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    pm2 = create_project_media project: p2, media: m,  disable_es_callbacks:  false
    sleep 10
    query = 'query Search { search(query: "{\"keyword\":\"title_a\",\"projects\":[' + p.id.to_s + ',' + p2.id.to_s + ']}") { medias(first: 10) { edges { node { dbid, project_id } } } } }'
    post :create, query: query
    assert_response :success
    p_ids = []
    m_ids = []
    JSON.parse(@response.body)['data']['search']['medias']['edges'].each do |id|
      m_ids << id["node"]["dbid"]
      p_ids << id["node"]["project_id"]
    end
    assert_equal [pm.id, pm2.id], m_ids.sort
    assert_equal [p.id, p2.id], p_ids.sort
    pm2.embed= {description: 'new_description'}.to_json
    sleep 10
    query = 'query Search { search(query: "{\"keyword\":\"title_a\",\"projects\":[' + p.id.to_s + ',' + p2.id.to_s + ']}") { medias(first: 10) { edges { node { dbid, project_id, embed } } } } }'
    post :create, query: query
    assert_response :success
    result = {}
    JSON.parse(@response.body)['data']['search']['medias']['edges'].each do |id|
      result[id["node"]["project_id"]] = id["node"]["embed"]
    end
    assert_equal 'new_description', result[p2.id]["description"]
    assert_equal 'search_desc', result[p.id]["description"]
  end

  test "should search by dynamic annotation" do
    u = create_user
    p = create_project team: @team
    m1 = create_valid_media
    pm1 = create_project_media project: p, media: m1, disable_es_callbacks: false
    authenticate_with_user(u)
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "title_a", "description":"search_desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m2 = create_media(account: create_valid_account, url: url)
    pm2 = create_project_media project: p, media: m2, disable_es_callbacks: false

    at = create_annotation_type annotation_type: 'task_response_free_text', label: 'Task Response Free Text', description: 'Free text response that can added to a task'
    ft = create_field_type field_type: 'text_field', label: 'Text Field', description: 'A text field'
    fi1 = create_field_instance name: 'response', label: 'Response', description: 'The response to a task', field_type_object: ft, optional: false, settings: {}
    fi2 = create_field_instance name: 'note', label: 'Note', description: 'A note that explains a response to a task', field_type_object: ft, optional: true, settings: {}
    a = create_dynamic_annotation annotation_type: 'task_response_free_text', annotated: pm1, disable_es_callbacks: false
    f1 = create_field annotation_id: a.id, field_name: 'response', value: 'There is dynamic response here'
    f2 = create_field annotation_id: a.id, field_name: 'note', value: 'This is a dynamic note'
    a.save!
    sleep 20
    query = 'query Search { search(query: "{\"keyword\":\"dynamic response\",\"projects\":[' + p.id.to_s + ']}") { number_of_results, medias(first: 10) { edges { node { dbid } } } } }'
    post :create, query: query
    assert_response :success
    ids = []
    JSON.parse(@response.body)['data']['search']['medias']['edges'].each do |id|
      ids << id["node"]["dbid"]
    end
    assert_equal [pm1.id], ids
    query = 'query Search { search(query: "{\"keyword\":\"dynamic note\",\"projects\":[' + p.id.to_s + ']}") { number_of_results, medias(first: 10) { edges { node { dbid } } } } }'
    post :create, query: query
    assert_response :success
    ids = []
    JSON.parse(@response.body)['data']['search']['medias']['edges'].each do |id|
      ids << id["node"]["dbid"]
    end
    assert_equal [pm1.id], ids
  end

  test "should read first response from task" do
    u = create_user
    p = create_project team: @team
    create_team_user user: u, team: @team
    m = create_valid_media
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    authenticate_with_user(u)
    t = create_task annotated: pm
    at = create_annotation_type annotation_type: 'task_response'
    ft2 = DynamicAnnotation::FieldType.where(field_type: 'text').last || create_field_type(field_type: 'text')
    create_field_instance annotation_type_object: at, field_type_object: ft2, name: 'response'
    t.response = { annotation_type: 'task_response', set_fields: { response: 'Test' }.to_json }.to_json
    t.save!
    query = "query { project_media(ids: \"#{pm.id},#{p.id}\") { tasks { edges { node { jsonoptions, first_response_value, first_response { content } } } } } }"
    post :create, query: query, team: @team.slug
    assert_response :success
    node = JSON.parse(@response.body)['data']['project_media']['tasks']['edges'][0]['node']
    fields = node['first_response']['content']
    assert_equal 'Test', JSON.parse(fields).select{ |f| f['field_type'] == 'text' }.first['value']
    assert_equal 'Test', node['first_response_value']
  end

  test "should move report to other projects" do
    u = create_user
    p = create_project team: @team
    p2 = create_project team: @team
    create_team_user user: u, team: @team, role: 'owner'
    m = create_valid_media
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    authenticate_with_user(u)
    id = Base64.encode64("ProjectMedia/#{pm.id}")
    query = "mutation update { updateProjectMedia( input: { clientMutationId: \"1\", id: \"#{id}\", project_id: #{p2.id} }) { project_media { project_id }, project { id } } }"
    post :create, query: query, team: @team.slug
    assert_response :success
    assert_equal p2.id, JSON.parse(@response.body)['data']['updateProjectMedia']['project_media']['project_id']
    last_version = pm.versions.last
    assert_equal [p.id, p2.id], JSON.parse(last_version.object_changes)['project_id']
    assert_equal u.id.to_s, last_version.whodunnit
  end

  test "should search with keyword" do
    t = create_team
    p = create_project team: t
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    url = 'http://test.com'
    author_url = 'http://facebook.com/123456'
    author_normal_url = 'http://www.facebook.com/meedan'

    data = { url: url, author_url: author_url, type: 'item', title: 'search_title', description: 'search_desc' }
    response = '{"type":"media","data":' + data.to_json + '}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)

    data = { url: author_normal_url, provider: 'facebook', picture: 'http://fb/p.png', username: 'username', title: 'Foo', description: 'Bar', type: 'profile' }
    response = '{"type":"media","data":' + data.to_json + '}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: author_url } }).to_return(body: response)

    m = create_media url: url, account_id: nil, user_id: nil, account: nil, user: nil
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    sleep 1
    Team.current = t
    result = CheckSearch.new({keyword: "non_exist_title"}.to_json)
    assert_empty result.medias
    result = CheckSearch.new({keyword: "search_title"}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
    # overide title then search
    pm.embed= {title: 'search_title_a'}.to_json
    sleep 1
    result = CheckSearch.new({keyword: "search_title_a"}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
    # search with original title
    result = CheckSearch.new({keyword: "search_title"}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
    # search in description
    result = CheckSearch.new({keyword: "search_desc"}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
    # search in account info
    # Search with account name
    result = CheckSearch.new({keyword: "username"}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
    # Search with account title
    result = CheckSearch.new({keyword: "Foo"}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
    # Search with account description
    result = CheckSearch.new({keyword: "Bar"}.to_json)
    assert_empty result.medias
    # add keyword and same account to multiple medias
    media_url = 'http://www.facebook.com/meedan/posts/456789'
    data = { url: media_url, author_url: author_url, type: 'item', description: 'search_desc' }
    response = '{"type":"media","data":' + data.to_json + '}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: media_url } }).to_return(body: response)
    m2 = create_media url: media_url, account_id: nil, user_id: nil, account: nil, user: nil
    pm2 = create_project_media project: p, media: m2, disable_es_callbacks: false
    sleep 1
    result = CheckSearch.new({keyword: "search_desc"}.to_json)
    assert_equal [pm.id, pm2.id].sort, result.medias.map(&:id).sort
    # Search with account name
    result = CheckSearch.new({keyword: "username"}.to_json)
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
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "search_title", "description":"search_desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m = create_media(account: create_valid_account, url: url)
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    keyword = {projects: [rand(40000...50000)]}.to_json
    sleep 1
    Team.current = t
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

  test "should search with tags or status" do
    stub_config('app_name', 'Check') do
      t = create_team
      p = create_project team: t
      m = create_valid_media
      pm = create_project_media project: p, media: m, disable_es_callbacks: false
      m2 = create_valid_media
      pm2 = create_project_media project: p, media: m2, disable_es_callbacks: false
      create_status status: 'verified', annotated: pm, disable_es_callbacks: false
      create_tag tag: 'sports', annotated: pm, disable_es_callbacks: false
      create_tag tag: 'sports', annotated: pm2, disable_es_callbacks: false
      create_tag tag: 'newtag', annotated: pm2, disable_es_callbacks: false
      create_tag tag: 'news', annotated: pm, disable_es_callbacks: false
      sleep 5
      Team.current = t
      # search by status
      result = CheckSearch.new({verification_status: ['false']}.to_json)
      assert_empty result.medias
      result = CheckSearch.new({verification_status: ['verified']}.to_json)
      assert_equal [pm.id], result.medias.map(&:id)
      create_status status: 'false', annotated: pm, disable_es_callbacks: false
      sleep 1
      result = CheckSearch.new({verification_status: ['verified']}.to_json)
      assert_empty result.medias
      # search by tags
      result = CheckSearch.new({tags: ['non_exist_tag']}.to_json)
      assert_empty result.medias
      result = CheckSearch.new({tags: ['sports']}.to_json)
      assert_equal [pm.id, pm2.id].sort, result.medias.map(&:id).sort
      result = CheckSearch.new({tags: ['news']}.to_json)
      assert_equal [pm.id], result.medias.map(&:id)
      # search tags as keywords
      result = CheckSearch.new({keyword: 'news'}.to_json)
      assert_equal [pm.id], result.medias.map(&:id)
      result = CheckSearch.new({keyword: ' news '}.to_json)
      assert_equal [pm.id], result.medias.map(&:id)
      # search by multiple tags as keyword
      result = CheckSearch.new({keyword: 'newtag news'}.to_json)
      assert_equal [pm.id, pm2.id].sort, result.medias.map(&:id).sort
    end
  end

  test "should search tags case-insensitive" do
    stub_config('app_name', 'Check') do
      t = create_team
      p = create_project team: t
      m = create_valid_media
      pm = create_project_media project: p, media: m, disable_es_callbacks: false
      create_tag tag: 'two Words', annotated: pm, disable_es_callbacks: false
      sleep 5
      Team.current = t
      # search by tags
      result = CheckSearch.new({tags: ['two Words']}.to_json)
      assert_equal [pm.id], result.medias.map(&:id)
      result = CheckSearch.new({tags: ['two words']}.to_json)
      assert_equal [pm.id], result.medias.map(&:id)
      result = CheckSearch.new({tags: ['TWO WORDS']}.to_json)
      assert_equal [pm.id], result.medias.map(&:id)
      # search tags as keywords
      result = CheckSearch.new({keyword: 'two Words'}.to_json)
      assert_equal [pm.id], result.medias.map(&:id)
      result = CheckSearch.new({keyword: 'TWO WORDS'}.to_json)
      assert_equal [pm.id], result.medias.map(&:id)
    end
  end

  test "should have unique id per params" do
    t = create_team
    Team.current = t
    s1 = CheckSearch.new({ keyword: 'foo' }.to_json)
    s2 = CheckSearch.new({ keyword: 'foo' }.to_json)
    s3 = CheckSearch.new({ keyword: 'bar' }.to_json)
    assert_equal s1.id, s2.id
    assert_not_equal s1.id, s3.id
  end

  test "should search with multiple filters" do
    stub_config('app_name', 'Check') do
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
      create_status status: 'verified', annotated: pm, disable_es_callbacks: false
      sleep 1
      # keyword & tags
      Team.current = t
      result = CheckSearch.new({keyword: 'report_title', tags: ['sports']}.to_json)
      assert_equal [pm2.id, pm.id], result.medias.map(&:id)
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
    end
  end

  test "should search keyword in comments" do
    t = create_team
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    create_comment text: 'add_comment', annotated: pm, disable_es_callbacks: false
    sleep 10
    Team.current = t
    result = CheckSearch.new({keyword: 'add_comment', projects: [p.id]}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
  end

  test "should sort results by recent activities" do
    stub_config('app_name', 'Check') do
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
      sleep 10
      # sort with keywords
      Team.current = t
      result = CheckSearch.new({keyword: 'search_sort', projects: [p.id]}.to_json)
      assert_equal [pm3.id, pm2.id, pm1.id], result.medias.map(&:id)
      result = CheckSearch.new({keyword: 'search_sort', projects: [p.id], sort: 'recent_activity'}.to_json)
      assert_equal [pm1.id, pm3.id, pm2.id], result.medias.map(&:id)
      # sort with keywords and tags
      create_tag tag: 'sorts', annotated: pm3, disable_es_callbacks: false
      create_tag tag: 'sorts', annotated: pm2, disable_es_callbacks: false
      sleep 10
      result = CheckSearch.new({tags: ["sorts"], projects: [p.id], sort: 'recent_activity'}.to_json)
      assert_equal [pm2.id, pm3.id], result.medias.map(&:id).sort
      result = CheckSearch.new({keyword: 'search_sort', tags: ["sorts"], projects: [p.id], sort: 'recent_activity'}.to_json)
      assert_equal [pm2.id, pm3.id], result.medias.map(&:id)
      create_status status: 'verified', annotated: pm3, disable_es_callbacks: false
      create_status status: 'verified', annotated: pm2, disable_es_callbacks: false
      create_status status: 'verified', annotated: pm1, disable_es_callbacks: false
      create_status status: 'false', annotated: pm1, disable_es_callbacks: false
      sleep 10
      # sort with keywords, tags and status
      result = CheckSearch.new({verification_status: ["verified"], projects: [p.id], sort: 'recent_activity'}.to_json)
      assert_equal [pm2.id, pm3.id], result.medias.map(&:id)
      result = CheckSearch.new({keyword: 'search_sort', tags: ["sorts"], verification_status: ["verified"], projects: [p.id], sort: 'recent_activity'}.to_json)
      assert_equal [pm2.id, pm3.id], result.medias.map(&:id)
      result = CheckSearch.new({keyword: 'search_sort', tags: ["sorts"], verification_status: ["verified"], projects: [p.id]}.to_json)
      assert_equal [pm3.id, pm2.id], result.medias.map(&:id)
    end
  end

  test "should sort results asc and desc" do
    t = create_team
    p = create_project team: t

    info = {title: 'search_sort'}.to_json

    m1 = create_valid_media
    pm1 = create_project_media project: p, media: m1, disable_es_callbacks: false
    pm1.embed = info

    m2 = create_valid_media
    pm2 = create_project_media project: p, media: m2, disable_es_callbacks: false
    pm2.embed = info

    m3 = create_valid_media
    pm3 = create_project_media project: p, media: m3, disable_es_callbacks: false
    pm3.embed = info

    create_tag tag: 'sorts', annotated: pm3, disable_es_callbacks: false
    sleep 2
    create_tag tag: 'sorts', annotated: pm1, disable_es_callbacks: false
    sleep 2
    create_tag tag: 'sorts', annotated: pm2, disable_es_callbacks: false
    sleep 6

    Team.current = t
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
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
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
    Team.current = t
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
    Team.current = t
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
    sleep 10
    Team.current = t
    result = CheckSearch.new({tags: ['iron maiden']}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
    result = CheckSearch.new({tags: ['iron']}.to_json)
    assert_equal [pm2.id, pm.id].sort, result.medias.map(&:id).sort
  end

  test "should search for hashtag" do
    t = create_team
    p = create_project team: t
    info = {title: 'report title'}.to_json
    m = create_valid_media
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    pm.embed= info
    create_tag tag: '#monkey', annotated: pm, disable_es_callbacks: false
    info2 = {title: 'report #title'}.to_json
    m2 = create_valid_media
    pm2 = create_project_media project: p, media: m2, disable_es_callbacks: false
    pm2.embed= info2
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
    assert_equal [pm.id], result.medias.map(&:id)
  end

  test "should include tag and status in recent activity sort" do
    stub_config('app_name', 'Check') do
      t = create_team
      p = create_project team: t
      pender_url = CONFIG['pender_url_private'] + '/api/medias'
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
      sleep 1
      create_status annotated: pm1, status: 'in_progress', disable_es_callbacks: false
      sleep 1
      Team.current = t
      result = CheckSearch.new({projects: [p.id], sort: "recent_activity"}.to_json)
      assert_equal [pm1.id, pm2.id], result.medias.map(&:id)
      create_tag annotated: pm2, tag: 'in_progress', disable_es_callbacks: false
      sleep 1
      result = CheckSearch.new({projects: [p.id], sort: "recent_activity"}.to_json)
      assert_equal [pm2.id, pm1.id], result.medias.map(&:id)
    end
  end

  test "should include notes in recent activity sort" do
    t = create_team
    p = create_project team: t
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
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
    Team.current = t
    result = CheckSearch.new({keyword: 'search_title', projects: [p.id], sort: "recent_activity"}.to_json)
    assert_equal [pm1.id, pm2.id], result.medias.map(&:id)
    result = CheckSearch.new({keyword: 'search_title', projects: [p.id], sort: "recent_activity", sort_type: 'asc'}.to_json)
    assert_equal [pm2.id, pm1.id], result.medias.map(&:id)
  end

  test "should sort by recent activity with project and status filters" do
    stub_config('app_name', 'Check') do
      t = create_team
      p = create_project team: t
      pender_url = CONFIG['pender_url_private'] + '/api/medias'
      url = 'http://test.com'
      response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "search_title", "description":"search_desc"}}'
      WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
      m = create_media(account: create_valid_account, url: url)
      pm = create_project_media project: p, media: m, disable_es_callbacks: false
      create_status status: 'in_progress', annotated: pm, disable_es_callbacks: false
      sleep 1
      Team.current = t
      result = CheckSearch.new({projects: [p.id], verification_status: ['in_progress'], sort: "recent_activity"}.to_json)
      assert_equal 1, result.project_medias.count
    end
  end

  test "should load all items sorted" do
    pm1 = create_project_media disable_es_callbacks: false
    pm2 = create_project_media disable_es_callbacks: false
    sleep 1
    assert_equal [pm1.id, pm2.id], MediaSearch.all_sorted().keep_if {|x| x.annotated_type == 'ProjectMedia'}.map(&:annotated_id).map(&:to_i)
    assert_equal [pm2.id, pm1.id], MediaSearch.all_sorted('desc').keep_if {|x| x.annotated_type == 'ProjectMedia'}.map(&:annotated_id).map(&:to_i)
  end

  test "should always hit ElasticSearch" do
    t1 = create_team
    p1a = create_project team: t1
    p1b = create_project team: t1
    pm1a = create_project_media project: p1a, disable_es_callbacks: false
    ps1a = create_project_source project: p1a, disable_es_callbacks: false
    sleep 1
    pm1b = create_project_media project: p1b, disable_es_callbacks: false

    t2 = create_team
    p2a = create_project team: t2
    p2b = create_project team: t2
    pm2a = create_project_media project: p2a, disable_es_callbacks: false
    sleep 1
    pm2b = create_project_media project: p2b, disable_es_callbacks: false

    Team.current = t1
    assert_equal [pm1b, pm1a], CheckSearch.new('{}').medias
    assert_equal [], CheckSearch.new('{}').sources
    assert_equal p1a.project_sources.sort, CheckSearch.new({ projects: [p1a.id], show: ['medias', 'sources']}.to_json).sources.sort
    assert_equal 2, CheckSearch.new('{}').project_medias.count
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

  test "should ensure project_medias to be an alias of medias" do
    create_project_media
    cs = CheckSearch.new('{}')
    assert_equal cs.medias, cs.project_medias
  end

  test "should get search id" do
    assert_not_nil CheckSearch.id
    assert_not_nil CheckSearch.new('{}').id
  end

  test "should get Pusher channel" do
    p = create_project
    cs = CheckSearch.new({ 'parent' => { 'type' => 'project', 'id' => p.id }, 'projects' => [p.id] }.to_json)
    assert_equal p.pusher_channel, cs.pusher_channel
    t = create_team
    cs = CheckSearch.new({ 'parent' => { 'type' => 'team', 'slug' => t.slug } }.to_json)
    assert_equal t.pusher_channel, cs.pusher_channel
    cs = CheckSearch.new('{}')
    assert_nil cs.pusher_channel
  end

  # Please add new tests to test/controllers/elastic_search_3_test.rb
end
