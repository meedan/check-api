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
    ft1 = create_field_type field_type: 'task_reference'
    ft2 = DynamicAnnotation::FieldType.where(field_type: 'text').last || create_field_type(field_type: 'text')
    create_field_instance annotation_type_object: at, field_type_object: ft1, name: 'task'
    create_field_instance annotation_type_object: at, field_type_object: ft2, name: 'response'
    t.response = { annotation_type: 'task_response', set_fields: { response: 'Test', task: t.id.to_s }.to_json }.to_json
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

  test "should not hit elasticsearch when there are no filters" do
    t1 = create_team
    p1a = create_project team: t1
    p1b = create_project team: t1
    pm1a = create_project_media project: p1a
    ps1a = create_project_source project: p1a
    sleep 1
    pm1b = create_project_media project: p1b

    t2 = create_team
    p2a = create_project team: t2
    p2b = create_project team: t2
    pm2a = create_project_media project: p2a
    sleep 1
    pm2b = create_project_media project: p2b

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
    ps1 = create_project_source project: p, name: 'search_sort', disable_es_callbacks: false
    ps2 = create_project_source project: p, name: 'search_sort', disable_es_callbacks: false
    ps3 = create_project_source project: p, name: 'search_sort', disable_es_callbacks: false
    create_comment text: 'search_sort', annotated: ps1, disable_es_callbacks: false
    sleep 10
    # sort with keywords
    Team.current = t
    result = CheckSearch.new({keyword: 'search_sort', projects: [p.id], show: ['sources'] }.to_json)
    assert_equal [ps3.id, ps2.id, ps1.id], result.sources.map(&:id)
    result = CheckSearch.new({keyword: 'search_sort', projects: [p.id], sort: 'recent_activity', show: ['sources'] }.to_json)
    assert_equal [ps1.id, ps3.id, ps2.id], result.sources.map(&:id)
    # sort with keywords and tags
    create_tag tag: 'sorts', annotated: ps3, disable_es_callbacks: false
    create_tag tag: 'sorts', annotated: ps2, disable_es_callbacks: false
    sleep 10
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

  test "should filter by archived" do
    create_project_media
    pm = create_project_media
    pm.archived = true
    pm.save!
    create_project_media
    result = CheckSearch.new({}.to_json)
    assert_equal 2, result.medias.count
    result = CheckSearch.new({ archived: 1 }.to_json)
    assert_equal 1, result.medias.count
    result = CheckSearch.new({ archived: 0 }.to_json)
    assert_equal 2, result.medias.count
  end

  test "should get teams" do
    s = CheckSearch.new({}.to_json)
    assert_equal [], s.teams
  end

  test "should update elasticsearch after move project to other team" do
    u = create_user
    t = create_team
    t2 = create_team
    u.is_admin = true; u.save!
    p = create_project team: t
    m = create_valid_media
    User.stubs(:current).returns(u)
    Sidekiq::Testing.inline! do
      pm = create_project_media project: p, media: m, disable_es_callbacks: false
      pm2 = create_project_media project: p, quote: 'Claim', disable_es_callbacks: false
      pids = ProjectMedia.where(project_id: p.id).map(&:id)
      pids.concat ProjectSource.where(project_id: p.id).map(&:id)
      sleep 5
      results = MediaSearch.search(query: { match: { team_id: t.id } }).results
      assert_equal pids.sort, results.map(&:annotated_id).sort
      p.team_id = t2.id; p.save!
      sleep 5
      results = MediaSearch.search(query: { match: { team_id: t.id } }).results
      assert_equal [], results.map(&:annotated_id)
      results = MediaSearch.search(query: { match: { team_id: t2.id } }).results
      assert_equal pids.sort, results.map(&:annotated_id).sort
    end
  end

  test "should update elasticsearch after move media to other projects" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    p2 = create_project team: t
    m = create_valid_media
    User.stubs(:current).returns(u)
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    create_comment annotated: pm
    create_tag annotated: pm
    sleep 1
    id = get_es_id(pm)
    ms = MediaSearch.find(id)
    assert_equal ms.project_id.to_i, p.id
    assert_equal ms.team_id.to_i, t.id
    pm.project = p2; pm.save!
    # confirm annotations log
    sleep 1
    ms = MediaSearch.find(id)
    assert_equal ms.project_id.to_i, p2.id
    assert_equal ms.team_id.to_i, t.id
  end

  test "should destroy elasticseach project media" do
    t = create_team
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    sleep 1
    id = get_es_id(pm)
    assert_not_nil MediaSearch.find(id)
    Sidekiq::Testing.inline! do
      pm.destroy
      sleep 1
      assert_raise Elasticsearch::Persistence::Repository::DocumentNotFound do
        result = MediaSearch.find(id)
      end
    end
  end

  test "should update elasticsearch after refresh pender data" do
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    url = random_url
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: '{"type":"media","data":{"url":"' + url + '","type":"item","title":"org_title"}}')
    WebMock.stub_request(:get, pender_url).with({ query: { url: url, refresh: '1' } }).to_return(body: '{"type":"media","data":{"url":"' + url + '","type":"item","title":"new_title"}}')
    t = create_team
    p = create_project team: t
    p2 = create_project team: t
    m = create_media url: url
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    pm2 = create_project_media project: p2, media: m, disable_es_callbacks: false
    sleep 1
    ms = MediaSearch.find(get_es_id(pm))
    assert_equal ms.title, 'org_title'
    ms2 = MediaSearch.find(get_es_id(pm2))
    assert_equal ms2.title, 'org_title'
    Sidekiq::Testing.inline! do
      # Update title
      pm2.reload; pm2.disable_es_callbacks = false
      info = {title: 'override_title'}.to_json
      pm2.embed= info
      pm.reload; pm.disable_es_callbacks = false
      pm.refresh_media = true
      pm.save!
      pm2.reload; pm2.disable_es_callbacks = false
      pm2.refresh_media = true
      pm2.save!
    end
    sleep 1
    ms = MediaSearch.find(get_es_id(pm))
    assert_equal ms.title, 'new_title'
    ms2 = MediaSearch.find(get_es_id(pm2))
    assert_equal ms2.title.sort, ["org_title", "override_title"].sort
  end

  test "should set elasticsearch data for media account" do
    t = create_team
    p = create_project team: t
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    media_url = 'http://www.facebook.com/meedan/posts/123456'
    author_url = 'http://facebook.com/123456'
    author_normal_url = 'http://www.facebook.com/meedan'

    data = { url: media_url, author_url: author_url, type: 'item' }
    response = '{"type":"media","data":' + data.to_json + '}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: media_url } }).to_return(body: response)

    data = { url: author_normal_url, provider: 'facebook', picture: 'http://fb/p.png', username: 'username', title: 'Foo', description: 'Bar', type: 'profile' }
    response = '{"type":"media","data":' + data.to_json + '}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: author_url } }).to_return(body: response)

    m = create_media url: media_url, account_id: nil, user_id: nil, account: nil, user: nil
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    sleep 1
    ms = MediaSearch.find(get_es_id(pm))
    assert_equal ms['accounts'][0].sort, {"id"=> m.account.id, "title"=>"Foo", "description"=>"Bar", "username"=>"username"}.sort
  end

  test "should update or destroy media search in background" do
    Sidekiq::Testing.fake!
    t = create_team
    p = create_project team: t
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "test media", "description":"add desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m = create_media(account: create_valid_account, url: url)
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    # update title or description
    ElasticSearchWorker.clear
    pm.embed= {title: 'title', description: 'description'}.to_json
    assert_equal 1, ElasticSearchWorker.jobs.size
    # destroy media
    ElasticSearchWorker.clear
    assert_equal 0, ElasticSearchWorker.jobs.size
    pm.destroy
    assert ElasticSearchWorker.jobs.size > 0
  end

  test "should add or destroy es for annotations in background" do
    Sidekiq::Testing.fake!
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p, disable_es_callbacks: false
    # add comment
    ElasticSearchWorker.clear
    c = create_comment annotated: pm, disable_es_callbacks: false
    assert_equal 1, ElasticSearchWorker.jobs.size
    # add tag
    ElasticSearchWorker.clear
    t = create_tag annotated: pm, disable_es_callbacks: false
    assert_equal 1, ElasticSearchWorker.jobs.size
    # destroy comment
    ElasticSearchWorker.clear
    c.destroy
    assert_equal 1, ElasticSearchWorker.jobs.size
    # destroy tag
    ElasticSearchWorker.clear
    t.destroy
    assert_equal 1, ElasticSearchWorker.jobs.size
  end

  test "should update status in background" do
    m = create_valid_media
    Sidekiq::Testing.fake! do
      Sidekiq::Worker.clear_all
      ElasticSearchWorker.clear
      assert_equal 0, ElasticSearchWorker.jobs.size
      pm = create_project_media media: m, disable_es_callbacks: false
      assert ElasticSearchWorker.jobs.size > 0
    end
  end

  test "should index and search by location" do
    att = 'task_response_geolocation'
    at = create_annotation_type annotation_type: att, label: 'Task Response Geolocation'
    geotype = create_field_type field_type: 'geojson', label: 'GeoJSON'
    create_field_instance annotation_type_object: at, name: 'response_geolocation', field_type_object: geotype
    pm = create_project_media disable_es_callbacks: false
    geo = {
      type: 'Feature',
      geometry: {
        type: 'Point',
        coordinates: [-12.9015866, -38.560239]
      },
      properties: {
        name: 'Salvador, BA, Brazil'
      }
    }.to_json

    fields = { response_geolocation: geo }.to_json
    d = create_dynamic_annotation annotation_type: att, annotated: pm, set_fields: fields, disable_es_callbacks: false

    search = {
      query: {
        nested: {
          path: 'dynamics',
          query: {
            bool: {
              filter: {
                geo_distance: {
                  distance: '1000mi',
                  "dynamics.location": {
                    lat: -12.900,
                    lon: -38.560
                  }
                }
              }
            }
          }
        }
      }
    }

    sleep 3

    assert_equal 1, MediaSearch.search(search).results.size
  end

  test "should index and search by datetime" do
    att = 'task_response_datetime'
    at = create_annotation_type annotation_type: att, label: 'Task Response Date Time'
    datetime = create_field_type field_type: 'datetime', label: 'Date Time'
    create_field_instance annotation_type_object: at, name: 'response_datetime', field_type_object: datetime
    pm = create_project_media disable_es_callbacks: false
    fields = { response_datetime: '2017-08-21 14:13:42' }.to_json
    d = create_dynamic_annotation annotation_type: att, annotated: pm, set_fields: fields, disable_es_callbacks: false

    search = {
      query: {
        nested: {
          path: 'dynamics',
          query: {
            bool: { 
              filter: {
                range: {
                  "dynamics.datetime": {
                    lte: Time.parse('2017-08-22').to_i,
                    gte: Time.parse('2017-08-20').to_i
                  }
                }
              }
            }
          }
        }
      }
    }

    sleep 5

    assert_equal 1, MediaSearch.search(search).results.size
  end

  test "should index and search by language" do
    att = 'language'
    at = create_annotation_type annotation_type: att, label: 'Language'
    language = create_field_type field_type: 'language', label: 'Language'
    create_field_instance annotation_type_object: at, name: 'language', field_type_object: language

    languages = ['pt', 'en', 'ar', 'es', 'pt-BR', 'pt-PT']
    ids = {}

    languages.each do |code|
      pm = create_project_media disable_es_callbacks: false
      d = create_dynamic_annotation annotation_type: att, annotated: pm, set_fields: { language: code }.to_json, disable_es_callbacks: false
      ids[code] = pm.id
    end
    
    sleep languages.size * 2
    
    languages.each do |code|
      search = {
        query: {
          nested: {
            path: 'dynamics',
            query: {
              term: {
                "dynamics.language": code
              }
            }
          }
        }
      }

      results = MediaSearch.search(search).results
      assert_equal 1, results.size
      assert_equal ids[code], results.first.annotated_id
    end
  end

  test "should create media search" do
    assert_difference 'MediaSearch.length' do
      create_media_search
    end
  end

  test "should set type automatically for media" do
    m = create_media_search
    assert_equal 'mediasearch', m.annotation_type
  end

  test "should reindex data" do
    # Test raising error for re-index
    MediaSearch.stubs(:migrate_es_data).raises(StandardError)
    CheckElasticSearchModel.reindex_es_data
    MediaSearch.unstub(:migrate_es_data)

    source_index = CheckElasticSearchModel.get_index_name
    target_index = "#{source_index}_reindex"
    MediaSearch.delete_index target_index
    MediaSearch.create_index(target_index, false)
    m = create_media_search
    url = "http://#{CONFIG['elasticsearch_host']}:#{CONFIG['elasticsearch_port']}"
    repository = Elasticsearch::Persistence::Repository.new url: url
    repository.type = 'media_search'
    repository.index = source_index
    results = repository.search(query: { match_all: { } }, size: 10000)
    assert_equal 1, results.size
    repository.index = target_index
    results = repository.search(query: { match_all: { } }, size: 10000)
    assert_equal 0, results.size
    MediaSearch.migrate_es_data(source_index, target_index)
    sleep 1
    results = repository.search(query: { match_all: { } }, size: 10000)
    assert_equal 1, results.size
    # test re-index
    CheckElasticSearchModel.reindex_es_data
    sleep 1
    assert_equal 1, MediaSearch.length
  end

  test "should update elasticsearch after source update" do
    s = create_source name: 'source_a', slogan: 'desc_a'
    ps = create_project_source project: create_project, source: s, disable_es_callbacks: false
    sleep 1
    ms = MediaSearch.find(get_es_id(ps))
    assert_equal ms.title, s.name
    assert_equal ms.description, s.description
    s.name = 'new_source'; s.slogan = 'new_desc'; s.disable_es_callbacks = false; s.save!
    s.reload
    sleep 1
    ms = MediaSearch.find(get_es_id(ps))
    assert_equal ms.title, s.name
    assert_equal ms.description, s.description
    # test multiple project sources
    ps2 = create_project_source project: create_project, source: s, disable_es_callbacks: false
    sleep 1
    ms = MediaSearch.find(get_es_id(ps2))
    assert_equal ms.title, s.name
    assert_equal ms.description, s.description
    # update source should update all related project_sources
    s.name = 'source_b'; s.slogan = 'desc_b'; s.save!
    s.reload
    sleep 1
    ms1 = MediaSearch.find(get_es_id(ps))
    ms2 = MediaSearch.find(get_es_id(ps2))
    assert_equal ms1.title, ms2.title, s.name
    assert_equal ms1.description, ms2.description, s.description
  end

  test "should destroy related items" do
    t = create_team
    p = create_project team: t
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item", "title": "test media", "description":"add desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m = create_media(account: create_valid_account, url: url)
    Sidekiq::Testing.inline! do
      pm = create_project_media project: p, media: m, disable_es_callbacks: false
      c = create_comment annotated: pm, disable_es_callbacks: false
      sleep 1
      result = MediaSearch.find(get_es_id(pm))
      assert_equal 1, result['comments'].count
      id = pm.id
      m.destroy
      assert_equal 0, ProjectMedia.where(media_id: id).count
      assert_equal 0, Annotation.where(annotated_id: pm.id, annotated_type: 'ProjectMedia').count
      sleep 1
      assert_raise Elasticsearch::Persistence::Repository::DocumentNotFound do
        MediaSearch.find(get_es_id(pm))
      end
    end
  end
  
  test "should destroy related items 2" do
    t = create_team
    p = create_project team: t
    id = p.id
    p.title = 'Change title'; p.save!
    Sidekiq::Testing.inline! do
      pm = create_project_media project: p, disable_es_callbacks: false
      c = create_comment annotated: pm, disable_es_callbacks: false
      sleep 1
      result = MediaSearch.find(get_es_id(pm))
      p.destroy
      assert_equal 0, ProjectMedia.where(project_id: id).count
      assert_equal 0, Annotation.where(annotated_id: pm.id, annotated_type: 'ProjectMedia').count
      assert_equal 0, PaperTrail::Version.where(item_id: id, item_type: 'Project').count
      sleep 1
      assert_raise Elasticsearch::Persistence::Repository::DocumentNotFound do
        MediaSearch.find(get_es_id(pm))
      end
    end
  end

  test "should destroy elasticseach project source" do
    t = create_team
    p = create_project team: t
    s = create_source
    ps = create_project_source project: p, source: s, disable_es_callbacks: false
    sleep 1
    assert_not_nil MediaSearch.find(get_es_id(ps))
    ps.destroy
    sleep 1
    assert_raise Elasticsearch::Persistence::Repository::DocumentNotFound do
      result = MediaSearch.find(get_es_id(ps))
    end
  end

  test "should index project source" do
    ps = create_project_source disable_es_callbacks: false
    sleep 1
    assert_not_nil MediaSearch.find(get_es_id(ps))
  end

  test "should index related accounts" do
    url = random_url
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: '{"type":"media","data":{"url":"' + url + '","type":"profile"}}')
    ps = create_project_source name: 'New source', url: url, disable_es_callbacks: false
    sleep 1
    result = MediaSearch.find(get_es_id(ps))
    assert_equal ps.source.accounts.map(&:id).sort, result['accounts'].collect{|i| i["id"]}.sort
  end

  test "should update elasticsearch after move source to other projects" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    p2 = create_project team: t
    s = create_source
    User.stubs(:current).returns(u)
    ps = create_project_source project: p, source: s, disable_es_callbacks: false
    sleep 1
    id = get_es_id(ps)
    ms = MediaSearch.find(id)
    assert_equal ms.project_id.to_i, p.id
    assert_equal ms.team_id.to_i, t.id
    ps.project = p2; ps.save!
    sleep 1
    ms = MediaSearch.find(id)
    assert_equal ms.project_id.to_i, p2.id
    assert_equal ms.team_id.to_i, t.id
  end

  test "should create elasticsearch comment" do
    t = create_team
    p = create_project team: t
    m = create_valid_media
    s = create_source
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    ps = create_project_source project: p, source: s, disable_es_callbacks: false
    c = create_comment annotated: pm, text: 'test', disable_es_callbacks: false
    sleep 1
    result = MediaSearch.find(get_es_id(pm))
    assert_equal [c.id], result['comments'].collect{|i| i["id"]}
    c2 = create_comment annotated: ps, text: 'test', disable_es_callbacks: false
    sleep 1
    result = MediaSearch.find(get_es_id(ps))
    assert_equal [c2.id], result['comments'].collect{|i| i["id"]}
  end

  test "should update elasticsearch comment" do
    t = create_team
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    c = create_comment annotated: pm, text: 'test', disable_es_callbacks: false
    c.text = 'test-mod'; c.save!
    sleep 1
    result = MediaSearch.find(get_es_id(pm))
    assert_equal ['test-mod'], result['comments'].collect{|i| i["text"]}
  end

  test "should destroy elasticsearch comment" do
    t = create_team
    p = create_project team: t
    m = create_valid_media
    s = create_source
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    ps = create_project_source project: p, source: s, disable_es_callbacks: false
    c = create_comment annotated: pm, text: 'test', disable_es_callbacks: false
    c2 = create_comment annotated: ps, text: 'test', disable_es_callbacks: false
    sleep 1
    result = MediaSearch.find(get_es_id(pm))
    assert_equal [c.id], result['comments'].collect{|i| i["id"]}
    c.destroy
    c2.destroy
    sleep 1
    result = MediaSearch.find(get_es_id(pm))
    assert_empty result['comments']
    result = MediaSearch.find(get_es_id(ps))
    assert_empty result['comments']
  end

  test "should create elasticsearch tag" do
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p, disable_es_callbacks: false
    t = create_tag annotated: pm, tag: 'sports', disable_es_callbacks: false
    sleep 1
    result = MediaSearch.find(get_es_id(pm))
    assert_equal [t.id], result['tags'].collect{|i| i["id"]}
  end

  test "should update elasticsearch tag" do
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p, disable_es_callbacks: false
    t = create_tag annotated: pm, tag: 'sports', disable_es_callbacks: false
    t.tag = 'sports-news'; t.save!
    sleep 1
    result = MediaSearch.find(get_es_id(pm))
    assert_equal ['sports-news'], result['tags'].collect{|i| i["tag"]}
  end

  test "should create elasticsearch status" do
    m = create_valid_media
    Sidekiq::Testing.inline! do
      pm = create_project_media media: m, disable_es_callbacks: false
      sleep 5
      ms = MediaSearch.find(get_es_id(pm))
      assert_equal 'undetermined', ms.verification_status
      assert_equal 'pending', ms.translation_status
    end
  end

  test "should update elasticsearch status" do
    m = create_valid_media
    Sidekiq::Testing.inline! do
      pm = create_project_media media: m, disable_es_callbacks: false
      s = pm.get_annotations('translation_status').last.load
      s.status = 'translated'
      s.save!
      s = pm.get_annotations('verification_status').last.load
      s.status = 'verified'
      s.save!
      sleep 5
      ms = MediaSearch.find(get_es_id(pm))
      assert_equal 'verified', ms.verification_status
      assert_equal 'translated', ms.translation_status
    end
  end

  test "should create parent if not exists" do
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p
    c = create_comment annotated: pm, disable_es_callbacks: false
    sleep 1
    result = MediaSearch.find(get_es_id(pm))
    assert_not_nil result
  end

  test "should search with reserved characters" do
    # The reserved characters are: + - = && || > < ! ( ) { } [ ] ^ " ~ * ? : \ /
    t = create_team
    p = create_project team: t
    m = create_claim_media quote: 'search quote'
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    sleep 1
    result = CheckSearch.new({keyword: "search / quote"}.to_json)
    # TODO: fix test
    # assert_equal [pm.id], result.medias.map(&:id)
  end

  test "should search by custom status with hyphens" do
    stub_config('app_name', 'Check') do
      value = {
        label: 'Status',
        default: 'foo-bar',
        active: 'foo-bar',
        statuses: [
          { id: 'foo-bar', label: 'Foo Bar', completed: '', description: '', style: 'blue' }
        ]
      }
      t = create_team
      t.set_media_verification_statuses(value)
      t.save!
      p = create_project team: t
      m = create_valid_media
      pm = create_project_media project: p, media: m, disable_es_callbacks: false
      assert_equal 'foo-bar', pm.last_verification_status
      sleep 5
      result = CheckSearch.new({verification_status: ['foo']}.to_json)
      assert_empty result.medias
      result = CheckSearch.new({verification_status: ['bar']}.to_json)
      assert_empty result.medias
      result = CheckSearch.new({verification_status: ['foo-bar']}.to_json)
      assert_equal [pm.id], result.medias.map(&:id)
    end
  end

  test "should search in target reports and return parent instead" do
    t = create_team
    p = create_project team: t
    sm = create_claim_media quote: 'source'
    tm1 = create_claim_media quote: 'target 1'
    tm2 = create_claim_media quote: 'target 2'
    om = create_claim_media quote: 'unrelated target'
    s = create_project_media project: p, media: sm, disable_es_callbacks: false
    t1 = create_project_media project: p, media: tm1, disable_es_callbacks: false
    t2 = create_project_media project: p, media: tm2, disable_es_callbacks: false
    o = create_project_media project: p, media: om, disable_es_callbacks: false
    sleep 1
    result = CheckSearch.new({ keyword: 'target' }.to_json)
    assert_equal [t1.id, t2.id, o.id].sort, result.medias.map(&:id).sort
    r1 = create_relationship source_id: s.id, target_id: t1.id
    r2 = create_relationship source_id: s.id, target_id: t2.id
    sleep 1
    result = CheckSearch.new({ keyword: 'target' }.to_json)
    assert_equal [s.id, o.id].sort, result.medias.map(&:id).sort
    r1.destroy
    r2.destroy
    sleep 1
    result = CheckSearch.new({ keyword: 'target' }.to_json)
    assert_equal [t1.id, t2.id, o.id].sort, result.medias.map(&:id).sort
  end

  test "should filter target reports" do
    t = create_team
    p = create_project team: t
    m = create_claim_media quote: 'test'
    s = create_project_media project: p, disable_es_callbacks: false
    
    t1 = create_project_media project: p, media: m, disable_es_callbacks: false
    create_relationship source_id: s.id, target_id: t1.id
    
    t2 = create_project_media project: p, disable_es_callbacks: false
    create_relationship source_id: s.id, target_id: t2.id
    
    t3 = create_project_media project: p, disable_es_callbacks: false
    create_relationship source_id: s.id, target_id: t3.id
    vs = t3.last_verification_status_obj
    vs.status = 'verified'
    vs.save!

    t4 = create_project_media project: p, disable_es_callbacks: false
    create_relationship source_id: s.id, target_id: t4.id
    ts = t4.last_translation_status_obj
    ts.status = 'ready'
    ts.save!

    sleep 2
    
    assert_equal [t1, t2, t3, t4].sort, Relationship.targets_grouped_by_type(s).first['targets'].sort
    assert_equal [t1].sort, Relationship.targets_grouped_by_type(s, { keyword: 'test' }).first['targets'].sort
    assert_equal [t3].sort, Relationship.targets_grouped_by_type(s, { verification_status: ['verified'] }).first['targets'].sort
    assert_equal [t4].sort, Relationship.targets_grouped_by_type(s, { translation_status: ['ready'] }).first['targets'].sort
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
end
