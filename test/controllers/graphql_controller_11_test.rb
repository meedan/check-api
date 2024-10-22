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
    p = create_project team: @t
    authenticate_with_user(@u)

    # Test for creating media with plain text original claim
    query_plain_text = <<~GRAPHQL
      mutation {
        createProjectMedia(input: { project_id: #{p.id}, set_original_claim: "This is an original claim" }) {
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
        createProjectMedia(input: { project_id: #{p.id}, set_original_claim: "#{url_types[:audio]}" }) {
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
        createProjectMedia(input: { project_id: #{p.id}, set_original_claim: "#{url_types[:image]}" }) {
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
        createProjectMedia(input: { project_id: #{p.id}, set_original_claim: "#{url_types[:video]}" }) {
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
        createProjectMedia(input: { project_id: #{p.id}, set_original_claim: "#{url_types[:generic]}" }) {
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
end
