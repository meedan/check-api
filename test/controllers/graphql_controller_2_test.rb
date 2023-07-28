require_relative '../test_helper'
require 'error_codes'

class GraphqlController2Test < ActionController::TestCase
  def setup
    @controller = Api::V1::GraphqlController.new
    @url = 'https://www.youtube.com/user/MeedanTube'
    require 'sidekiq/testing'
    Sidekiq::Testing.inline!
    super
    TestDynamicAnnotationTables.load!
    User.unstub(:current)
    Team.unstub(:current)
    User.current = nil
    Team.current = nil
  end

  test "should read project media dynamic annotation fields" do
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p
    u = create_user
    create_team_user user: u, team: t, role: 'admin'
    authenticate_with_user(u)
    d = create_dynamic_annotation annotated: pm, annotation_type: 'metadata'

    query = "query GetById { project_media(ids: \"#{pm.id},#{p.id}\") { dynamic_annotation_metadata { dbid }, dynamic_annotations_metadata { edges { node { dbid } } } } }"
    post :create, params: { query: query, team: t.slug }

    assert_response :success
    data = JSON.parse(@response.body)['data']['project_media']
    assert_equal d.id.to_s, data['dynamic_annotation_metadata']['dbid']
    assert_equal d.id.to_s, data['dynamic_annotations_metadata']['edges'][0]['node']['dbid']
  end

  test "should return nil on team_userEdge if user is admin and not a team member" do
    u = create_user
    u.is_admin = true; u.save
    authenticate_with_user(u)
    t = create_team name: 'foo'
    User.current = u

    assert_nil GraphqlCrudOperations.define_conditional_returns(t)[:team_userEdge]

    tu = create_team_user user: u, team: t
    assert_equal tu, GraphqlCrudOperations.define_conditional_returns(t)[:team_userEdge].node

    User.current = nil
  end

  test "should get listed bots, current user and current team" do
    BotUser.delete_all
    authenticate_with_user
    tb1 = create_team_bot set_listed: true
    tb2 = create_team_bot set_listed: false
    query = "query read { root { current_user { id }, current_team { id }, team_bots_listed { edges { node { dbid } } } } }"
    post :create, params: { query: query }
    edges = JSON.parse(@response.body)['data']['root']['team_bots_listed']['edges']
    assert_equal [tb1.id], edges.collect{ |e| e['node']['dbid'] }
  end

  test "should get bot by id" do
    authenticate_with_user
    tb = create_team_bot set_approved: true, name: 'My Bot'
    query = "query read { bot_user(id: #{tb.id}) { name } }"
    post :create, params: { query: query }
    assert_response :success
    name = JSON.parse(@response.body)['data']['bot_user']['name']
    assert_equal 'My Bot', name
  end

  test "should get bots installed in a team" do
    t = create_team slug: 'test'
    u = create_user
    create_team_user user: u, team: t, role: 'admin'
    authenticate_with_user(u)

    tb1 = create_team_bot set_approved: false, name: 'Custom Bot', team_author_id: t.id
    tb2 = create_team_bot set_approved: true, name: 'My Bot'
    tb3 = create_team_bot set_approved: true, name: 'Other Bot'
    create_team_bot_installation user_id: tb2.id, team_id: t.id

    query = 'query read { team(slug: "test") { team_bots { edges { node { name, settings_as_json_schema(team_slug: "test"), team_author { slug } } } } } }'
    post :create, params: { query: query }
    assert_response :success
    edges = JSON.parse(@response.body)['data']['team']['team_bots']['edges']
    assert_equal ['Custom Bot', 'My Bot'], edges.collect{ |e| e['node']['name'] }.sort
    assert edges[0]['node']['team_author']['slug'] == 'test' || edges[1]['node']['team_author']['slug'] == 'test'
  end

  test "should get bot installations in a team" do
    t = create_team slug: 'test'
    u = create_user
    create_team_user user: u, team: t, role: 'admin'
    authenticate_with_user(u)

    tb1 = create_team_bot set_approved: false, name: 'Custom Bot', team_author_id: t.id
    tb2 = create_team_bot set_approved: true, name: 'My Bot'
    tb3 = create_team_bot set_approved: true, name: 'Other Bot'
    create_team_bot_installation user_id: tb2.id, team_id: t.id

    query = 'query read { team(slug: "test") { team_bot_installations { edges { node { team { slug, public_team { id } }, bot_user { name } } } } } }'
    post :create, params: { query: query }
    assert_response :success
    edges = JSON.parse(@response.body)['data']['team']['team_bot_installations']['edges']
    assert_equal ['Custom Bot', 'My Bot'], edges.collect{ |e| e['node']['bot_user']['name'] }.sort
    assert_equal ['test', 'test'], edges.collect{ |e| e['node']['team']['slug'] }
  end

  test "should install bot using mutation" do
    t = create_team slug: 'test'
    u = create_user
    create_team_user user: u, team: t, role: 'admin'
    tb = create_team_bot set_approved: true

    authenticate_with_user(u)

    assert_equal [], t.team_bots

    query = 'mutation create { createTeamBotInstallation(input: { clientMutationId: "1", user_id: ' + tb.id.to_s + ', team_id: ' + t.id.to_s + ' }) { team { dbid }, bot_user { dbid } } }'
    assert_difference 'TeamBotInstallation.count' do
      post :create, params: { query: query }
    end
    data = JSON.parse(@response.body)['data']['createTeamBotInstallation']

    assert_equal [tb], t.reload.team_bots
    assert_equal t.id, data['team']['dbid']
    assert_equal tb.id, data['bot_user']['dbid']
  end

  test "should not get OCR" do
    u = create_user
    t = create_team private: true
    authenticate_with_user(u)

    pm = create_project_media team: t, media: create_uploaded_image

    query = 'mutation ocr { extractText(input: { clientMutationId: "1", id: "' + pm.graphql_id + '" }) { project_media { id } } }'
    post :create, params: { query: query, team: t.slug }

    assert_nil pm.get_annotations('extracted_text').last
  end

  test "should get cached values for list columns" do
    RequestStore.store[:skip_cached_field_update] = false
    t = create_team
    t.set_list_columns = ["updated_at_timestamp", "last_seen", "demand", "share_count", "folder", "linked_items_count", "suggestions_count", "type_of_media", "status", "created_at_timestamp", "report_status", "tags_as_sentence", "media_published_at", "comment_count", "reaction_count", "related_count"]
    t.save!
    5.times { create_project_media team: t }
    u = create_user is_admin: true
    create_team_user user: u, team: t, role: 'admin'
    authenticate_with_user(u)

    query = 'query CheckSearch { search(query: "{}") { medias(first: 5) { edges { node { list_columns_values } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success

    assert_queries(9, '=') do
      query = 'query CheckSearch { search(query: "{}") { medias(first: 5) { edges { node { list_columns_values } } } } }'
      post :create, params: { query: query, team: t.slug }
      assert_response :success
    end
  end

  test "should get team task" do
    t = create_team
    t2 = create_team
    u = create_user
    create_team_user user: u, team: t, role: 'admin'
    authenticate_with_user(u)
    tt = create_team_task team_id: t.id, order: 3

    query = "query GetById { team(id: \"#{t.id}\") { team_task(dbid: #{tt.id}) { dbid } } }"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal tt.id, JSON.parse(@response.body)['data']['team']['team_task']['dbid']

    query = "query GetById { team(id: \"#{t2.id}\") { team_task(dbid: #{tt.id}) { dbid } } }"
    post :create, params: { query: query, team: t2.slug }
    assert_response :success
    assert_nil JSON.parse(@response.body)['data']['team']['team_task']
  end

  test "should return suggested similar items count" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'admin'
    authenticate_with_user(u)
    p = create_project team: t
    p1 = create_project_media project: p
    p1a = create_project_media project: p
    p1b = create_project_media project: p
    create_relationship source_id: p1.id, target_id: p1a.id, relationship_type: Relationship.suggested_type
    create_relationship source_id: p1.id, target_id: p1b.id, relationship_type: Relationship.suggested_type
    p2 = create_project_media project: p
    p2a = create_project_media project: p
    p2b = create_project_media project: p
    create_relationship source_id: p2.id, target_id: p2a.id
    create_relationship source_id: p2.id, target_id: p2b.id, relationship_type: Relationship.suggested_type
    post :create, params: { query: "query { project_media(ids: \"#{p1.id},#{p.id}\") { suggested_similar_items_count } }", team: t.slug }; false
    assert_equal 2, JSON.parse(@response.body)['data']['project_media']['suggested_similar_items_count']
  end

  test "should return confirmed similar items count" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'admin'
    authenticate_with_user(u)
    p = create_project team: t
    p1 = create_project_media project: p
    p1a = create_project_media project: p
    p1b = create_project_media project: p
    create_relationship source_id: p1.id, target_id: p1a.id, relationship_type: Relationship.confirmed_type
    create_relationship source_id: p1.id, target_id: p1b.id, relationship_type: Relationship.confirmed_type
    p2 = create_project_media project: p
    p2a = create_project_media project: p
    p2b = create_project_media project: p
    create_relationship source_id: p2.id, target_id: p2a.id
    create_relationship source_id: p2.id, target_id: p2b.id, relationship_type: Relationship.confirmed_type
    post :create, params: { query: "query { project_media(ids: \"#{p1.id},#{p.id}\") { confirmed_similar_items_count } }", team: t.slug }; false
    assert_equal 2, JSON.parse(@response.body)['data']['project_media']['confirmed_similar_items_count']
  end

  test "should sort search by metadata value where items without metadata value show first on ascending order" do
    RequestStore.store[:skip_cached_field_update] = false
    u = create_user is_admin: true
    t = create_team
    create_team_user team: t, user: u
    tt1 = create_team_task fieldset: 'metadata', team_id: t.id
    tt2 = create_team_task fieldset: 'metadata', team_id: t.id
    t.list_columns = ["task_value_#{tt1.id}", "task_value_#{tt2.id}"]
    t.save!
    pm1 = create_project_media team: t, disable_es_callbacks: false
    pm2 = create_project_media team: t, disable_es_callbacks: false
    pm3 = create_project_media team: t, disable_es_callbacks: false
    pm4 = create_project_media team: t, disable_es_callbacks: false

    m = pm1.get_annotations('task').map(&:load).select{ |t| t.team_task_id == tt1.id }.last
    m.disable_es_callbacks = false
    m.response = { annotation_type: 'task_response_free_text', set_fields: { response_free_text: 'B' }.to_json }.to_json
    m.save!
    m = pm3.get_annotations('task').map(&:load).select{ |t| t.team_task_id == tt1.id }.last
    m.disable_es_callbacks = false
    m.response = { annotation_type: 'task_response_free_text', set_fields: { response_free_text: 'A' }.to_json }.to_json
    m.save!
    m = pm4.get_annotations('task').map(&:load).select{ |t| t.team_task_id == tt1.id }.last
    m.disable_es_callbacks = false
    m.response = { annotation_type: 'task_response_free_text', set_fields: { response_free_text: 'C' }.to_json }.to_json
    m.save!
    sleep 5

    m = pm1.get_annotations('task').map(&:load).select{ |t| t.team_task_id == tt2.id }.last
    m.disable_es_callbacks = false
    m.response = { annotation_type: 'task_response_free_text', set_fields: { response_free_text: 'C' }.to_json }.to_json
    m.save!
    m = pm2.get_annotations('task').map(&:load).select{ |t| t.team_task_id == tt2.id }.last
    m.disable_es_callbacks = false
    m.response = { annotation_type: 'task_response_free_text', set_fields: { response_free_text: 'B' }.to_json }.to_json
    m.save!
    m = pm4.get_annotations('task').map(&:load).select{ |t| t.team_task_id == tt2.id }.last
    m.disable_es_callbacks = false
    m.response = { annotation_type: 'task_response_free_text', set_fields: { response_free_text: 'A' }.to_json }.to_json
    m.save!
    sleep 5

    authenticate_with_user(u)

    query = 'query CheckSearch { search(query: "{\"sort\":\"task_value_' + tt1.id.to_s + '\",\"sort_type\":\"asc\"}") {medias(first:20){edges{node{dbid}}}}}'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
    assert_equal 4, results.size
    assert_equal pm2.id, results.first

    query = 'query CheckSearch { search(query: "{\"sort\":\"task_value_' + tt2.id.to_s + '\",\"sort_type\":\"asc\"}") {medias(first:20){edges{node{dbid}}}}}'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
    assert_equal 4, results.size
    assert_equal pm3.id, results.first

    query = 'query CheckSearch { search(query: "{\"sort\":\"task_value_' + tt1.id.to_s + '\",\"sort_type\":\"desc\"}") {medias(first:20){edges{node{dbid}}}}}'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
    assert_equal 4, results.size
    assert_equal pm2.id, results.last

    query = 'query CheckSearch { search(query: "{\"sort\":\"task_value_' + tt2.id.to_s + '\",\"sort_type\":\"desc\"}") {medias(first:20){edges{node{dbid}}}}}'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
    assert_equal 4, results.size
    assert_equal pm3.id, results.last
  end

  test "should load permissions for GraphQL" do
    pm1 = create_project_media
    pm2 = create_project_media
    User.current = create_user
    PermissionsLoader.any_instance.stubs(:fulfill).returns(nil)
    assert_kind_of Array, PermissionsLoader.new(nil).perform([pm1.id, pm2.id])
    PermissionsLoader.any_instance.unstub(:fulfill)
    User.current = nil
  end

  test "should not get Smooch Bot RSS feed preview if not logged in" do
    u = create_user
    t = create_team
    b = create_team_bot name: 'Smooch', login: 'smooch', set_approved: true, set_events: [], set_request_url: "#{CheckConfig.get('checkdesk_base_url_private')}/api/bots/smooch"
    tbi = create_team_bot_installation team_id: t.id, user_id: b.id
    tu = create_team_user team: t, user: u, role: 'admin'
    url = random_url
    output = "Foo\nhttp://foo\n\nBar\nhttp://bar"
    query = 'query { node(id: "' + tbi.graphql_id + '") { ... on TeamBotInstallation { smooch_bot_preview_rss_feed(rss_feed_url: "' + url + '", number_of_articles: 3) } } }'
    post :create, params: { query: query, team: t.slug }
    assert_match /Sorry/, @response.body
  end

  test "should return similar items" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'admin'
    authenticate_with_user(u)
    p = create_project team: t
    p1 = create_project_media project: p
    p1a = create_project_media project: p
    p1b = create_project_media project: p
    create_relationship source_id: p1.id, target_id: p1a.id, relationship_type: Relationship.suggested_type
    create_relationship source_id: p1.id, target_id: p1b.id, relationship_type: Relationship.suggested_type
    p2 = create_project_media project: p
    p2a = create_project_media project: p
    p2b = create_project_media project: p
    create_relationship source_id: p2.id, target_id: p2a.id
    create_relationship source_id: p2.id, target_id: p2b.id, relationship_type: Relationship.suggested_type
    post :create, params: { query: "query { project_media(ids: \"#{p1.id},#{p.id}\") { is_main, is_secondary, is_confirmed_similar_to_another_item, suggested_main_item { id }, confirmed_main_item { id }, default_relationships_count, default_relationships(first: 10000) { edges { node { dbid } } }, confirmed_similar_relationships(first: 10000) { edges { node { dbid } } }, suggested_similar_relationships(first: 10000) { edges { node { target { dbid } } } } } }", team: t.slug }
    assert_equal [p1a.id, p1b.id].sort, JSON.parse(@response.body)['data']['project_media']['suggested_similar_relationships']['edges'].collect{ |x| x['node']['target']['dbid'] }.sort
  end

  test "should get Smooch Bot RSS feed preview if has permissions" do
    rss = %{
      <rss xmlns:atom="http://www.w3.org/2005/Atom" version="2.0">
        <channel>
          <title>Test</title>
          <link>http://test.com/rss.xml</link>
          <description>Test</description>
          <language>en</language>
          <lastBuildDate>Fri, 09 Oct 2020 18:00:48 GMT</lastBuildDate>
          <managingEditor>test@test.com (editors)</managingEditor>
          <item>
            <title>Foo</title>
            <description>This is the description.</description>
            <pubDate>Wed, 11 Apr 2018 15:25:00 GMT</pubDate>
            <link>http://foo</link>
          </item>
          <item>
            <title>Bar</title>
            <description>This is the description.</description>
            <pubDate>Wed, 10 Apr 2018 15:25:00 GMT</pubDate>
            <link>http://bar</link>
          </item>
        </channel>
      </rss>
    }
    u = create_user
    t = create_team
    b = create_team_bot name: 'Smooch', login: 'smooch', set_approved: true, set_events: [], set_request_url: "#{CheckConfig.get('checkdesk_base_url_private')}/api/bots/smooch"
    tbi = create_team_bot_installation team_id: t.id, user_id: b.id
    tu = create_team_user team: t, user: u, role: 'admin'
    authenticate_with_user(u)
    url = random_url
    WebMock.stub_request(:get, url).to_return(status: 200, body: rss)
    output = "Foo\nhttp://foo\n\nBar\nhttp://bar"
    query = 'query { node(id: "' + tbi.graphql_id + '") { ... on TeamBotInstallation { smooch_bot_preview_rss_feed(rss_feed_url: "' + url + '", number_of_articles: 3) } } }'
    post :create, params: { query: query, team: t.slug }
    assert_no_match /Sorry/, @response.body
    assert_equal output, JSON.parse(@response.body)['data']['node']['smooch_bot_preview_rss_feed']
  end

  test "should get item tasks by fieldset" do
    u = create_user is_admin: true
    t = create_team
    pm = create_project_media team: t
    t1 = create_task annotated: pm, fieldset: 'tasks'
    t2 = create_task annotated: pm, fieldset: 'metadata'
    ids = [pm.id, nil, t.id].join(',')
    authenticate_with_user(u)

    query = 'query { project_media(ids: "' + ids + '") { tasks(fieldset: "tasks", first: 1000) { edges { node { dbid } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal t1.id, JSON.parse(@response.body)['data']['project_media']['tasks']['edges'][0]['node']['dbid'].to_i

    query = 'query { project_media(ids: "' + ids + '") { tasks(fieldset: "metadata", first: 1000) { edges { node { dbid } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal t2.id, JSON.parse(@response.body)['data']['project_media']['tasks']['edges'][0]['node']['dbid'].to_i
    s = create_source team: t
    t3 = create_task annotated: s, fieldset: 'metadata'
    query = 'query { source(id: "' + s.id.to_s + '") { tasks(fieldset: "metadata", first: 1000) { edges { node { dbid } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal t3.id, JSON.parse(@response.body)['data']['source']['tasks']['edges'][0]['node']['dbid'].to_i
  end

  test "should get team tasks by fieldset" do
    u = create_user is_admin: true
    t = create_team
    t1 = create_team_task team_id: t.id, fieldset: 'tasks'
    t2 = create_team_task team_id: t.id, fieldset: 'metadata'
    authenticate_with_user(u)

    query = 'query { team { team_tasks(fieldset: "tasks", first: 1000) { edges { node { dbid } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal t1.id, JSON.parse(@response.body)['data']['team']['team_tasks']['edges'][0]['node']['dbid'].to_i

    query = 'query { team { team_tasks(fieldset: "metadata", first: 1000) { edges { node { dbid } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal t2.id, JSON.parse(@response.body)['data']['team']['team_tasks']['edges'][0]['node']['dbid'].to_i
  end

  test "should update task options" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'admin'
    tt = create_team_task team_id: t.id, label: 'Select one', type: 'single_choice', options: ['ans_a', 'ans_b', 'ans_c']
    pm = create_project_media team: t
    authenticate_with_user(u)
    query = 'mutation { updateTeamTask(input: { clientMutationId: "1", id: "' + tt.graphql_id + '", label: "Select only one", json_options: "[ \"bli\", \"blo\", \"bla\" ]", options_diff: "{ \"deleted\": [\"ans_c\"], \"changed\": { \"ans_a\": \"bli\", \"ans_b\": \"blo\" }, \"added\": \"bla\" }" }) { team_task { label } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal 'Select only one', tt.reload.label
    assert_equal ['bli', 'blo', 'bla'], tt.options
  end

  test "should get team fieldsets" do
    u = create_user is_admin: true
    authenticate_with_user(u)
    t = create_team
    query = 'query { team { get_fieldsets } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_kind_of Array, JSON.parse(@response.body)['data']['team']['get_fieldsets']
  end

  test "should get number of results without similar items" do
    u = create_user
    authenticate_with_user(u)
    t = create_team slug: 'team'
    create_team_user user: u, team: t
    p = create_project team: t
    pm1 = create_project_media project: p, quote: 'Test 1 Bar', disable_es_callbacks: false
    pm2 = create_project_media project: p, quote: 'Test 2 Foo', disable_es_callbacks: false
    create_relationship source_id: pm1.id, target_id: pm2.id, relationship_type: Relationship.confirmed_type, disable_es_callbacks: false
    pm3 = create_project_media project: p, quote: 'Test 3 Bar', disable_es_callbacks: false
    pm4 = create_project_media project: p, quote: 'Test 4 Foo', disable_es_callbacks: false
    create_relationship source_id: pm3.id, target_id: pm4.id, relationship_type: Relationship.confirmed_type, disable_es_callbacks: false
    sleep 1

    query = 'query CheckSearch { search(query: "{\"keyword\":\"Test\"}") { number_of_results } }'
    post :create, params: { query: query, team: 'team' }
    assert_response :success
    assert_equal 2, JSON.parse(@response.body)['data']['search']['number_of_results']

    query = 'query CheckSearch { search(query: "{\"keyword\":\"Test\",\"show_similar\":false}") { number_of_results } }'
    post :create, params: { query: query, team: 'team' }
    assert_response :success
    assert_equal 2, JSON.parse(@response.body)['data']['search']['number_of_results']

    query = 'query CheckSearch { search(query: "{\"keyword\":\"Test\",\"show_similar\":true}") { number_of_results } }'
    post :create, params: { query: query, team: 'team' }
    assert_response :success
    assert_equal 4, JSON.parse(@response.body)['data']['search']['number_of_results']

    query = 'query CheckSearch { search(query: "{\"keyword\":\"Foo\",\"show_similar\":false}") { number_of_results } }'
    post :create, params: { query: query, team: 'team' }
    assert_response :success
    assert_equal 2, JSON.parse(@response.body)['data']['search']['number_of_results']
  end

  test "should replace blank project media by another" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'admin'
    old = create_project_media team: t, media: Blank.create!
    r = publish_report(old)
    new = create_project_media team: t
    authenticate_with_user(u)

    query = 'mutation { replaceProjectMedia(input: { clientMutationId: "1", project_media_to_be_replaced_id: "' + old.graphql_id + '", new_project_media_id: "' + new.graphql_id + '" }) { old_project_media_deleted_id, new_project_media { dbid } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    data = JSON.parse(@response.body)['data']['replaceProjectMedia']
    assert_equal old.graphql_id, data['old_project_media_deleted_id']
    assert_equal new.id, data['new_project_media']['dbid']
    assert_nil ProjectMedia.find_by_id(old.id)
    assert_equal r, new.get_dynamic_annotation('report_design')
  end

  test "should set and get Slack settings for team" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'admin'
    authenticate_with_user(u)
    query = 'mutation { updateTeam(input: { clientMutationId: "1", id: "' + t.graphql_id + '", slack_notifications: "[{\"label\":\"not #1\",\"event_type\":\"any_activity\",\"slack_channel\":\"#list\"}]" }) { team { get_slack_notifications } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_not_nil JSON.parse(@response.body)['data']['updateTeam']['team']['get_slack_notifications']
  end

  test "should set and get special list filters for team" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'admin'
    authenticate_with_user(u)
    # Tipline list
    query = 'mutation { updateTeam(input: { clientMutationId: "1", id: "' + t.graphql_id + '", tipline_inbox_filters: "{\"read\":[\"0\"],\"projects\":[\"-1\"]}" }) { team { get_tipline_inbox_filters } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_not_nil JSON.parse(@response.body)['data']['updateTeam']['team']['get_tipline_inbox_filters']
    # Suggested match list
    query = 'mutation { updateTeam(input: { clientMutationId: "1", id: "' + t.graphql_id + '", suggested_matches_filters: "{\"projects\":[\"-1\"],\"suggestions_count\":{\"min\":5,\"max\":10}}" }) { team { get_suggested_matches_filters } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_not_nil JSON.parse(@response.body)['data']['updateTeam']['team']['get_suggested_matches_filters']
  end
end
