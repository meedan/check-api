require_relative '../test_helper'
require 'error_codes'
require 'sidekiq/testing'

class GraphqlController12Test < ActionController::TestCase
  def setup
    @controller = Api::V1::GraphqlController.new
    TestDynamicAnnotationTables.load!

    @u = create_user
    @t = create_team
    create_team_user team: @t, user: @u, role: 'admin'
  end

  def teardown
    User.unstub(:current)
    Team.unstub(:current)
    User.current = nil
    Team.current = nil
  end

  test "should list feed invitations for a feed" do
    f = create_feed team: @t
    fi = create_feed_invitation feed: f
    create_feed_invitation

    authenticate_with_user(@u)
    query = 'query { feed(id: "' + f.id.to_s + '") { feed_invitations(first: 10) { edges { node { id, dbid } } } } }'
    post :create, params: { query: query }
    assert_response :success
    assert_equal [fi.id], JSON.parse(@response.body)['data']['feed']['feed_invitations']['edges'].collect{ |edge| edge['node']['dbid'] }
  end

  test "should list feed invitations for a user" do
    fi = create_feed_invitation email: @u.email
    create_feed_invitation

    authenticate_with_user(@u)
    query = 'query { me { feed_invitations(first: 10) { edges { node { id, dbid } } } } }'
    post :create, params: { query: query }
    assert_response :success
    assert_equal [fi.id], JSON.parse(@response.body)['data']['me']['feed_invitations']['edges'].collect{ |edge| edge['node']['dbid'] }
  end

  test "should list teams for a feed" do
    t2 = create_team
    f = create_feed team: @t
    create_feed_team feed: f, team: t2
    create_feed_team

    authenticate_with_user(@u)
    query = 'query { feed(id: "' + f.id.to_s + '") { teams(first: 10) { edges { node { id, dbid } } } } }'
    post :create, params: { query: query }
    assert_response :success
    assert_equal [@t.id, t2.id].sort, JSON.parse(@response.body)['data']['feed']['teams']['edges'].collect{ |edge| edge['node']['dbid'] }.sort
  end

  test "should create feed invitation" do
    f = create_feed team: @t

    authenticate_with_user(@u)
    query = 'mutation { createFeedInvitation(input: { feed_id: ' + f.id.to_s + ', email: "' + random_email + '"}) { feed_invitation { id } } }'
    assert_difference 'FeedInvitation.count' do
      post :create, params: { query: query }
    end
    assert_response :success
  end

  test "should not create feed invitation" do
    f = create_feed

    authenticate_with_user(@u)
    query = 'mutation { createFeedInvitation(input: { feed_id: ' + f.id.to_s + ', email: "' + random_email + '"}) { feed_invitation { id } } }'
    assert_no_difference 'FeedInvitation.count' do
      post :create, params: { query: query }
    end
    assert_response 400
  end

  test "should destroy feed invitation" do
    f = create_feed team: @t
    fi = create_feed_invitation feed: f

    authenticate_with_user(@u)
    query = 'mutation { destroyFeedInvitation(input: { id: "' + fi.graphql_id + '" }) { deletedId } }'
    assert_difference 'FeedInvitation.count', -1 do
      post :create, params: { query: query }
    end
    assert_response :success
  end

  test "should not destroy feed invitation" do
    fi = create_feed_invitation

    authenticate_with_user(@u)
    query = 'mutation { destroyFeedInvitation(input: { id: "' + fi.graphql_id + '" }) { deletedId } }'
    assert_no_difference 'FeedInvitation.count' do
      post :create, params: { query: query }
    end
    assert_response 400
  end

  test "should accept feed invitation" do
    fi = create_feed_invitation email: @u.email

    authenticate_with_user(@u)
    query = 'mutation { acceptFeedInvitation(input: { id: ' + fi.id.to_s + ', team_id: ' + @t.id.to_s + ' }) { success } }'
    assert_difference 'FeedTeam.count' do
      post :create, params: { query: query }
    end
    assert_response :success
    assert JSON.parse(@response.body).dig('data', 'acceptFeedInvitation', 'success')
  end

  test "should not accept feed invitation if it's not the same email" do
    fi = create_feed_invitation

    authenticate_with_user(@u)
    query = 'mutation { acceptFeedInvitation(input: { id: ' + fi.id.to_s + ', team_id: ' + @t.id.to_s + ' }) { success } }'
    assert_no_difference 'FeedTeam.count' do
      post :create, params: { query: query }
    end
    assert_response :success
    assert_nil JSON.parse(@response.body).dig('data', 'acceptFeedInvitation', 'success')
  end

  test "should not accept feed invitation if it's not a member of the target workspace" do
    fi = create_feed_invitation email: @u.email

    authenticate_with_user(@u)
    query = 'mutation { acceptFeedInvitation(input: { id: ' + fi.id.to_s + ', team_id: ' + create_team.id.to_s + ' }) { success } }'
    assert_no_difference 'FeedTeam.count' do
      post :create, params: { query: query }
    end
    assert_response :success
    assert !JSON.parse(@response.body).dig('data', 'acceptFeedInvitation', 'success')
  end

  test "should reject feed invitation" do
    fi = create_feed_invitation email: @u.email

    authenticate_with_user(@u)
    query = 'mutation { rejectFeedInvitation(input: { id: ' + fi.id.to_s + ' }) { success } }'
    post :create, params: { query: query }
    assert_response :success
    assert JSON.parse(@response.body).dig('data', 'rejectFeedInvitation', 'success')
  end

  test "should not reject feed invitation if it's not the same email" do
    fi = create_feed_invitation

    authenticate_with_user(@u)
    query = 'mutation { rejectFeedInvitation(input: { id: ' + fi.id.to_s + ' }) { success } }'
    post :create, params: { query: query }
    assert_response :success
    assert !JSON.parse(@response.body).dig('data', 'rejectFeedInvitation', 'success')
  end

  test "should read feed invitation" do
    fi = create_feed_invitation email: @u.email

    authenticate_with_user(@u)
    query = 'query { feed_invitation(id: ' + fi.id.to_s + ') { id } }'
    post :create, params: { query: query }
    assert_response :success
    assert_not_nil JSON.parse(@response.body).dig('data', 'feed_invitation')
  end

  test "should not read feed invitation" do
    fi = create_feed_invitation

    authenticate_with_user(@u)
    query = 'query { feed_invitation(id: ' + fi.id.to_s + ') { dbid } }'
    post :create, params: { query: query }
    assert_response :success
    assert_nil JSON.parse(@response.body).dig('data', 'feed_invitation')
  end

  test "should read feed invitation based on feed ID and current user email" do
    fi = create_feed_invitation email: @u.email

    authenticate_with_user(@u)
    query = 'query { feed_invitation(feedId: ' + fi.feed_id.to_s + ') { id } }'
    post :create, params: { query: query }
    assert_response :success
    assert_not_nil JSON.parse(@response.body).dig('data', 'feed_invitation')
  end

  test "should not read feed invitation based on feed ID and current user email" do
    fi = create_feed_invitation

    authenticate_with_user(@u)
    query = 'query { feed_invitation(feedId: ' + fi.feed_id.to_s + ') { id } }'
    post :create, params: { query: query }
    assert_response :success
    assert_nil JSON.parse(@response.body).dig('data', 'feed_invitation')
  end

  test "should read feed team" do
    ft = create_feed_team team: @t

    authenticate_with_user(@u)
    query = 'query { feed_team(id: ' + ft.id.to_s + ') { id } }'
    post :create, params: { query: query }
    assert_response :success
    assert_not_nil JSON.parse(@response.body).dig('data', 'feed_team')
  end

  test "should not read feed team" do
    ft = create_feed_team

    authenticate_with_user(@u)
    query = 'query { feed_team(id: ' + ft.id.to_s + ') { id } }'
    post :create, params: { query: query }
    assert_response :success
    assert_nil JSON.parse(@response.body).dig('data', 'feed_team')
  end

  test "should read feed team based on feed ID and team slug" do
    ft = create_feed_team team: @t

    authenticate_with_user(@u)
    query = 'query { feed_team(feedId: ' + ft.feed_id.to_s + ', teamSlug: "' + @t.slug + '") { id } }'
    post :create, params: { query: query }
    assert_response :success
    assert_not_nil JSON.parse(@response.body).dig('data', 'feed_team')
  end

  test "should not read feed team based on feed ID and team slug" do
    ft = create_feed_team

    authenticate_with_user(@u)
    query = 'query { feed_team(feedId: ' + ft.feed_id.to_s + ', teamSlug: "' + ft.team.slug + '") { id } }'
    post :create, params: { query: query }
    assert_response :success
    assert_nil JSON.parse(@response.body).dig('data', 'feed_team')
  end

  test "should always apply team filter on search" do
    setup_elasticsearch
    t1 = create_team
    t2 = create_team
    pm1 = create_project_media team: t1, quote: 'Test 1', disable_es_callbacks: false
    pm2 = create_project_media team: t2, quote: 'Test 2', disable_es_callbacks: false
    sleep 2 # Wait for content to be indexed

    authenticate_with_user(@u)

    # ElasticSearch
    query = 'query { search(query: "{\"keyword\":\"Test\",\"operator\":\"or\"}") { number_of_results } }'
    post :create, params: { query: query, team: t1.slug }
    assert_response :success
    assert_equal 1, JSON.parse(@response.body).dig('data', 'search', 'number_of_results')

    # PostgreSQL
    query = 'query { search(query: "{\"operator\":\"or\"}") { number_of_results } }'
    post :create, params: { query: query, team: t1.slug }
    assert_response :success
    assert_equal 1, JSON.parse(@response.body).dig('data', 'search', 'number_of_results')
  end

  test "should set and get feed data points" do
    authenticate_with_user(@u)

    query = 'mutation { createFeed(input: { name: "' + random_string + '", dataPoints: [1, 2, 3], licenses: [] }) { feed { dbid, data_points } } }'
    assert_difference 'Feed.count' do
      post :create, params: { query: query, team: @t.slug }
    end
    assert_response :success

    feed = Feed.find(JSON.parse(@response.body).dig('data', 'createFeed', 'feed', 'dbid'))
    assert_equal [1, 2, 3].sort, feed.data_points.sort

    query = 'query { feed(id: ' + feed.id.to_s + ') { data_points } }'
    post :create, params: { query: query, team: @t.slug }
    assert_response :success
    assert_equal [1, 2, 3].sort, JSON.parse(@response.body).dig('data', 'feed', 'data_points').sort
  end

  test "should return me type after update user" do
    user = create_user
    authenticate_with_user(user)
    post :create, params: { query: 'query Query { me { id } }' }
    assert_response :success
    id = JSON.parse(@response.body)['data']['me']['id']
    query = 'mutation { updateUser(input: { clientMutationId: "1", id: "' + id + '", name: "update name" }) { user { dbid }, me { dbid } } }'
    post :create, params: { query: query }
    assert_response :success
    data = JSON.parse(@response.body)['data']['updateUser']['me']
    assert_equal user.id, data['dbid']
  end

  test "should ensure graphql introspection is disabled" do
    user = create_user
    authenticate_with_user(user)
    INTROSPECTION_QUERY = <<-GRAPHQL
      {
        __schema {
          queryType {
            name
          }
        }
      }
    GRAPHQL

    post :create, params: { query: INTROSPECTION_QUERY }
    assert_response :success
    response_body = JSON.parse(response.body)
    assert_equal response_body['errors'][0]['message'], "Field '__schema' doesn't exist on type 'Query'"
  end

  test "should return feed clusters" do
    n = random_number(5) # In order to avoid N + 1 query problems, we need to be sure that the number of SQL queries is the same regardless the number of clusters
    puts "Testing with #{n} clusters"
    f = create_feed team: @t
    n.times { create_cluster feed: f, team_ids: [@t.id], project_media: create_project_media(team: @t) }

    authenticate_with_user(@u)
    query = 'query { feed(id: "' + f.id.to_s + '") { clusters_count, clusters(first: 10) { edges { node { id, dbid, fact_checks_count, first_item_at, last_item_at, last_request_date, last_fact_check_date, center { id }, teams(first: 10) { edges { node { name, avatar } } } } } } } }'
    assert_queries 21, '<=' do
      post :create, params: { query: query }
    end
    assert_response :success
    assert_equal n, JSON.parse(@response.body)['data']['feed']['clusters']['edges'].size
  end

  test "should return a feed cluster" do
    f = create_feed team: @t, data_points: [1, 2]
    pm = create_project_media team: @t
    create_fact_check claim_description: create_claim_description(project_media: pm)
    c = create_cluster feed: f, team_ids: [@t.id]
    create_cluster_project_media cluster: c, project_media: pm

    authenticate_with_user(@u)
    query = 'query { feed(id: "' + f.id.to_s + '") { cluster(project_media_id: ' + pm.id.to_s + ') { dbid, project_media(id: ' + pm.id.to_s + ') { id, articles_count, imported_from_feed { id } }, project_medias(teamId: ' + @t.id.to_s + ', first: 1) { edges { node { id } } }, cluster_teams(first: 10) { edges { node { id, team { name }, last_request_date, media_count, requests_count, fact_checks(first: 1) { edges { node { id } } } } } } } } }'
    post :create, params: { query: query }
    assert_response :success
    assert_equal c.id, JSON.parse(@response.body)['data']['feed']['cluster']['dbid']
  end

  test "should import medias from the feed by creating a new item" do
    Sidekiq::Testing.inline!
    t = create_team
    pm1 = create_project_media team: t
    pm2 = create_project_media team: t
    f = create_feed team: @t
    f.teams << t
    c = create_cluster feed: f, team_ids: [t.id], project_media: pm1
    create_cluster_project_media cluster: c, project_media: pm2
    assert_equal 0, @t.project_medias.count

    authenticate_with_user(@u)
    query = "mutation { feedImportMedia(input: { feedId: #{f.id}, projectMediaId: #{pm1.id} }) { projectMedia { id } } }"
    post :create, params: { query: query, team: @t.slug }
    assert_response :success
    assert_equal 2, @t.reload.project_medias.count
  end

  test "should import medias from the feed by adding to existing item" do
    Sidekiq::Testing.inline!
    pm = create_project_media team: @t
    t = create_team
    pm1 = create_project_media team: t
    pm2 = create_project_media team: t
    f = create_feed team: @t
    f.teams << t
    c = create_cluster feed: f, team_ids: [t.id], project_media: pm1
    create_cluster_project_media cluster: c, project_media: pm2
    assert_equal 1, @t.project_medias.count

    authenticate_with_user(@u)
    query = "mutation { feedImportMedia(input: { feedId: #{f.id}, projectMediaId: #{pm1.id}, parentId: #{pm.id} }) { projectMedia { id } } }"
    post :create, params: { query: query, team: @t.slug }
    assert_response :success
    assert_equal 3, @t.reload.project_medias.count
  end

  test "should get team articles (explainers)" do
    Sidekiq::Testing.fake!
    @t.set_explainers_enabled = true
    @t.save!
    ex = create_explainer team: @t
    tag = create_tag annotated: ex
    authenticate_with_user(@u)
    query = "query { team(slug: \"#{@t.slug}\") { get_explainers_enabled, articles_count(article_type: \"explainer\"), articles(article_type: \"explainer\") { edges { node { ... on Explainer { dbid, tags } } } } } }"
    post :create, params: { query: query, team: @t.slug }
    assert_response :success
    team = JSON.parse(@response.body)['data']['team']
    assert_equal 1, team['articles_count']
    assert team['get_explainers_enabled']
    data = team['articles']['edges']
    assert_equal [ex.id], data.collect{ |edge| edge['node']['dbid'] }
  end

  test "should get team articles (fact-checks)" do
    Sidekiq::Testing.fake!
    authenticate_with_user(@u)
    pm = create_project_media team: @t
    cd = create_claim_description project_media: pm
    fc = create_fact_check claim_description: cd, tags: ['foo', 'bar']
    query = "query { team(slug: \"#{@t.slug}\") { articles_count(article_type: \"fact-check\"), articles(article_type: \"fact-check\") { edges { node { ... on FactCheck { dbid, tags } } } } } }"
    post :create, params: { query: query, team: @t.slug }
    assert_response :success
    team = JSON.parse(@response.body)['data']['team']
    assert_equal 1, team['articles_count']
    data = team['articles']['edges']
    assert_equal [fc.id], data.collect{ |edge| edge['node']['dbid'] }
  end

  test "should get all team articles" do
    Sidekiq::Testing.fake!
    authenticate_with_user(@u)
    pm = create_project_media team: @t
    cd = create_claim_description project_media: pm
    create_fact_check claim_description: cd, title: 'Foo'
    sleep 1
    create_explainer team: @t, title: 'Test'
    sleep 1
    create_explainer team: @t, title: 'Bar'
    query = "query { team(slug: \"#{@t.slug}\") { articles(first: 2, sort: \"title\", sort_type: \"asc\") { edges { node { ... on Explainer { title }, ... on FactCheck { title } } } }, articles_count } }"
    post :create, params: { query: query, team: @t.slug }
    assert_response :success
    data = JSON.parse(@response.body)['data']
    assert_equal 3, data.dig('team', 'articles_count')
    assert_equal ['Bar', 'Foo'], data.dig('team', 'articles', 'edges').collect{ |node| node.dig('node', 'title') }
  end

  test "should create api key" do
    t = create_team
    u = create_user
    create_team_user user: u, team: t, role: 'admin'
    authenticate_with_user(u)
    query = 'mutation create { createApiKey(input: { title: "test-api-key", description: "This is a test api key" }) { api_key { id title description } } }'

    assert_difference 'ApiKey.count' do
      post :create, params: { query: query, team: t }
    end
  end

  test "should get all api keys in a team" do
    t = create_team
    u = create_user
    create_team_user user: u, team: t, role: 'admin'
    authenticate_with_user(u)

    api_key_1 = create_api_key(team: t)
    api_key_2 = create_api_key(team: t)

    query = 'query read { team { api_keys { edges { node { dbid, title, description } } } } }'
    post :create, params: { query: query, team: t }
    assert_response :success
    edges = JSON.parse(@response.body)['data']['team']['api_keys']['edges']
    assert_equal [api_key_1.title, api_key_2.title].sort, edges.collect{ |e| e['node']['title'] }.sort
  end

  test "should get api key in a team by id" do
    t = create_team
    u = create_user
    create_team_user user: u, team: t, role: 'admin'
    authenticate_with_user(u)

    a = create_api_key(team: t)

    query = "query { team { api_key(dbid: #{a.id}) { dbid } } }"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    response = JSON.parse(@response.body).dig('data', 'team', 'api_key')
    assert_equal 1, response.size
    assert_equal a.id, response.dig('dbid')
  end

  test "should delete api key" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'admin'
    authenticate_with_user(u)

    a = create_api_key(team: t)
    query = 'mutation destroy { destroyApiKey(input: { id: "' + a.id.to_s + '" }) { deletedId } }'
    post :create, params: { query: query }
    assert_response :success
    response = JSON.parse(@response.body).dig('data', 'destroyApiKey')
    assert_equal a.id.to_s, response.dig('deletedId')
  end

  test "should log all graphql activity" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'admin'
    authenticate_with_user(u)

    query = 'query me { me { name } }'

    expected_message = "[Graphql] Logging activity: uid: #{u.id} user_name: #{u.name} team: #{t.name} role: admin"
    mock_logger = mock()
    mock_logger.expects(:info).with(expected_message)

    Rails.stubs(:logger).returns(mock_logger)
    post :create, params: { query: query }
  end

  test "should send report when bulk-accepting suggestion" do
    Sidekiq::Testing.fake!
    WebMock.stub_request(:get, /#{CheckConfig.get('narcissus_url')}/).to_return(body: '{"url":"http://screenshot/test/test.png"}')
    create_verification_status_stuff
    pm1 = create_project_media team: @t ; s = pm1.last_status_obj ; s.status = 'false' ; s.save!
    publish_report(pm1)
    pm2 = create_project_media team: @t ; s = pm2.last_status_obj ; s.status = 'undetermined' ; s.save!
    b1 = create_team_bot(name: 'Alegre', login: 'alegre')
    b2 = create_team_bot(name: 'Smooch', login: 'smooch', set_approved: true)
    b2.install_to!(@t)
    r = create_relationship source_id: pm1.id, target_id: pm2.id, relationship_type: Relationship.suggested_type, user: b1

    assert_equal 'false', pm1.reload.last_status
    assert_equal 'undetermined', pm2.reload.last_status

    authenticate_with_user(@u)
    query = 'mutation { updateRelationships(input: { clientMutationId: "1", ids: ' + [r.graphql_id].to_json + ', action: "accept", source_id: ' + pm1.id.to_s + ' }) { ids } }'
    Sidekiq::Testing.inline! do
      post :create, params: { query: query, team: @t.slug }
    end
    assert_response :success

    # Child item should inherit status from parent when suggestion is accepted
    assert_equal 'false', pm1.reload.last_status
    assert_equal 'false', pm2.reload.last_status
  end

  test "should return super-admin user as 'meedan' if user IS NOT a part of the team" do
    u1 = create_user name: 'Mei'
    u2 = create_user name: 'Satsuki', is_admin: true

    t1 = create_team
    t2 = create_team

    create_team_user user: u1, team: t1
    create_team_user user: u2, team: t2

    authenticate_with_user(u1)

    query1 = "query { user (id: #{ u1.id }) { name } }"
    post :create, params: { query: query1 }
    assert_response :success
    assert_equal false, u1.is_admin?
    assert_equal 'Mei', JSON.parse(@response.body)['data']['user']['name']

    query2 = "query { user (id: #{ u2.id }) { name } }"
    post :create, params: { query: query2 }
    assert_response :success
    assert_equal true, u2.is_admin?
    assert_equal CheckConfig.get('super_admin_name'), JSON.parse(@response.body)['data']['user']['name']
  end

  test "should return super-admin user themself if user IS a part of the team" do
    u1 = create_user name: 'Mei'
    u2 = create_user name: 'Satsuki', is_admin: true

    t = create_team

    create_team_user user: u1, team: t
    create_team_user user: u2, team: t

    authenticate_with_user(u1)

    query1 = "query { user (id: #{ u1.id }) { name } }"
    post :create, params: { query: query1 }
    assert_response :success
    assert_equal false, u1.is_admin?
    assert_equal 'Mei', JSON.parse(@response.body)['data']['user']['name']

    query2 = "query { user (id: #{ u2.id }) { name } }"
    post :create, params: { query: query2 }
    assert_response :success
    assert_equal true, u2.is_admin?
    assert_equal 'Satsuki', JSON.parse(@response.body)['data']['user']['name']
  end

  test "should return default profile image if super-admin user IS NOT a part of the team" do
    u1 = create_user
    u2 = create_user is_admin: true, profile_image: "#{CheckConfig.get('checkdesk_base_url')}/images/checklogo.png"

    t1 = create_team
    t2 = create_team

    create_team_user user: u1, team: t1
    create_team_user user: u2, team: t2

    authenticate_with_user(u1)

    query = "query { user (id: #{ u2.id }) { profile_image, source { image } } }"
    post :create, params: { query: query }
    assert_response :success
    assert_equal true, u2.is_admin?
    assert_equal "#{CheckConfig.get('checkdesk_base_url')}/images/user.png", JSON.parse(@response.body)['data']['user']['profile_image']
    assert_equal "#{CheckConfig.get('checkdesk_base_url')}/images/user.png", JSON.parse(@response.body)['data']['user']['source']['image']
  end

  test "should return custom profile image if super-admin user IS a part of the team" do
    u1 = create_user
    u2 = create_user is_admin: true, profile_image: "#{CheckConfig.get('checkdesk_base_url')}/images/checklogo.png"

    t = create_team

    create_team_user user: u1, team: t
    create_team_user user: u2, team: t

    authenticate_with_user(u1)

    query = "query { user (id: #{ u2.id }) { profile_image, source { image } } }"
    post :create, params: { query: query }
    assert_response :success
    assert_equal true, u2.is_admin?
    assert_equal "#{CheckConfig.get('checkdesk_base_url')}/images/checklogo.png", JSON.parse(@response.body)['data']['user']['profile_image']
    assert_equal "#{CheckConfig.get('checkdesk_base_url')}/images/checklogo.png", JSON.parse(@response.body)['data']['user']['source']['image']
  end

  test "should treat ' tag' and 'tag' as the same tag, and not try to create a new tag" do
    Sidekiq::Testing.inline!
    t = create_team
    a = ApiKey.create!
    b = create_bot_user api_key_id: a.id
    create_team_user team: t, user: b
    p = create_project team: t
    authenticate_with_token(a)

    query1 = ' mutation create {
              createProjectMedia(input: {
                project_id: ' + p.id.to_s + ',
                media_type: "Blank",
                channel: { main: 1 },
                set_tags: ["science"],
                set_status: "verified",
                set_claim_description: "Claim #1.",
                set_fact_check: {
                  title: "Title #1",
                  language: "en",
                }
              }) {
                project_media {
                  full_url,
                  tags {
                    edges {
                      node {
                        tag_text
                      }
                    }
                  }
                }
              }
            } '

    post :create, params: { query: query1, team: t.slug }
    assert_response :success
    assert_equal 'science', JSON.parse(@response.body)['data']['createProjectMedia']['project_media']['tags']['edges'][0]['node']['tag_text']
    sleep 1

    query2 = ' mutation create {
      createProjectMedia(input: {
        project_id: ' + p.id.to_s + ',
        media_type: "Blank",
        channel: { main: 1 },
        set_tags: ["science "],
        set_status: "verified",
        set_claim_description: "Claim #2.",
        set_fact_check: {
          title: "Title #2",
          language: "en",
        }
      }) {
        project_media {
          full_url,
          tags {
            edges {
              node {
                tag_text
              }
            }
          }
        }
      }
    } '

    post :create, params: { query: query2, team: t.slug }
    assert_response :success
    assert_equal 'science', JSON.parse(@response.body)['data']['createProjectMedia']['project_media']['tags']['edges'][0]['node']['tag_text']
  end

  test "should not create duplicate tags for the ProjectMedia and FactCheck" do
    Sidekiq::Testing.inline!
    t = create_team
    a = ApiKey.create!
    b = create_bot_user api_key_id: a.id
    create_team_user team: t, user: b
    p = create_project team: t
    authenticate_with_token(a)

    query1 = ' mutation create {
              createProjectMedia(input: {
                project_id: ' + p.id.to_s + ',
                media_type: "Blank",
                channel: { main: 1 },
                set_tags: ["science", "science", "#science"],
                set_status: "verified",
                set_claim_description: "Claim #1.",
                set_fact_check: {
                  title: "Title #1",
                  language: "en",
                }
              }) {
                project_media {
                full_url
                  claim_description {
                    fact_check {
                      tags
                    }
                  }
                  tags {
                    edges {
                      node {
                        tag_text
                      }
                    }
                  }
                }
              }
            } '

    post :create, params: { query: query1, team: t.slug }
    assert_response :success

    pm = JSON.parse(@response.body)['data']['createProjectMedia']['project_media']
    pm_tags = pm['tags']['edges']
    fc_tags = pm['claim_description']['fact_check']['tags']

    assert_equal 1, pm_tags.count
    assert_equal 1, fc_tags.count
  end

  test "should append FactCheck to ProjectMedia, if ProjectMedia already exists and does not have a FactCheck" do
    Sidekiq::Testing.fake!
    url = 'http://example.com'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response_body = '{"type":"media","data":{"url":"' + url + '","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response_body)

    t = create_team
    p = create_project team: t
    pm = create_project_media team: t, set_original_claim: url

    assert_not_nil pm

    a = ApiKey.create!
    b = create_bot_user api_key_id: a.id
    create_team_user team: t, user: b
    authenticate_with_token(a)

    query = <<~GRAPHQL
      mutation {
        createProjectMedia(input: {
          project_id: #{p.id},
          media_type: "Blank",
          channel: { main: 1 },
          set_tags: ["tag"],
          set_status: "verified",
          set_claim_description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
          set_original_claim: "#{url}",
          set_fact_check: {
            title: "Title #1",
            language: "en",
          }
        }) {
          project_media {
          dbid
          full_url
            claim_description {
              fact_check {
                dbid
              }
            }
          }
        }
      }
    GRAPHQL

    assert_no_difference 'ProjectMedia.count' do
      assert_difference 'FactCheck.count' do
        post :create, params: { query: query, team: t.slug }
        assert_response :success
      end
    end

    response_pm = JSON.parse(@response.body)['data']['createProjectMedia']['project_media']
    fact_check = response_pm['claim_description']['fact_check']

    assert_not_nil fact_check
    assert_equal response_pm['dbid'], pm.id
  end

  test "should create a FactCheck with a Blank ProjectMedia, if ProjectMedia already exists and has a FactCheck in a different language" do
    Sidekiq::Testing.fake!
    url = 'http://example.com'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response_body = '{"type":"media","data":{"url":"' + url + '","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response_body)

    t = create_team
    t.settings[:languages] << 'pt'
    t.save!
    p = create_project team: t
    pm = create_project_media team: t, set_original_claim: url
    c = create_claim_description project_media: pm
    fc_1 = create_fact_check claim_description: c

    assert_not_nil fc_1

    a = ApiKey.create!
    b = create_bot_user api_key_id: a.id
    create_team_user team: t, user: b
    authenticate_with_token(a)

    query = <<~GRAPHQL
      mutation {
        createProjectMedia(input: {
          project_id: #{p.id},
          media_type: "Blank",
          channel: { main: 1 },
          set_tags: ["tag"],
          set_status: "verified",
          set_claim_description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
          set_original_claim: "#{url}",
          set_fact_check: {
            title: "Title #1",
            language: "pt",
          }
        }) {
          project_media {
          dbid
          full_url
            claim_description {
              fact_check {
                dbid
              }
            }
          }
        }
      }
    GRAPHQL

    assert_difference 'ProjectMedia.count' do
      assert_difference 'FactCheck.count' do
        post :create, params: { query: query, team: t.slug }
        assert_response :success
      end
    end

    response_pm = JSON.parse(@response.body)['data']['createProjectMedia']['project_media']
    fc_2 = response_pm['claim_description']['fact_check']

    assert_not_nil fc_2
    assert_not_equal response_pm['dbid'], pm.id
  end

  test 'should raise exception but not create item when trying to create imported item with fact-check in the same language and existing original media URL' do
    create_metadata_stuff
    Sidekiq::Testing.fake!

    url = 'http://example.com'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response_body = '{"type":"media","data":{"url":"' + url + '","type":"item","title":"Test"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response_body)

    t = create_team
    pm = create_project_media team: t, set_original_claim: url
    cd = create_claim_description project_media: pm
    fc = create_fact_check claim_description: cd

    a = ApiKey.create!
    b = create_bot_user api_key_id: a.id
    create_team_user team: t, user: b
    authenticate_with_token(a)

    query = <<~GRAPHQL
      mutation {
        createProjectMedia(input: {
          media_type: "Blank",
          set_status: "undetermined",
          set_claim_description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
          set_original_claim: "#{url}",
          set_fact_check: {
            title: "Fact Check Title",
            summary: "Fact Check Summary",
            language: "#{fc.language}",
            publish_report: false
          }
        }) {
          project_media {
            title
          }
        }
      }
    GRAPHQL

    assert_nothing_raised do
      post :create, params: { query: query, team: t.slug }
    end
    assert_response 400
    assert_equal 'This item already exists', JSON.parse(@response.body).dig('errors', 0, 'message')
  end
end
