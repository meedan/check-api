require_relative '../test_helper'

class GraphqlController11Test < ActionController::TestCase
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

  test "should create media with various types using set_original_claim" do
    authenticate_with_user(@u)

    # Test for creating media with plain text original claim
    query_plain_text = <<~GRAPHQL
      mutation {
        createProjectMedia(input: { set_original_claim: "This is an original claim" }) {
          project_media {
            id
          }
        }
      }
    GRAPHQL

    post :create, params: { query: query_plain_text, team: @t.slug }
    assert_response :success
    data = JSON.parse(response.body)['data']['createProjectMedia']
    assert_not_nil data['project_media']['id']

    # Prepare mock responses for URLs
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url_types = {
      audio: 'http://example.com/audio.mp3',
      image: 'http://example.com/image.png',
      video: 'http://example.com/video.mp4',
      generic: 'http://example.com'
    }

    url_types.each do |type, url|
      response_body = '{"type":"media","data":{"url":"' + url + '","type":"item"}}'
      WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response_body)
    end

    # Test for creating media with audio URL original claim
    query_audio = <<~GRAPHQL
      mutation {
        createProjectMedia(input: { set_original_claim: "#{url_types[:audio]}" }) {
          project_media {
            id
          }
        }
      }
    GRAPHQL

    post :create, params: { query: query_audio, team: @t.slug }
    assert_response :success
    data = JSON.parse(response.body)['data']['createProjectMedia']
    assert_not_nil data['project_media']['id']

    # Test for creating media with image URL original claim
    query_image = <<~GRAPHQL
      mutation {
        createProjectMedia(input: { set_original_claim: "#{url_types[:image]}" }) {
          project_media {
            id
          }
        }
      }
    GRAPHQL

    post :create, params: { query: query_image, team: @t.slug }
    assert_response :success
    data = JSON.parse(response.body)['data']['createProjectMedia']
    assert_not_nil data['project_media']['id']

    # Test for creating media with video URL original claim
    query_video = <<~GRAPHQL
      mutation {
        createProjectMedia(input: { set_original_claim: "#{url_types[:video]}" }) {
          project_media {
            id
          }
        }
      }
    GRAPHQL

    post :create, params: { query: query_video, team: @t.slug }
    assert_response :success
    data = JSON.parse(response.body)['data']['createProjectMedia']
    assert_not_nil data['project_media']['id']

    # Test for creating media with generic URL original claim
    query_generic = <<~GRAPHQL
      mutation {
        createProjectMedia(input: { set_original_claim: "#{url_types[:generic]}" }) {
          project_media {
            id
          }
        }
      }
    GRAPHQL

    post :create, params: { query: query_generic, team: @t.slug }
    assert_response :success
    data = JSON.parse(response.body)['data']['createProjectMedia']
    assert_not_nil data['project_media']['id']
  end

  test "admin users should be able to see all workspaces as accessible teams" do
    Team.destroy_all

    user = create_user
    team1 = create_team
    create_team_user user: user, team: team1

    admin = create_user(is_admin: true)
    team2 = create_team
    create_team_user user: admin, team: team2

    authenticate_with_user(admin)
    query = "query { me { accessible_teams_count, accessible_teams { edges { node { dbid } } } } }"
    post :create, params: { query: query }
    assert_response :success
    response = JSON.parse(@response.body)['data']['me']
    data = response['accessible_teams']['edges'].collect{ |edge| edge['node']['dbid'] }.sort
    assert_equal 2, data.size
    assert_equal team1.id, data[0]
    assert_equal team2.id, data[1]
    assert_equal 2, response['accessible_teams_count']
  end

  test "non-admin users should only be able to see workspaces they belong to as accessible teams" do
    Team.destroy_all
    user = create_user
    team1 = create_team
    create_team_user user: user, team: team1

    user2 = create_user
    team2 = create_team
    create_team_user user: user2, team: team2

    authenticate_with_user(user)
    query = "query { me { accessible_teams_count, accessible_teams { edges { node { dbid } } } } }"
    post :create, params: { query: query }
    assert_response :success
    response = JSON.parse(@response.body)['data']['me']
    data = response['accessible_teams']['edges']
    assert_equal 1, data.size
    assert_equal team1.id, data[0]['node']['dbid']
    assert_equal 1, response['accessible_teams_count']
  end

  test "should export list if it's a workspace admin and number of results is not over the limit" do
    Sidekiq::Testing.inline!
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'admin'
    authenticate_with_user(u)

    query = "mutation { exportList(input: { query: \"{}\", type: \"media\" }) { success } }"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert JSON.parse(@response.body)['data']['exportList']['success']
  end

  test "should not export list if it's not a workspace admin" do
    Sidekiq::Testing.inline!
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'editor'
    authenticate_with_user(u)

    query = "mutation { exportList(input: { query: \"{}\", type: \"media\" }) { success } }"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert !JSON.parse(@response.body)['data']['exportList']['success']
  end

  test "should not export list if it's over the limit" do
    Sidekiq::Testing.inline!
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'admin'
    authenticate_with_user(u)

    stub_configs({ 'export_csv_maximum_number_of_results' => -1 }) do 
      query = "mutation { exportList(input: { query: \"{}\", type: \"media\" }) { success } }"
      post :create, params: { query: query, team: t.slug }
      assert_response :success
      assert !JSON.parse(@response.body)['data']['exportList']['success']
    end
  end

  test "should get team statistics" do
    user = create_user
    team = create_team
    create_team_user user: user, team: team, role: 'admin'

    authenticate_with_user(user)
    query = <<~GRAPHQL
      query {
        team(slug: "#{team.slug}") {
          statistics(period: "past_week", platform: "whatsapp", language: "en") {
            number_of_articles_created_by_date
            number_of_articles_updated_by_date
            number_of_explainers_created
            number_of_fact_checks_created
            number_of_published_fact_checks
            number_of_fact_checks_by_rating
            top_articles_sent
            top_articles_tags
            number_of_messages
            number_of_conversations
            number_of_messages_by_date
            number_of_conversations_by_date
            number_of_search_results_by_feedback_type
            average_response_time
            number_of_unique_users
            number_of_total_users
            number_of_returning_users
            number_of_subscribers
            number_of_new_subscribers
            number_of_newsletters_sent
            number_of_newsletters_delivered
            top_media_tags
            top_requested_media_clusters
            number_of_media_received_by_media_type
            number_of_articles_sent
            number_of_matched_results_by_article_type
          }
        }
      }
    GRAPHQL

    post :create, params: { query: query }
    assert_response :success
  end

  test "should not get requests if interval is more than one month" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'editor'
    2.times { create_tipline_request team_id: t.id }
    create_tipline_request
    authenticate_with_user(u)

    query = <<~GRAPHQL
      query {
        team(slug: "#{t.slug}") {
          tipline_requests(from_timestamp: 1724266372, to_timestamp: 1729536732) {
            edges {
              node {
                id
              }
            }
          }
        }
      }
    GRAPHQL

    post :create, params: { query: query, team: t.slug }
    assert_response 400
    assert_equal 'Maximum interval is one month.', JSON.parse(@response.body)['errors'][0]['message']
  end

  test "should get requests" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'editor'
    2.times { create_tipline_request team_id: t.id }
    create_tipline_request
    authenticate_with_user(u)

    from = Time.now.beginning_of_month.to_i
    to = Time.now.end_of_month.to_i
    query = <<~GRAPHQL
      query {
        team(slug: "#{t.slug}") {
          tipline_requests(from_timestamp: #{from}, to_timestamp: #{to}) {
            edges {
              node {
                id
              }
            }
          }
        }
      }
    GRAPHQL

    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal 2, JSON.parse(@response.body).dig('data', 'team', 'tipline_requests', 'edges').size
  end

  test "super admin user should receive 3 matching fact-checks or explainers based on search text and arguments sent to bot query" do
    t = create_team
    # Create a super admin user
    super_admin = create_user(is_admin: true)
    create_team_user team: t, user: super_admin, role: 'admin'

    # Authenticate with super admin user
    authenticate_with_user(super_admin)

    # Create ProjectMedia instances
    pm1 = create_project_media quote: 'Foo Bar', team: t
    pm2 = create_project_media quote: 'Foo Bar Test', team: t
    pm3 = create_project_media quote: 'Foo Bar Test Testing', team: t

    # Create Explainers and attach them to PMs
    ex1 = create_explainer language: 'en', team: t, title: 'Foo Bar'
    ex2 = create_explainer language: 'en', team: t, title: 'Foo Bar Test'
    ex3 = create_explainer language: 'en', team: t, title: 'Foo Bar Test Testing'
    ex4 = create_explainer language: 'en', team: t, title: 'Explainer Test Testing'
    ex5 = create_explainer language: 'en', team: t, title: 'Explainer 5 Test Testing'
    ex6 = create_explainer language: 'en', team: t, title: 'Explainer 6 Test Testing'
    pm1.explainers << ex1
    pm2.explainers << ex2
    pm3.explainers << ex3
    pm3.explainers << ex4
    pm3.explainers << ex5
    pm3.explainers << ex6

    # Perform the GraphQL query with searchText "Foo"
    query = <<~GRAPHQL
      query {
        team(slug: "#{t.slug}") {
          bot_query(searchText: "Foo", threshold: 0.75, maxNumberOfWords: 2, enableLanguageDetection: false, shouldRestrictByLanguage: true, enableLinkShortening: true, utmCode: "test") {
            title
            type
          }
        }
      }
    GRAPHQL

    post :create, params: { query: query, team: t.slug }
    assert_response :success

    data = JSON.parse(@response.body)['data']['team']['bot_query']
    assert_equal 3, data.size, "Expected 3 matching results"

    expected_titles = [ex1.title, ex2.title, ex3.title]
    actual_titles = data.map { |result| result['title'] }
    assert_equal expected_titles.sort, actual_titles.sort, "Results should match the search query"
  end

  test "should get media cluster origin fields for an item" do
    Sidekiq::Testing.fake!
    Relationship.delete_all

    u = create_user is_admin: true
    t = create_team
    pm1 = create_project_media team: t, user: u
    pm2 = create_project_media team: t
    r = create_relationship source: pm1, target: pm2, user: u

    authenticate_with_user(u)
    query = "query { project_media(ids: \"#{pm1.id},#{t.id}\") { media_cluster_relationship { dbid, user_id, confirmed_at, weight, source_field, target_field, model, user { name }, confirmed_by { name } }, media_cluster_origin, media_cluster_origin_user { dbid }, media_cluster_origin_timestamp } }"
    post :create, params: { query: query }
    assert_response :success

    response = JSON.parse(@response.body)['data']['project_media']
    assert_equal r.id, response['media_cluster_relationship']['dbid']
    assert_equal u.id, response['media_cluster_origin_user']['dbid']
    assert_equal pm1.created_at.to_i, response['media_cluster_origin_timestamp']
    assert_equal CheckMediaClusterOrigins::OriginCodes::USER_ADDED, response['media_cluster_origin']
  end

  test "should not crash if workspace doesn't exist" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    authenticate_with_user(u)
    t.delete

    query = <<~GRAPHQL
      query {
        team(slug: "#{t.slug}", random: "123456") {
          name
        }
      }
    GRAPHQL

    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_match /ActiveRecord::RecordNotFound/, @response.body
  end

  test "should query tipline requests that never received articles and send explainers" do
    Bot::Smooch.stubs(:send_message_to_user)
    u = create_user is_admin: true
    t = create_team
    create_team_user team: t, user: u, role: 'admin'
    pm = create_project_media team: t
    tr_1a = create_tipline_request team_id: t.id, associated: pm
    Time.stubs(:now).returns(Time.new - 7.days)
    tr_7a = create_tipline_request team_id: t.id, associated: pm
    Time.unstub(:now)
    authenticate_with_user(u)
    query = "query { project_media(ids: \"#{pm.id}\") { has_tipline_requests_that_never_received_articles, number_of_tipline_requests_that_never_received_articles_by_time } }"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    data = JSON.parse(@response.body)['data']['project_media']
    assert data['has_tipline_requests_that_never_received_articles']
    expected_result = { 1 => 1, 7 => 1, 30 => 2 }.to_json
    assert_equal expected_result, data['number_of_tipline_requests_that_never_received_articles_by_time'].to_json
    # Verify send explainers mutation
    ex = create_explainer team: t
    pm.explainers << ex
    ex_item = pm.explainer_items.last
    Sidekiq::Testing.inline! do
      query = "mutation sendExplainersToPreviousRequests { sendExplainersToPreviousRequests(input: { clientMutationId: \"1\", dbid: #{ex_item.id}, range: 7 }) { success } }"
      post :create, params: { query: query, team: t.slug }
      assert_response :success
      assert JSON.parse(@response.body)['data']['sendExplainersToPreviousRequests']['success']
    end
    # Test failing mutation
    Sidekiq::Testing.inline! do
      query = "mutation sendExplainersToPreviousRequests { sendExplainersToPreviousRequests(input: { clientMutationId: \"1\", dbid: 0, range: 7 }) { success } }"
      post :create, params: { query: query, team: t.slug }
      assert_response :success
      assert !JSON.parse(@response.body)['data']['sendExplainersToPreviousRequests']['success']
    end
  end
end
