require_relative '../test_helper'

class ElasticSearchTest < ActionController::TestCase
  def setup
    super
    setup_elasticsearch
  end

  test "should search media" do
    u = create_user
    @team = create_team
    m1 = create_valid_media
    pm1 = create_project_media team: @team, media: m1, disable_es_callbacks: false
    authenticate_with_user(u)
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "title_a", "description":"search_desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m2 = create_media(account: create_valid_account, url: url)
    pm2 = create_project_media team: @team, media: m2, disable_es_callbacks: false
    sleep 2
    Team.stubs(:current).returns(@team)
    query = 'query Search { search(query: "{\"keyword\":\"title_a\"}") { number_of_results, medias(first: 10) { edges { node { dbid } } } } }'
    post :create, params: { query: query }
    Team.unstub(:current)
    assert_response :success
    ids = []
    JSON.parse(@response.body)['data']['search']['medias']['edges'].each do |id|
      ids << id["node"]["dbid"]
    end
    assert_equal [pm2.id], ids
  end

  test "should read first response from task" do
    u = create_user
    @team = create_team
    create_team_user user: u, team: @team
    m = create_valid_media
    pm = create_project_media team: @team, media: m, disable_es_callbacks: false
    authenticate_with_user(u)
    t = create_task annotated: pm
    at = create_annotation_type annotation_type: 'task_response_test'
    ft2 = DynamicAnnotation::FieldType.where(field_type: 'text').last || create_field_type(field_type: 'text')
    create_field_instance annotation_type_object: at, field_type_object: ft2, name: 'response'
    t.response = { annotation_type: 'task_response_test', set_fields: { response: 'Test' }.to_json }.to_json
    t.save!
    query = "query { project_media(ids: \"#{pm.id}\") { tasks { edges { node { jsonoptions, first_response_value, first_response { content } } } } } }"
    post :create, params: { query: query, team: @team.slug }
    assert_response :success
    node = JSON.parse(@response.body)['data']['project_media']['tasks']['edges'][0]['node']
    fields = node['first_response']['content']
    assert_equal 'Test', JSON.parse(fields).select{ |f| f['field_type'] == 'text' }.first['value']
    assert_equal 'Test', node['first_response_value']
  end

  test "should search with keyword" do
    t = create_team
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
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
    pm = create_project_media team: t, media: m, disable_es_callbacks: false
    sleep 1
    Team.current = t
    result = CheckSearch.new({keyword: "non_exist_title"}.to_json)
    assert_empty result.medias
    result = CheckSearch.new({keyword: "search_title"}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
    # overide title then search
    pm.analysis = { title: 'search_title_a' }
    sleep 1
    result = CheckSearch.new({keyword: "search_title_a"}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
    # search with original title
    result = CheckSearch.new({keyword: "search_title"}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
    # search in description
    result = CheckSearch.new({keyword: "search_desc"}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
    # add keyword and same account to multiple medias
    media_url = 'http://www.facebook.com/meedan/posts/456789'
    data = { url: media_url, author_url: author_url, type: 'item', description: 'search_desc' }
    response = '{"type":"media","data":' + data.to_json + '}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: media_url } }).to_return(body: response)
    m2 = create_media url: media_url, account_id: nil, user_id: nil, account: nil, user: nil
    pm2 = create_project_media team: t, media: m2, disable_es_callbacks: false
    sleep 1
    result = CheckSearch.new({keyword: "search_desc"}.to_json)
    assert_equal [pm.id, pm2.id].sort, result.medias.map(&:id).sort
    # search in quote (with and operator)
    m = create_claim_media quote: 'keyworda and keywordb'
    pm = create_project_media team: t, media: m, disable_es_callbacks: false
    sleep 1
    result = CheckSearch.new({keyword: "keyworda and keywordb"}.to_json)
    assert_equal [pm.id], result.medias.map(&:id)
  end

  test "should search with tags or status" do
    t = create_team
    m = create_valid_media
    pm = create_project_media team: t, media: m, disable_es_callbacks: false
    m2 = create_valid_media
    pm2 = create_project_media team: t, media: m2, disable_es_callbacks: false
    create_status status: 'verified', annotated: pm, disable_es_callbacks: false
    create_tag tag: 'sports', annotated: pm, disable_es_callbacks: false
    create_tag tag: 'sports', annotated: pm2, disable_es_callbacks: false
    create_tag tag: 'newtag', annotated: pm2, disable_es_callbacks: false
    create_tag tag: 'news', annotated: pm, disable_es_callbacks: false
    sleep 2
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

  test "should search tags case-insensitive" do
    t = create_team
    m = create_valid_media
    pm = create_project_media team: t, media: m, disable_es_callbacks: false
    create_tag tag: 'two Words', annotated: pm, disable_es_callbacks: false
    sleep 2
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

  test "should have unique id per params" do
    t = create_team
    Team.current = t
    s1 = CheckSearch.new({ keyword: 'foo' }.to_json)
    s2 = CheckSearch.new({ keyword: 'foo' }.to_json)
    s3 = CheckSearch.new({ keyword: 'bar' }.to_json)
    assert_equal s1.id, s2.id
    assert_not_equal s1.id, s3.id
  end

  test "should ensure project_medias to be an alias of medias" do
    pm = create_project_media
    cs = CheckSearch.new('{}', nil, pm.team_id)
    assert_equal cs.medias.to_a, cs.project_medias.to_a
  end

  test "should get search id" do
    assert_not_nil CheckSearch.id
    assert_not_nil CheckSearch.new('{}', nil, create_team.id).id
  end

  test "should get Pusher channel" do
    t = create_team
    cs = CheckSearch.new({ 'parent' => { 'type' => 'team', 'slug' => t.slug } }.to_json, nil, t.id)
    assert_equal t.pusher_channel, cs.pusher_channel
  end

  test "should search by numeric range for tasks" do
    number = create_field_type field_type: 'number', label: 'Number'
    at = create_annotation_type annotation_type: 'task_response_number', label: 'Task Response Number'
    create_field_instance annotation_type_object: at, name: 'response_number', label: 'Response', field_type_object: number, optional: true
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    tt = create_team_task team_id: t.id, type: 'number'
    with_current_user_and_team(u ,t) do
      pm = create_project_media team: t, disable_es_callbacks: false
      pm2 = create_project_media team: t, disable_es_callbacks: false
      pm3 = create_project_media team: t, disable_es_callbacks: false
      pm2_tt = pm2.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm2_tt.response = { annotation_type: 'task_response_number', set_fields: { response_number: 2 }.to_json }.to_json
      pm2_tt.save!
      pm3_tt = pm3.annotations('task').select{|t| t.team_task_id == tt.id}.last
      pm3_tt.response = { annotation_type: 'task_response_number', set_fields: { response_number: 4 }.to_json }.to_json
      pm3_tt.save!
      sleep 2
      results = CheckSearch.new({ team_tasks: [{ id: tt.id, response: 'NUMERIC_RANGE', range: { min: 2 }}]}.to_json)
      assert_equal [pm2.id, pm3.id], results.medias.map(&:id).sort
      results = CheckSearch.new({ team_tasks: [{ id: tt.id, response: 'NUMERIC_RANGE', range: { min: 2, max: 5 }}]}.to_json)
      assert_equal [pm2.id, pm3.id], results.medias.map(&:id).sort
      results = CheckSearch.new({ team_tasks: [{ id: tt.id, response: 'NUMERIC_RANGE', range: { min: 2, max: 3 }}]}.to_json)
      assert_equal [pm2.id], results.medias.map(&:id)
      results = CheckSearch.new({ team_tasks: [{ id: tt.id, response: 'NUMERIC_RANGE', range: { min: 3, max: 5 }}]}.to_json)
      assert_equal [pm3.id], results.medias.map(&:id)
    end
  end

  # Please add new tests to test/controllers/elastic_search_7_test.rb
end
