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
    pm = create_project_media team: t
    u = create_user
    create_team_user user: u, team: t, role: 'admin'
    authenticate_with_user(u)
    d = create_dynamic_annotation annotated: pm, annotation_type: 'metadata'

    query = "query GetById { project_media(ids: \"#{pm.id}\") { dynamic_annotation_metadata { dbid }, dynamic_annotations_metadata { edges { node { dbid } } } } }"
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
    query = "query read { root { current_user { id }, current_team { id }, team_bots_listed { edges { node { dbid, get_description, get_version, get_source_code_url, get_role } } } } }"
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

  test "should get only webhooks installed in a team" do
    t = create_team slug: 'test'
    u = create_user
    create_team_user user: u, team: t, role: 'admin'
    authenticate_with_user(u)

    w1 = create_team_bot set_approved: false, name: 'My Webhook', team_author_id: t.id, set_headers: { authorization: "ABCDEFG" }
    w2 = create_team_bot set_approved: false, name: 'My Second Webhook', team_author_id: t.id
    create_bot_user set_approved: true, name: 'My Bot, not a Webhook', team: t
    create_team_bot set_approved: true, name: 'Other Team\'s Webhook'

    query = <<~GRAPHQL
      query read {
        team(slug: "test") {
          webhooks { edges { node  { name, dbid, events, request_url, headers } } }
        }
      }
    GRAPHQL

    post :create, params: { query: query }
    assert_response :success
    edges = JSON.parse(@response.body)['data']['team']['webhooks']['edges']
    assert_equal ['My Second Webhook', 'My Webhook'], edges.collect{ |e| e['node']['name'] }.sort
    assert_equal [w1.id, w2.id], edges.collect{ |e| e['node']['dbid'] }.sort
    assert_not_nil edges.first['node']['events']
    assert_not_nil edges.first['node']['request_url']
    assert_not_nil edges.first['node']['headers']
  end

  test "should create a webhook, and return team with webhook's list" do
    t = create_team
    u = create_user
    create_team_user user: u, team: t, role: 'admin'
    authenticate_with_user(u)

    query = <<~GRAPHQL
      mutation create {
        createWebhook(input: {
          name: "My Webhook",
          request_url: "https://wwww.example.com",
          events: [{ event: "publish_report", graphql: "data, project_media { title, dbid, status, report_status, media { quote, url }}" }],
          headers: { authorization: "ABCDEFG" }
          }) {
            team { webhooks { edges { node  { name } } } }
            bot_user {
              id
              dbid
              name
              request_url
              events
              headers
          }
        }
      }
    GRAPHQL

    assert_difference 'BotUser.count' do
      post :create, params: { query: query, team: t }
    end
    response = JSON.parse(@response.body).dig('data', 'createWebhook')

    # make sure the webhook was created with all the information
    webhook = BotUser.find(response.dig('bot_user','dbid'))
    assert_not_nil webhook.get_events
    assert_not_nil webhook.get_request_url
    assert_not_nil webhook.get_headers

    # make sure the webhook is returned by the team's webhooks query
    team_webhooks_list = response.dig('team','webhooks','edges')
    assert_equal "My Webhook", team_webhooks_list[0].dig('node','name')
  end

  test "should update a webhook, and return team with webhook's list" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'admin'
    authenticate_with_user(u)

    webhook = create_team_bot set_approved: false, name: 'My Webhook', team_author_id: t.id, events: nil, request_url: nil

    assert_equal webhook.name, 'My Webhook'
    assert_nil webhook.get_headers
    assert_nil webhook.get_events
    assert_nil webhook.get_request_url

    query = <<~GRAPHQL
      mutation update {
        updateWebhook(input: {
          id: "#{webhook.graphql_id}",
          name: "My Updated Webhook",
          request_url: "https://wwww.updated-example.com",
          events: [{ event: "publish_report", graphql: "data, project_media { title, dbid, status, report_status, media { quote, url }}" }],
          headers: { authorization: "ABCDEFG" }
        }) {
            team { webhooks { edges { node  { name } } } }
            bot_user {
              dbid
              name
              request_url
              events
              headers
          }
        }
      }
    GRAPHQL

    post :create, params: { query: query, team: t }
    assert_response :success
    response = JSON.parse(@response.body).dig('data', 'updateWebhook')

    # make sure the original webhook was updated
    assert_equal webhook.id, response.dig('bot_user','dbid')

    webhook = webhook.reload
    assert_equal webhook.name, 'My Updated Webhook'
    assert_not_nil webhook.get_headers
    assert_not_nil webhook.get_events
    assert_not_nil webhook.get_request_url

    # make sure the updated webhook is returned by the team's webhooks query
    team_webhooks_list = response.dig('team','webhooks','edges')
    assert_equal "My Updated Webhook", team_webhooks_list[0].dig('node','name')
  end

  test "should delete a webhook, whether the id format is Webhook/ID or BotUser/ID" do
    u = create_user
    t = create_team slug: 'test'
    create_team_user user: u, team: t, role: 'admin'
    authenticate_with_user(u)

    # Delete with the Webhook/ID
    # This follows the flow from the frontend, where we get the id from the webhooks query
    create_team_bot name: 'My Webhook #1', team_author_id: t.id

    query = <<~GRAPHQL
      query read {
        team(slug: "test") {
          webhooks { edges { node { id } } }
        }
      }
    GRAPHQL

    post :create, params: { query: query }
    assert_response :success
    webhook_1_graphql_id = JSON.parse(@response.body).dig('data','team','webhooks','edges')[0].dig('node','id')

    query = <<~GRAPHQL
      mutation destroy {
        destroyWebhook(input: { id: "#{webhook_1_graphql_id}" }) { deletedId }
      }
    GRAPHQL

    post :create, params: { query: query }
    assert_response :success
    response = JSON.parse(@response.body).dig('data', 'destroyWebhook')
    assert_equal webhook_1_graphql_id, response.dig('deletedId')

    # Delete with the BotUser/ID
    # For this one we get the id directly from the BotUser
    webhook_2 = create_team_bot name: 'My Webhook #2', team_author_id: t.id

    query = <<~GRAPHQL
      mutation destroy {
        destroyWebhook(input: { id: "#{webhook_2.graphql_id}" }) { deletedId }
      }
    GRAPHQL

    post :create, params: { query: query }
    assert_response :success
    response = JSON.parse(@response.body).dig('data', 'destroyWebhook')
    assert_equal webhook_2.graphql_id, response.dig('deletedId')
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
    p1 = create_project_media team: t
    p1a = create_project_media team: t
    p1b = create_project_media team: t
    create_relationship source_id: p1.id, target_id: p1a.id, relationship_type: Relationship.suggested_type
    create_relationship source_id: p1.id, target_id: p1b.id, relationship_type: Relationship.suggested_type
    p2 = create_project_media team: t
    p2a = create_project_media team: t
    p2b = create_project_media team: t
    create_relationship source_id: p2.id, target_id: p2a.id
    create_relationship source_id: p2.id, target_id: p2b.id, relationship_type: Relationship.suggested_type
    post :create, params: { query: "query { project_media(ids: \"#{p1.id}\") { suggested_similar_items_count } }", team: t.slug }; false
    assert_equal 2, JSON.parse(@response.body)['data']['project_media']['suggested_similar_items_count']
  end

  test "should return confirmed similar items count" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'admin'
    authenticate_with_user(u)
    p1 = create_project_media team: t
    p1a = create_project_media team: t
    p1b = create_project_media team: t
    create_relationship source_id: p1.id, target_id: p1a.id, relationship_type: Relationship.confirmed_type
    create_relationship source_id: p1.id, target_id: p1b.id, relationship_type: Relationship.confirmed_type
    p2 = create_project_media team: t
    p2a = create_project_media team: t
    p2b = create_project_media team: t
    create_relationship source_id: p2.id, target_id: p2a.id
    create_relationship source_id: p2.id, target_id: p2b.id, relationship_type: Relationship.confirmed_type
    post :create, params: { query: "query { project_media(ids: \"#{p1.id}\") { confirmed_similar_items_count } }", team: t.slug }; false
    assert_equal 2, JSON.parse(@response.body)['data']['project_media']['confirmed_similar_items_count']
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
    p1 = create_project_media team: t
    p1a = create_project_media team: t
    p1b = create_project_media team: t
    create_relationship source_id: p1.id, target_id: p1a.id, relationship_type: Relationship.suggested_type
    create_relationship source_id: p1.id, target_id: p1b.id, relationship_type: Relationship.suggested_type
    p2 = create_project_media team: t
    p2a = create_project_media team: t
    p2b = create_project_media team: t
    create_relationship source_id: p2.id, target_id: p2a.id
    create_relationship source_id: p2.id, target_id: p2b.id, relationship_type: Relationship.suggested_type
    post :create, params: { query: "query { project_media(ids: \"#{p1.id}\") { is_main, is_secondary, is_confirmed_similar_to_another_item, suggested_main_item { id }, suggested_main_relationship { id }, confirmed_main_item { id }, default_relationships_count, default_relationships(first: 10000) { edges { node { dbid } } }, confirmed_similar_relationships(first: 10000) { edges { node { dbid } } }, suggested_similar_relationships(first: 10000) { edges { node { target { dbid } } } } } }", team: t.slug }
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
    ids = [pm.id, t.id].join(',')
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
    Sidekiq::Testing.inline! do
      u = create_user
      authenticate_with_user(u)
      t = create_team slug: 'team'
      create_team_user user: u, team: t
      pm1 = create_project_media team: t, quote: 'Test 1 Bar', disable_es_callbacks: false
      pm2 = create_project_media team: t, quote: 'Test 2 Foo', disable_es_callbacks: false
      create_relationship source_id: pm1.id, target_id: pm2.id, relationship_type: Relationship.confirmed_type, disable_es_callbacks: false
      pm3 = create_project_media team: t, quote: 'Test 3 Bar', disable_es_callbacks: false
      pm4 = create_project_media team: t, quote: 'Test 4 Foo', disable_es_callbacks: false
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

      query = 'query CheckSearch { search(query: "{\"keyword\":\"Foo\",\"show_similar\":true}") { number_of_results } }'
      post :create, params: { query: query, team: 'team' }
      assert_response :success
      assert_equal 2, JSON.parse(@response.body)['data']['search']['number_of_results']
    end
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
