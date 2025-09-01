require_relative '../test_helper'

class GraphqlController8Test < ActionController::TestCase
  def setup
    require 'sidekiq/testing'
    super
    TestDynamicAnnotationTables.load!
    @controller = Api::V1::GraphqlController.new

    RequestStore.store[:skip_cached_field_update] = false
    User.current = nil
    Team.current = nil
  end

  test "should create and retrieve clips" do
    admin_user = create_user is_admin: true
    t = create_team
    pm = create_project_media team: t
    authenticate_with_user(admin_user)

    query = 'mutation { createDynamic(input: { annotation_type: "clip", annotated_type: "ProjectMedia", annotated_id: "' + pm.id.to_s + '", fragment: "t=10,20", set_fields: "{\"label\":\"Clip Label\"}" }) { dynamic { data, parsed_fragment } } }'
    assert_difference 'Annotation.where(annotation_type: "clip").count', 1 do
      post :create, params: { query: query, team: pm.team.slug }
    end
    assert_response :success
    annotation = JSON.parse(@response.body)['data']['createDynamic']['dynamic']
    assert_equal 'Clip Label', annotation['data']['label']
    assert_equal({ 't' => [10, 20] }, annotation['parsed_fragment'])

    query = %{
      query {
        project_media(ids: "#{pm.id}") {
          clips: annotations(first: 10000, annotation_type: "clip") {
            edges {
              node {
                ... on Dynamic {
                  id
                  data
                  parsed_fragment
                }
              }
            }
          }
        }
      }
    }
    post :create, params: { query: query, team: pm.team.slug }
    assert_response :success
    clips = JSON.parse(@response.body)['data']['project_media']['clips']['edges']
    assert_equal 1, clips.size
    assert_equal 'Clip Label', clips[0]['node']['data']['label']
    assert_equal({ 't' => [10, 20] }, clips[0]['node']['parsed_fragment'])
  end

  test "should get team user from user" do
    u = create_user
    u2 = create_user
    t = create_team
    t2 = create_team
    tu = create_team_user user: u, team: t
    tu2 = create_team_user user: u2, team: t2
    authenticate_with_user(u)

    query = 'query { me { team_users(first: 1) { edges { node { id } } }, team_user(team_slug: "' + t.slug + '") { dbid, invited_by { dbid } } } }'
    post :create, params: { query: query }
    assert_response :success
    assert_equal tu.id, JSON.parse(@response.body)['data']['me']['team_user']['dbid']

    query = 'query { me { team_user(team_slug: "' + random_string + '") { dbid } } }'
    post :create, params: { query: query }
    assert_response :success
    assert_nil JSON.parse(@response.body)['data']['me']['team_user']
  end

    test "should define team languages settings" do
    admin_user = create_user is_admin: true
    authenticate_with_user(admin_user)
    t = create_team
    t.set_language nil
    t.set_languages nil
    t.save!

    assert_nil t.reload.get_language
    assert_nil t.reload.get_languages

    query = 'mutation { updateTeam(input: { clientMutationId: "1", id: "' + t.graphql_id + '", language: "port" }) { team { id } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response 400

    query = 'mutation { updateTeam(input: { clientMutationId: "1", id: "' + t.graphql_id + '", languages: "[\"port\"]" }) { team { id } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response 400

    assert_nil t.reload.get_language
    assert_nil t.reload.get_languages

    query = 'mutation { updateTeam(input: { clientMutationId: "1", id: "' + t.graphql_id + '", language: "pt_BR", languages: "[\"es\", \"pt\", \"bho\"]" }) { team { id } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success

    assert_equal 'pt_BR', t.reload.get_language
    assert_equal ['es', 'pt', 'bho'], t.reload.get_languages
  end

  test "should define team custom statuses" do
    admin_user = create_user is_admin: true
    authenticate_with_user(admin_user)
    t = create_team

    custom_statuses = {
      label: 'Field label',
      active: '2',
      default: '1',
      statuses: [
        { id: '1', locales: { en: { label: 'Custom Status 1', description: 'The meaning of this status' } }, style: { color: 'red' } },
        { id: '2', locales: { en: { label: 'Custom Status 2', description: 'The meaning of that status' } }, style: { color: 'blue' } }
      ]
    }

    query = 'mutation { updateTeam(input: { clientMutationId: "1", id: "' + t.graphql_id + '", language: "pt_BR", media_verification_statuses: ' + custom_statuses.to_json.to_json + ' }) { team { id, verification_statuses_with_counters: verification_statuses(items_count_for_status: "1", published_reports_count_for_status: "1"), verification_statuses } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    data = JSON.parse(@response.body).dig('data', 'updateTeam', 'team')
    assert_match /items_count/, data['verification_statuses_with_counters'].to_json
    assert_no_match /items_count:0/, data['verification_statuses'].to_json
  end

  test "should get nested tag" do
    admin_user = create_user is_admin: true
    t = create_team
    pm = create_project_media team: t
    tag1 = create_tag annotated: pm, tag: 'Parent'
    tag2 = create_tag annotated: tag1, tag: 'Child'
    authenticate_with_user(admin_user)
    query = %{
      query {
        project_media(ids: "#{pm.id}") {
          tags: annotations(first: 10000, annotation_type: "tag") {
            edges {
              node {
                ... on Tag {
                  id
                  tag_text
                  tags: annotations(first: 10000, annotation_type: "tag") {
                    edges {
                      node {
                        ... on Tag {
                          id
                          tag_text
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    tags = JSON.parse(@response.body)['data']['project_media']['tags']['edges']
    assert_equal 1, tags.size
    assert_equal 'Parent', tags[0]['node']['tag_text']
    child_tags = tags[0]['node']['tags']['edges']
    assert_equal 1, child_tags.size
    assert_equal 'Child', child_tags[0]['node']['tag_text']
  end

  test "should create report with image" do
    admin_user = create_user is_admin: true
    pm = create_project_media
    authenticate_with_user(admin_user)
    path = File.join(Rails.root, 'test', 'data', 'rails.png')
    file = Rack::Test::UploadedFile.new(path, 'image/png')

    query = 'mutation create { createDynamic(input: { annotation_type: "report_design", action: "save", clientMutationId: "1", annotated_type: "ProjectMedia", annotated_id: "' + pm.id.to_s + '", set_fields: "{\"options\":{\"language\":\"en\"}}" }) { dynamic { dbid } } }'
    post :create, params: { query: query, file: [file] }
    assert_response :success
    assert JSON.parse(@response.body).dig('errors').blank?

    d = Dynamic.find(JSON.parse(@response.body).dig('data','createDynamic','dynamic','dbid')).data.with_indifferent_access
    assert_match /rails\.png/, d[:options]['image']
  end

  test "should get feed" do
    u = create_user
    authenticate_with_user(u)

    t = create_team private: true
    create_team_user(user: u, team: t)
    f = create_feed
    query = "query { team(slug: \"#{t.slug}\") { feed(dbid: #{f.id}) { current_feed_team { dbid, requests_filters } } } }"

    post :create, params: { query: query, team: t.slug }
    assert_nil JSON.parse(@response.body).dig('data', 'team', 'feed')

    with_current_user_and_team(nil, nil) { f.teams << t }
    post :create, params: { query: query, team: t.slug }
    assert_equal FeedTeam.where(feed: f, team: t).last.id, JSON.parse(@response.body).dig('data', 'team', 'feed', 'current_feed_team', 'dbid')
  end

  test "should get feed saved search" do
    t = create_team
    u = create_user
    create_team_user user: u, team: t, role: 'admin'
    media_saved_search = create_saved_search team: t, filters: { foo: 'bar' }, list_type: 'media'
    article_saved_search = create_saved_search team: t, filters: { foo: 'bar' }, list_type: 'article'
    f = create_feed media_saved_search: media_saved_search, article_saved_search:article_saved_search, team: t
    authenticate_with_user(u)
    query = <<~GRAPHQL
      query {
        team(slug: "#{t.slug}") {
          feed(dbid: #{f.id}) {
            media_saved_search_id,
            media_saved_search { dbid },
            article_saved_search_id,
            article_saved_search { dbid }
            }
          }
        }
    GRAPHQL

    post :create, params: { query: query, team: t.slug }
    assert_response :success
    data = JSON.parse(@response.body).dig('data', 'team', 'feed')

    assert_equal media_saved_search.id, data.dig('media_saved_search_id')
    assert_equal media_saved_search.id, data.dig('media_saved_search', 'dbid')
    assert_equal article_saved_search.id, data.dig('article_saved_search_id')
    assert_equal article_saved_search.id, data.dig('article_saved_search', 'dbid')
  end

  test "should get feed team saved search" do
    t = create_team
    u = create_user
    create_team_user user: u, team: t, role: 'admin'
    media_saved_search = create_saved_search team: t, filters: { foo: 'bar' }, list_type: 'media'
    article_saved_search = create_saved_search team: t, filters: { foo: 'bar' }, list_type: 'article'
    f = create_feed
    create_feed_team media_saved_search: media_saved_search, article_saved_search:article_saved_search, team_id: t.id, feed: f

    query = <<~GRAPHQL
      query {
        team(slug: "#{t.slug}") {
          feed(dbid: #{f.id}) {
            current_feed_team {
              dbid,
              media_saved_search_id,
              media_saved_search { dbid },
              article_saved_search_id,
              article_saved_search { dbid }
              }
            }
          }
        }
    GRAPHQL

    post :create, params: { query: query, team: t.slug }
    assert_response :success
    data = JSON.parse(@response.body).dig('data', 'team', 'feed', 'current_feed_team')

    assert_equal media_saved_search.id, data.dig('media_saved_search_id')
    assert_equal media_saved_search.id, data.dig('media_saved_search', 'dbid')
    assert_equal article_saved_search.id, data.dig('article_saved_search_id')
    assert_equal article_saved_search.id, data.dig('article_saved_search', 'dbid')
  end

  test "should return shared feed main feed (owner's feed) saved searches in feed teams" do
    user = create_user
    authenticate_with_user(user)

    # shared feed owner, main feed
    team = create_team
    create_team_user user: user, team: team, role: 'admin'
    media_saved_search = create_saved_search team: team, filters: { foo: 'bar' }, list_type: 'media'
    article_saved_search = create_saved_search team: team, filters: { foo: 'bar' }, list_type: 'article'
    feed = create_feed media_saved_search: media_saved_search, article_saved_search: article_saved_search, team: team

    # shared feed guest, invited team feed
    team2 = create_team
    media_saved_search2 = create_saved_search team: team2, filters: { foo: 'bar' }, list_type: 'media'
    article_saved_search2 = create_saved_search team: team2, filters: { foo: 'bar' }, list_type: 'article'
    create_feed_team media_saved_search: media_saved_search2, article_saved_search: article_saved_search2, feed: feed, team: team2

    query = <<~GRAPHQL
      query {
        me {
          current_team {
            name
            dbid
            feed(dbid: #{feed.id}) {
              team_id
              media_saved_search {
                team_id
                dbid
              }
              article_saved_search {
                team_id
                dbid
              }
              feed_teams {
                edges {
                  node {
                    team_id
                    media_saved_search {
                      dbid
                    }
                    article_saved_search {
                      dbid
                    }
                  }
                }
              }
            }
          }
        }
      }
    GRAPHQL

    post :create, params: { query: query, team: team.slug }
    assert_response :success
    data = JSON.parse(@response.body)
    feed = data.dig('data', 'me', 'current_team', 'feed')
    feed_teams_node_owner = feed.dig('feed_teams', 'edges').first['node']
    feed_teams_node_guest = feed.dig('feed_teams', 'edges').last['node']

    assert_equal media_saved_search.id, feed.dig('media_saved_search', 'dbid')
    assert_equal article_saved_search.id, feed.dig('article_saved_search', 'dbid')
    assert_equal media_saved_search.id, feed_teams_node_owner.dig('media_saved_search', 'dbid')
    assert_equal article_saved_search.id, feed_teams_node_owner.dig('article_saved_search', 'dbid')
    assert_equal media_saved_search2.id, feed_teams_node_guest.dig('media_saved_search', 'dbid')
    assert_equal article_saved_search2.id, feed_teams_node_guest.dig('article_saved_search', 'dbid')
  end

  test "should create feed" do
    team = create_team
    user = create_user
    create_team_user user: user, team: team, role: 'admin'
    media_saved_search = create_saved_search team: team, filters: { foo: 'bar' }, list_type: 'media'
    article_saved_search = create_saved_search team: team, filters: { foo: 'bar' }, list_type: 'article'
    authenticate_with_user(user)

    assert_difference 'Feed.count' do
      tags = ['tag_a', 'tag_b'].to_json
      licenses = [1, 2].to_json
      query = <<~GRAPHQL
        mutation {
          createFeed(input: {
            clientMutationId: "1",
            tags: #{tags},
            licenses: #{licenses},
            media_saved_search_id: #{media_saved_search.id},
            article_saved_search_id: #{article_saved_search.id},
            name: "FeedTitle", description: "FeedDescription"
          }) {
            feed {
              name,
              description,
              published,
              filters,
              tags,
              licenses,
              team_id,
              media_saved_search_id,
              media_saved_search { dbid }
              article_saved_search_id,
              article_saved_search { dbid }
              team { dbid },
            }
          }
        }
      GRAPHQL

      post :create, params: { query: query, team: team.slug }
      assert_response :success
    end
  end

  test "should update feed" do
    user = create_user
    authenticate_with_user(user)

    team = create_team private: true
    create_team_user(user: user, team: team, role: 'admin')
    feed = create_feed team_id: team.id
    media_saved_search = create_saved_search team: team, list_type: 'media'
    article_saved_search = create_saved_search team: team, list_type: 'article'

    query = <<~GRAPHQL
      mutation {
        updateFeed(input: {
          id: "#{feed.graphql_id}",
          published: true,
          media_saved_search_id: #{media_saved_search.id}
          article_saved_search_id: #{article_saved_search.id}
        }) {
          feed {
            published,
            media_saved_search_id
            article_saved_search_id
          }
        }
      }
    GRAPHQL

    post :create, params: { query: query, team: team.slug }
    assert_response :success

    data = JSON.parse(@response.body).dig('data', 'updateFeed', 'feed')
    assert data['published']
    assert media_saved_search.id, data['media_saved_search_id']
    assert article_saved_search.id, data['article_saved_search_id']
  end

  test "should update feed team" do
    user = create_user
    authenticate_with_user(user)

    team1 = create_team private: true
    create_team_user(user: user, team: team1, role: 'admin')
    team2 = create_team private: true
    media_saved_search = create_saved_search team: team1, type: 'media'
    article_saved_search = create_saved_search team: team1, type: 'article'
    feed = create_feed
    feed.teams << team1
    feed.teams << team2
    feed_team1 = FeedTeam.where(team: team1, feed: feed).last
    feed_team2 = FeedTeam.where(team: team2, feed: feed).last
    assert !feed_team1.shared
    assert !feed_team2.shared

    query = <<~GRAPHQL
      mutation {
        updateFeedTeam(input: {
          id: "#{feed_team1.graphql_id}",
          shared: true,
          media_saved_search_id: #{media_saved_search.id}
          article_saved_search_id: #{article_saved_search.id}
        }) {
          feed_team {
            shared,
            media_saved_search { dbid }
            article_saved_search { dbid }
          }
        }
      }
    GRAPHQL
    post :create, params: { query: query, team: team1.slug }
    assert feed_team1.reload.shared
    assert_equal media_saved_search.id, feed_team1.reload.media_saved_search_id
    assert_equal article_saved_search.id, feed_team1.reload.article_saved_search_id

    query = <<~GRAPHQL
      mutation {
        updateFeedTeam(input: {
          id: "#{feed_team2.graphql_id}",
          shared: true,
        }) {
          feed_team {
            shared
          }
        }
      }
    GRAPHQL
    post :create, params: { query: query, team: team2.slug }
    assert !feed_team2.reload.shared
  end

  test "should mark item as read" do
    pm = create_project_media
    assert !pm.reload.read

    admin_user = create_user is_admin: true
    authenticate_with_user(admin_user)

    assert_difference 'ProjectMediaUser.count' do
      query = 'mutation { createProjectMediaUser(input: { clientMutationId: "1", project_media_id: ' + pm.id.to_s + ', read: true }) { project_media { is_read } } }'
      post :create, params: { query: query, team: pm.team.slug }
      assert_response :success
      assert pm.reload.read

      query = 'mutation { createProjectMediaUser(input: { clientMutationId: "1", project_media_id: ' + pm.id.to_s + ', read: true }) { project_media { is_read } } }'
      post :create, params: { query: query, team: pm.team.slug }
      assert_response 409
    end
  end

  test "should filter by user in PostgreSQL" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t
    pm = create_project_media team: t, user: u
    create_project_media team: t
    authenticate_with_user(u)

    query = 'query CheckSearch { search(query: "{\"users\":[' + u.id.to_s + ']}") { medias(first: 10) { edges { node { dbid } } } } }'
    post :create, params: { query: query, team: t.slug }

    assert_response :success
    assert_equal [pm.id], JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
  end

  test "should check permission before setting Slack channel URL" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'admin'
    d = create_dynamic_annotation annotated: t, annotation_type: 'smooch_user'
    u2 = create_user
    authenticate_with_user(u2)
    query = 'mutation { smoochBotAddSlackChannelUrl(input: { clientMutationId: "1", id: "' + d.id.to_s +
  '", set_fields: "{\"smooch_user_slack_channel_url\":\"' + random_url+ '\"}" }) { annotation { dbid } } }'
    post :create, params: { query: query }
    assert_response 400
  end

  test "should delete tag" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'admin'
    authenticate_with_user(u)
    pm = create_project_media team: t
    tg = create_tag annotated: pm
    id = Base64.encode64("Tag/#{tg.id}")
    query = 'mutation destroy { destroyTag(input: { clientMutationId: "1", id: "' + id + '" }) { deletedId } }'
    post :create, params: { query: query }
    assert_response :success
  end

  test "should create relationship" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'admin'
    authenticate_with_user(u)
    pm1 = create_project_media team: t
    pm2 = create_project_media team: t
    assert_difference 'Relationship.count' do
      query = 'mutation { createRelationship(input: { clientMutationId: "1", source_id: ' + pm1.id.to_s + ', target_id: ' + pm2.id.to_s + ', relationship_type: "{\"source\":\"full_video\",\"target\":\"clip\"}" }) { relationship { dbid } } }'
      post :create, params: { query: query }
    end
    assert_response :success
  end

  test "should get statuses from team" do
    admin_user = create_user is_admin: true
    t = create_team
    authenticate_with_user(admin_user)
    query = "query { team(slug: \"#{t.slug}\") { verification_statuses } }"
    post :create, params: { query: query }
    assert_response :success
    assert_not_nil JSON.parse(@response.body)['data']['team']['verification_statuses']
  end

  test "should get tags from media" do
    admin_user = create_user is_admin: true
    t = create_team
    pm = create_project_media team: t
    c = create_tag annotated: pm, fragment: 't=10,20'
    authenticate_with_user(admin_user)
    query = "query { project_media(ids: \"#{pm.id}\") { tags(first: 10) { edges { node { parsed_fragment } } } } }"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal({ 't' => [10, 20] }, JSON.parse(@response.body)['data']['project_media']['tags']['edges'][0]['node']['parsed_fragment'])
  end

  test "should get OCR" do
    b = create_alegre_bot(name: 'alegre', login: 'alegre')
    b.approve!
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      Sidekiq::Testing.fake! do
        WebMock.disable_net_connect! allow: /#{CheckConfig.get('elasticsearch_host')}|#{CheckConfig.get('storage_endpoint')}/
        WebMock.stub_request(:post, 'http://alegre/image/ocr/').with({ body: { url: "some/path" } }).to_return(body: { text: 'Foo bar' }.to_json)
        WebMock.stub_request(:post, 'http://alegre/text/similarity/')

        u = create_user
        t = create_team
        create_team_user user: u, team: t, role: 'admin'
        authenticate_with_user(u)

        Bot::Alegre.unstub(:media_file_url)
        pm = create_project_media team: t, media: create_uploaded_image
        Bot::Alegre.stubs(:media_file_url).with(pm).returns('some/path')

        query = 'mutation ocr { extractText(input: { clientMutationId: "1", id: "' + pm.graphql_id + '" }) { project_media { id } } }'
        post :create, params: { query: query, team: t.slug }
        assert_response :success

        extracted_text_annotation = pm.get_annotations('extracted_text').last
        assert_equal 'Foo bar', extracted_text_annotation.data['text']
        Bot::Alegre.unstub(:media_file_url)
      end
    end
  end

  test "should avoid n+1 queries problem" do
    n = 2 # Number of media items to be created
    m = 2 # Number of annotations per media
    u = create_user
    authenticate_with_user(u)
    t = create_team slug: 'team'
    create_team_user user: u, team: t
    with_current_user_and_team(u, t) do
      n.times do
        pm = create_project_media team: t, disable_es_callbacks: false
        m.times { create_tag annotated: pm, annotator: u, disable_es_callbacks: false }
      end
    end
    sleep 4

    query = "query { search(query: \"{}\") { medias(first: 10000) { edges { node { dbid, media { dbid } } } } } }"

    # This number should be always CONSTANT regardless the number of medias and annotations above
    assert_queries (19), '<=' do
      post :create, params: { query: query, team: 'team' }
    end

    assert_response :success
    assert_equal n, JSON.parse(@response.body)['data']['search']['medias']['edges'].size
  end

  test "should get CheckSearch information fast" do
    RequestStore.store[:skip_cached_field_update] = false
    n = 3 # Number of media items to be created
    m = 2 # Number of annotations per media (doesn't matter in this case because we use the cached count - using random values to make sure it remains consistent)
    u = create_user
    authenticate_with_user(u)
    t = create_team slug: 'team'
    create_team_task team_id: t.id
    create_tag_text team_id: t.id
    create_team_bot_installation team_id: t.id
    create_team_user user: u, team: t
    n.times do
      pm = create_project_media team: t, user: create_user, disable_es_callbacks: false
      s = create_source
      create_account_source source: s, disable_es_callbacks: false
      m.times { create_tag annotated: pm, annotator: create_user, disable_es_callbacks: false }
    end
    create_project_media team: t, user: u, disable_es_callbacks: false
    pm = create_project_media team: t, disable_es_callbacks: false
    pm.archived = CheckArchivedFlags::FlagCodes::TRASHED
    pm.save!
    sleep 10

    # Current search query used by the frontend
    query = %{query CheckSearch {
      search(query: "{}") {
        id
        number_of_results
        team {
          id
          dbid
          name
          slug
          verification_statuses
          dynamic_search_fields_json_schema
          rules_search_fields_json_schema
          medias_count
          permissions
          search_id
          team_tasks(first: 10000) {
            edges {
              node {
                id
                dbid
                fieldset
                label
                options
                type
              }
            }
          }
          tag_texts(first: 10000) {
            edges {
              node {
                text
              }
            }
          }
          users(first: 10000) {
            edges {
              node {
                id
                dbid
                name
              }
            }
          }
          check_search_trash {
            id
            number_of_results
          }
          check_search_unconfirmed {
            id
            number_of_results
          }
          public_team {
            id
            medias_count
            trash_count
            unconfirmed_count
            spam_count
          }
          search {
            id
            number_of_results
          }
          team_bot_installations(first: 10000) {
            edges {
              node {
                id
                team_bot: bot_user {
                  id
                  identifier
                }
              }
            }
          }
        }
        medias(first: 20) {
          edges {
            node {
              id
              dbid
              picture
              title
              description
              is_read
              team {
                verification_statuses
              }
            }
          }
        }
      }
    }}

    # Make sure we only run queries for the 20 first items
    assert_queries 100, '<=' do
      post :create, params: { query: query, team: 'team' }
    end

    assert_response :success
    assert_equal 4, JSON.parse(@response.body)['data']['search']['medias']['edges'].size
  end

  test "should delete custom status" do
    setup_elasticsearch
    RequestStore.store[:skip_cached_field_update] = false
    u = create_user
    authenticate_with_user(u)
    t = create_team slug: 'team'
    create_team_user user: u, team: t, role: 'admin'
    value = {
      label: 'Field label',
      active: 'id1',
      default: 'id1',
      statuses: [
        { id: 'id1', locales: { en: { label: 'Custom Status 1', description: 'The meaning of this status' } }, style: { color: 'red' } },
        { id: 'id2', locales: { en: { label: 'Custom Status 2', description: 'The meaning of that status' } }, style: { color: 'blue' } },
        { id: 'id3', locales: { en: { label: 'Custom Status 3', description: 'The meaning of that status' } }, style: { color: 'green' } }
      ]
    }
    t.set_media_verification_statuses(value)
    t.save!
    pm1 = create_project_media team: t
    s = pm1.annotations.where(annotation_type: 'verification_status').last.load
    s.status = 'id1'
    s.disable_es_callbacks = false
    s.save!
    r1 = publish_report(pm1)
    pm2 = create_project_media team: t
    s = pm2.annotations.where(annotation_type: 'verification_status').last.load
    s.status = 'id2'
    s.disable_es_callbacks = false
    s.save!
    r2 = publish_report(pm2)

    assert_equal 'id1', pm1.reload.last_status
    assert_equal 'id2', pm2.reload.last_status
    assert_queries(0, '=') do
      assert_equal 'id1', pm1.status
      assert_equal 'id2', pm2.status
    end
    assert_not_equal [], t.reload.get_media_verification_statuses[:statuses].select{ |s| s[:id] == 'id2' }
    sleep 2
    assert_equal [pm2.id], CheckSearch.new({ verification_status: ['id2'] }.to_json, nil, t.id).medias.map(&:id)
    assert_equal [], CheckSearch.new({ verification_status: ['id3'] }.to_json, nil, t.id).medias.map(&:id)
    assert_equal 'published', r1.reload.get_field_value('state')
    assert_equal 'published', r2.reload.get_field_value('state')
    assert_not_equal 'red', r1.reload.report_design_field_value('theme_color')
    assert_not_equal 'blue', r2.reload.report_design_field_value('theme_color')
    assert_not_equal 'Custom Status 1', r1.reload.report_design_field_value('status_label')
    assert_not_equal 'Custom Status 3', r2.reload.report_design_field_value('status_label')

    query = "mutation deleteTeamStatus { deleteTeamStatus(input: { clientMutationId: \"1\", team_id: \"#{t.graphql_id}\", status_id: \"id2\", fallback_status_id: \"id3\" }) { team { id, verification_statuses(items_count_for_status: \"id3\") } } }"
    post :create, params: { query: query, team: 'team' }
    assert_response :success

    assert_equal 'id1', pm1.reload.last_status
    assert_equal 'id3', pm2.reload.last_status
    assert_queries(0, '=') do
      assert_equal 'id1', pm1.status
      assert_equal 'id3', pm2.status
    end
    sleep 2
    assert_equal [], CheckSearch.new({ verification_status: ['id2'] }.to_json, nil, t.id).medias.map(&:id)
    assert_equal [pm2.id], CheckSearch.new({ verification_status: ['id3'] }.to_json, nil, t.id).medias.map(&:id)
    assert_equal [], t.reload.get_media_verification_statuses[:statuses].select{ |s| s[:id] == 'id2' }
    assert_equal 'published', r1.reload.get_field_value('state')
    assert_equal 'paused', r2.reload.get_field_value('state')
    assert_not_equal 'red', r1.reload.report_design_field_value('theme_color')
    assert_equal 'green', r2.reload.report_design_field_value('theme_color')
    assert_not_equal 'Custom Status 1', r1.reload.report_design_field_value('status_label')
    assert_equal 'Custom Status 3', r2.reload.report_design_field_value('status_label')
  end

  test "should not access GraphQL query if not authenticated" do
    post :create, params: { query: 'query Query { about { name, version } }' }
    assert_response 401
  end

  test "should not access About if not authenticated" do
    post :create, params: { query: 'query About { about { name, version } }' }
    assert_response 401
  end

  test "should access GraphQL if authenticated" do
    authenticate_with_user
    post :create, params: { query: 'query Query { about { name, version, upload_max_size, upload_extensions, upload_max_dimensions, upload_min_dimensions, terms_last_updated_at } }', variables: '{"foo":"bar"}' }
    assert_response :success
    data = JSON.parse(@response.body)['data']['about']
    assert_kind_of String, data['name']
    assert_kind_of String, data['version']
  end

  test "should not access GraphQL if authenticated as a bot" do
    authenticate_with_user(create_bot_user)
    post :create, params: { query: 'query Query { about { name, version, upload_max_size, upload_extensions, upload_max_dimensions, upload_min_dimensions } }', variables: '{"foo":"bar"}' }
    assert_response 401
  end

  test "should get node from global id" do
    authenticate_with_user
    id = Base64.encode64('About/1')
    post :create, params: { query: "query Query { node(id: \"#{id}\") { id } }" }
    assert_equal id, JSON.parse(@response.body)['data']['node']['id']
  end

  test "should get current user" do
    u = create_user name: 'Test User'
    authenticate_with_user(u)
    post :create, params: { query: 'query Query { me { get_send_email_notifications, get_send_successful_login_notifications, get_send_failed_login_notifications, annotations(first: 1) { edges { node { id } } }, source { dbid }, source_id, token, is_admin, name, bot { id } } }' }
    assert_response :success
    data = JSON.parse(@response.body)['data']['me']
    assert_equal 'Test User', data['name']
  end

  test "should return 404 if object does not exist" do
    authenticate_with_user
    post :create, params: { query: 'query GetById { project_media(ids: "99999,99999") { id } }' }
    assert_response :success
  end

  test "should set context team" do
    authenticate_with_user
    t = create_team slug: 'context'
    post :create, params: { query: 'query Query { about { name, version } }', team: 'context' }
    assert_equal t, assigns(:context_team)
  end

  test "should get team by context" do
    authenticate_with_user
    t = create_team slug: 'context', name: 'Context Team'
    post :create, params: { query: 'query Team { team { name } }', team: 'context' }
    assert_response :success
    assert_equal 'Context Team', JSON.parse(@response.body)['data']['team']['name']
  end

  test "should get public team by context" do
    authenticate_with_user
    t1 = create_team slug: 'team1', name: 'Team 1'
    t2 = create_team slug: 'team2', name: 'Team 2'
    post :create, params: { query: 'query PublicTeam { public_team { name } }', team: 'team1' }
    assert_response :success
    assert_equal 'Team 1', JSON.parse(@response.body)['data']['public_team']['name']
  end

  test "should get public team by slug" do
    authenticate_with_user
    t1 = create_team slug: 'team1', name: 'Team 1'
    t2 = create_team slug: 'team2', name: 'Team 2'
    post :create, params: { query: 'query PublicTeam { public_team(slug: "team2") { name } }', team: 'team1' }
    assert_response :success
    assert_equal 'Team 2', JSON.parse(@response.body)['data']['public_team']['name']
  end

  test "should not get team by context" do
    authenticate_with_user
    Team.delete_all
    post :create, params: { query: 'query Team { team { name } }', team: 'test' }
    assert_response :success
  end

  test "should update current team based on context team" do
    u = create_user

    t1 = create_team slug: 'team1'
    create_team_user user: u, team: t1
    t2 = create_team slug: 'team2'
    t3 = create_team slug: 'team3'
    create_team_user user: u, team: t3

    u.current_team_id = t1.id
    u.save!

    assert_equal t1, u.reload.current_team

    authenticate_with_user(u)

    post :create, params: { query: 'query Query { me { name } }', team: 'team1' }
    assert_response :success
    assert_equal t1, u.reload.current_team

    post :create, params: { query: 'query Query { me { name } }', team: 'team2' }
    assert_response :success
    assert_equal t1, u.reload.current_team

    post :create, params: { query: 'query Query { me { name } }', team: 'team3' }
    assert_response :success
    assert_equal t3, u.reload.current_team
  end

  test "should return 404 if public team does not exist" do
    authenticate_with_user
    Team.delete_all
    post :create, params: { query: 'query PublicTeam { public_team { name } }', team: 'foo' }
    assert_response :success
  end

  test "should return null if public team is not found" do
    authenticate_with_user
    Team.delete_all
    post :create, params: { query: 'query FindPublicTeam { find_public_team(slug: "foo") { name } }', team: 'foo' }
    assert_response :success
    assert_nil JSON.parse(@response.body)['data']['find_public_team']
  end

  test "should get team by slug" do
    authenticate_with_user
    t = create_team slug: 'context', name: 'Context Team'
    post :create, params: { query: 'query Team { team(slug: "context") { name } }' }
    assert_response :success
    assert_equal 'Context Team', JSON.parse(@response.body)['data']['team']['name']
  end

  test "should transcribe audio" do
    Sidekiq::Testing.inline! do
      t = create_team
      u = create_user
      tu = create_team_user user: u, team: t

      pm = create_project_media team: t, media: create_uploaded_audio(file: 'rails.mp3')
      url = Bot::Alegre.media_file_url(pm)
      s3_url = url.gsub(/^https?:\/\/[^\/]+/, "s3://#{CheckConfig.get('storage_bucket')}")

      Bot::Alegre.stubs(:request).returns({ success: true })
      Bot::Alegre.stubs(:request).with('post', '/audio/transcription/', { url: s3_url, job_name: '0c481e87f2774b1bd41a0a70d9b70d11' }).returns({ 'job_status' => 'IN_PROGRESS' })
      Bot::Alegre.stubs(:request).with('post', '/audio/transcription/result/', { job_name: '0c481e87f2774b1bd41a0a70d9b70d11' }).returns({ 'job_status' => 'COMPLETED', 'transcription' => 'Foo bar' })
      WebMock.stub_request(:post, 'http://alegre/text/langid/').to_return(body: { 'result' => { 'language' => 'es' }}.to_json)

      b = create_bot_user login: 'alegre', name: 'Alegre', approved: true
      b.install_to!(t)
      WebMock.stub_request(:get, Bot::Alegre.media_file_url(pm)).to_return(body: File.read(File.join(Rails.root, 'test', 'data', 'rails.mp3')))

      authenticate_with_user(u)

      query = 'mutation { transcribeAudio(input: { clientMutationId: "1", id: "' + pm.graphql_id + '" }) { project_media { id }, annotation { data } } }'
      post :create, params: { query: query, team: t.slug }
      assert_response :success
      assert_equal 'Foo bar', JSON.parse(@response.body)['data']['transcribeAudio']['annotation']['data']['text']

      Bot::Alegre.unstub(:request)
    end
  end

  test "should get dynamic annotation field" do
    name = random_string
    phone = random_string
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'editor'
    pm = create_project_media team: t
    d = create_dynamic_annotation annotated: pm, annotation_type: 'smooch_user', set_fields: { smooch_user_id: random_string, smooch_user_app_id: random_string, smooch_user_data: { phone: phone, app_name: name }.to_json }.to_json
    authenticate_with_token
    query = 'query { dynamic_annotation_field(query: "{\"field_name\": \"smooch_user_data\", \"json\": { \"phone\": \"' + phone + '\", \"app_name\": \"' + name + '\" } }") { annotation { dbid } } }'
    post :create, params: { query: query }
    assert_response :success
    assert_equal d.id.to_s, JSON.parse(@response.body)['data']['dynamic_annotation_field']['annotation']['dbid']
  end

  test "should not get dynamic annotation field if does not have permission" do
    name = random_string
    phone = random_string
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'editor'
    pm = create_project_media team: t
    d = create_dynamic_annotation annotated: pm, annotation_type: 'smooch_user', set_fields: { smooch_user_id: random_string, smooch_user_app_id: random_string, smooch_user_data: { phone: phone, app_name: name }.to_json }.to_json
    authenticate_with_user(u)
    query = 'query { dynamic_annotation_field(query: "{\"field_name\": \"smooch_user_data\", \"json\": { \"phone\": \"' + phone + '\", \"app_name\": \"' + name + '\" } }") { annotation { dbid } } }'
    post :create, params: { query: query }
    assert_response :success
    assert_nil JSON.parse(@response.body)['data']['dynamic_annotation_field']
  end

  test "should not get dynamic annotation field if parameters do not match" do
    name = random_string
    phone = random_string
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'editor'
    pm = create_project_media team: t
    d = create_dynamic_annotation annotated: pm, annotation_type: 'smooch_user', set_fields: { smooch_user_id: random_string, smooch_user_app_id: random_string, smooch_user_data: { phone: phone, app_name: name }.to_json }.to_json
    authenticate_with_user(u)
    query = 'query { dynamic_annotation_field(query: "{\"field_name\": \"smooch_user_data\", \"json\": { \"phone\": \"' + phone + '\", \"app_name\": \"' + random_string + '\" } }") { annotation { dbid } } }'
    post :create, params: { query: query }
    assert_response :success
    assert_nil JSON.parse(@response.body)['data']['dynamic_annotation_field']
  end

  test "should get team settings fields" do
    u = create_user is_admin: true
    authenticate_with_user(u)
    t = create_team set_report: { en: { use_introduction: true, introduction: 'Test' } }
    fields = %w(get_slack_notifications_enabled get_slack_webhook get_embed_whitelist get_report_design_image_template get_status_target_turnaround get_rules get_languages get_language get_report get_data_report_url get_outgoing_urls_utm_code get_shorten_outgoing_urls get_report)
    post :create, params: { query: "query Team { team { join_requests(first: 10) { edges { node { id } } }, #{fields.join(', ')} } }", team: t.slug }
    assert_response :success
  end
end
