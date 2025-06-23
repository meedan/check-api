require_relative '../test_helper'

class GraphqlController5Test < ActionController::TestCase
  def setup
    require 'sidekiq/testing'
    super
    TestDynamicAnnotationTables.load!
    @controller = Api::V1::GraphqlController.new

    User.current = nil
    Team.current = nil
    @t = create_team private: true
    @tt1 = create_team_task team_id: @t.id, fieldset: 'tasks' ; sleep 1
    @tt2 = create_team_task team_id: @t.id, fieldset: 'tasks' ; sleep 1
    @tt3 = create_team_task team_id: @t.id, fieldset: 'tasks' ; sleep 1
    @tm1 = create_team_task team_id: @t.id, fieldset: 'metadata' ; sleep 1
    @tm2 = create_team_task team_id: @t.id, fieldset: 'metadata' ; sleep 1
    @tm3 = create_team_task team_id: @t.id, fieldset: 'metadata' ; sleep 1
    TeamTask.update_all(order: nil)
    @pm = create_project_media team: @t
    Task.delete_all
    @t1 = create_task annotated: @pm, fieldset: 'tasks' ; sleep 1
    @t2 = create_task annotated: @pm, fieldset: 'tasks' ; sleep 1
    @t3 = create_task annotated: @pm, fieldset: 'tasks' ; sleep 1
    @m1 = create_task annotated: @pm, fieldset: 'metadata' ; sleep 1
    @m2 = create_task annotated: @pm, fieldset: 'metadata' ; sleep 1
    @m3 = create_task annotated: @pm, fieldset: 'metadata' ; sleep 1
    [@t1, @t2, @t3, @m1, @m2, @m3].each { |t| t.order = nil ; t.save! }
    @u = create_user
    @tu = create_team_user team: @t, user: @u, role: 'admin'
    @f1 = Rack::Test::UploadedFile.new(File.join(Rails.root, 'test', 'data', 'rails.png'), 'image/png')
    @f2 = Rack::Test::UploadedFile.new(File.join(Rails.root, 'test', 'data', 'rails2.png'), 'image/png')
    @f3 = Rack::Test::UploadedFile.new(File.join(Rails.root, 'test', 'data', 'rails.mp4'), 'video/mp4')
    authenticate_with_user(@u)
  end

  test "should find similar items to media item" do
    t = create_team
    pm = create_project_media team: t, media: create_uploaded_audio(file: 'rails.mp3')
    pm2 = create_project_media team: t
    Bot::Alegre.stubs(:get_items_with_similar_media_v2).returns({ pm2.id => 0.9, pm.id => 0.8 })

    query = 'query { project_media(ids: "' + [pm.id, t.id].join(',') + '") { similar_items(first: 10000) { edges { node { dbid } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal pm2.id, JSON.parse(@response.body)['data']['project_media']['similar_items']['edges'][0]['node']['dbid']

    Bot::Alegre.unstub(:get_items_with_similar_media_v2)
  end

  test "should find similar items to text item" do
    t = create_team
    m = create_claim_media quote: 'This is a test'
    m2 = create_claim_media quote: 'Foo bar'
    pm = create_project_media team: t, media: m
    pm2 = create_project_media team: t, media: m2
    create_claim_description project_media: pm2
    Bot::Alegre.stubs(:get_items_from_similar_text).returns({ pm2.id => 0.9, pm.id => 0.8 })

    query = 'query { project_media(ids: "' + [pm.id, t.id].join(',') + '") { similar_items(first: 10000) { edges { node { dbid, claim_description { id, fact_check { id } } } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal pm2.id, JSON.parse(@response.body)['data']['project_media']['similar_items']['edges'][0]['node']['dbid']

    Bot::Alegre.unstub(:get_items_from_similar_text)
  end

  test "should create and update flags and content warning" do
    t = create_team
    u = create_user is_admin: true
    pm = create_project_media team: t
    authenticate_with_user(u)
    # verify create
    query = 'mutation create { createDynamic(input: { annotation_type: "flag", clientMutationId: "1", annotated_type: "ProjectMedia", annotated_id: "' + pm.id.to_s + '", set_fields: "{\"flags\":{\"adult\":3,\"spoof\":2,\"medical\":1,\"violence\":3,\"racy\":4,\"spam\":0},\"show_cover\":false}" }) { dynamic { dbid, id } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert JSON.parse(@response.body).dig('errors').blank?

    d = Dynamic.find(JSON.parse(@response.body)['data']['createDynamic']['dynamic']['dbid'])
    data = d.data.with_indifferent_access
    assert_equal ['flags', 'show_cover'].sort, data.keys.sort
    assert_equal ['adult', 'spoof', 'medical', 'violence', 'racy', 'spam'].sort, data['flags'].keys.sort
    assert !data['show_cover']
    # verify update
    query = 'mutation update { updateDynamic(input: { annotation_type: "flag", clientMutationId: "1", id: "' + d.graphql_id + '", set_fields: "{\"show_cover\":true}" }) { dynamic { dbid } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    d = Dynamic.find(d.id)
    data = d.data.with_indifferent_access
    assert_equal ['flags', 'show_cover'].sort, data.keys.sort
    assert_equal ['adult', 'spoof', 'medical', 'violence', 'racy', 'spam'].sort, data['flags'].keys.sort
    assert data['show_cover']
  end

  test "should return number of tasks related to a team task" do
    t = create_team
    tt = create_team_task team_id: t.id
    pm = create_project_media team: t
    pm2 = create_project_media team: t
    pm3 = create_project_media team: t
    # add response to task for pm
    pm_tt = pm.annotations('task').select{|t| t.team_task_id == tt.id}.last
    pm_tt.response = { annotation_type: 'task_response_free_text', set_fields: { response_task: 'Foo' }.to_json }.to_json
    pm_tt.save!

    query = 'query { team { team_tasks(fieldset: "tasks") { edges { node { dbid tasks_count tasks_with_answers_count } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    response = JSON.parse(@response.body)['data']['team']['team_tasks']['edges'][0]['node']
    assert_equal tt.id, response['dbid']
    assert_equal 3, response['tasks_count']
    assert_equal 1, response['tasks_with_answers_count']
  end

  test "should not raise error that user can't be updated" do
    t1 = create_team
    t2 = create_team
    u = create_user
    create_team_user user: u, team: t1
    create_team_user user: u, team: t2
    u.current_team_id = t1.id
    u.save!
    authenticate_with_user(u)
    query = 'query { search(query: "{}") { number_of_results } }'
    post :create, params: { query: query, team: t2.slug }
    assert_response :success
  end

  test "should get version related to status change" do
    with_versioning do
      u = create_user
      t = create_team
      create_team_user user: u, team: t, role: 'admin'
      pm = nil
      with_current_user_and_team(u, t) do
        pm = create_project_media team: t
        s = pm.last_status_obj
        s.status = 'in_progress'
        s.save!
      end
      authenticate_with_user(u)
      query = 'query { project_media(ids: "' + [pm.id, t.id].join(',') + '") {  log(annotation_types: ["verification_status"]) { edges { node { annotation { annotation_type } } } } } }'
      post :create, params: { query: query, team: t.slug }
      assert_response :success
      log = JSON.parse(@response.body)['data']['project_media']['log']['edges'].collect{ |e| e['node'] }
      assert_equal 1, log.size
      assert_equal 'verification_status', log[0]['annotation']['annotation_type']
    end
  end

  test "should not create more items than what the rate limit allows" do
    t = create_team
    a = ApiKey.create!
    a.rate_limits = { created_items_per_minute: 1 }
    a.save!
    b = create_bot_user api_key_id: a.id
    create_team_user team: t, user: b
    authenticate_with_token(a)

    query = 'mutation { createProjectMedia(input: { quote: "Foo" }) { project_media { dbid } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success

    query = 'mutation { createProjectMedia(input: { quote: "Bar" }) { project_media { dbid } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response 429
  end

  test "should get feed" do
    t = create_team
    u = create_user is_admin: true
    authenticate_with_user(u)

    f = create_feed
    f.teams << t
    FeedTeam.update_all(shared: true)

    r1 = create_request feed: f
    r2 = create_request feed: f
    r2.similar_to_request = r1
    r2.save!

    query = "query { team { feed(dbid: #{f.id}) { requests_count, requests(request_id: null, first: 100, offset: 0, sort: \"requests\", sort_type: \"asc\") { edges { node { dbid, media { id } } } } } } }"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    response = JSON.parse(@response.body).dig('data', 'team', 'feed', 'requests', 'edges')
    assert_equal 1, response.size
    assert_equal r1.id, response.dig(0, 'node', 'dbid')

    query = "query { team { feed(dbid: #{f.id}) { requests_count, requests(request_id: #{r1.id}, first: 100, offset: 0, sort: \"requests\", sort_type: \"asc\") { edges { node { dbid, feed { name }, media { id } } } } } } }"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    response = JSON.parse(@response.body).dig('data', 'team', 'feed', 'requests', 'edges')
    assert_equal 2, response.size
  end

  test "should get feed directly by id" do
    t = create_team
    u = create_user
    create_team_user user: u, team: t
    authenticate_with_user(u)

    f1 = create_feed
    f1.teams << t
    f2 = create_feed
    FeedTeam.update_all(shared: true)

    query = "query { feed(id: \"#{f1.id}\") { dbid } }"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal f1.id, JSON.parse(@response.body).dig('data', 'feed', 'dbid')

    query = "query { feed(id: \"#{f2.id}\") { dbid } }"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_nil JSON.parse(@response.body).dig('data', 'feed', 'dbid')
  end

  test "should get request directly by id" do
    t = create_team
    u = create_user
    create_team_user user: u, team: t
    authenticate_with_user(u)

    f1 = create_feed
    f1.teams << t
    f2 = create_feed
    FeedTeam.update_all(shared: true)

    r1 = create_request feed: f1
    r2 = create_request feed: f2

    query = "query { request(id: \"#{r1.id}\") { dbid } }"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal r1.id, JSON.parse(@response.body).dig('data', 'request', 'dbid')

    query = "query { request(id: \"#{r2.id}\") { dbid } }"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_nil JSON.parse(@response.body).dig('data', 'request', 'dbid')
  end

  test "should filter similar requests by media" do
    t = create_team
    u = create_user
    create_team_user user: u, team: t
    authenticate_with_user(u)

    f = create_feed
    f.teams << t
    FeedTeam.update_all(shared: true)

    r1 = create_request feed: f
    r2 = create_request feed: f
    r2.similar_to_request = r1
    r2.save!
    m = create_uploaded_image
    r3 = create_request feed: f, media: m
    r3.similar_to_request = r1
    r3.save!

    query = "query { request(id: \"#{r1.id}\") { similar_requests(first: 10) { edges { node { dbid } } } } }"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal 2, JSON.parse(@response.body).dig('data', 'request', 'similar_requests', 'edges').size

    query = "query { request(id: \"#{r1.id}\") { similar_requests(first: 10, media_id: #{m.id}) { edges { node { dbid } } } } }"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal 1, JSON.parse(@response.body).dig('data', 'request', 'similar_requests', 'edges').size
  end

  test "should bulk-accept or reject suggested items" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    authenticate_with_user(u)
    pm_s = create_project_media team: t
    pm_t1 = create_project_media team: t
    pm_t2 = create_project_media team: t
    pm_t3 = create_project_media team: t
    r1 = create_relationship source_id: pm_s.id, target_id: pm_t1.id, relationship_type: Relationship.suggested_type
    r2 = create_relationship source_id: pm_s.id, target_id: pm_t2.id, relationship_type: Relationship.suggested_type
    r3 = create_relationship source_id: pm_s.id, target_id: pm_t3.id, relationship_type: Relationship.suggested_type
    relations = [r1, r2, r3]
    ids = relations.map(&:graphql_id).to_json
    query = 'mutation { updateRelationships(input: { clientMutationId: "1", ids: ' + ids + ', action: "accept", source_id: ' + pm_s.id.to_s + ' }) { ids, source_project_media { dbid } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal Relationship.confirmed_type, r1.reload.relationship_type
    assert_equal Relationship.confirmed_type, r2.reload.relationship_type
    assert_equal Relationship.confirmed_type, r3.reload.relationship_type
    query = 'mutation { destroyRelationships(input: { clientMutationId: "1", ids: ' + ids + ', source_id: ' + pm_s.id.to_s + ' }) { ids, source_project_media { dbid } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    count = Relationship.where(id: [r1.id, r2.id, r3.id]).count
    assert_equal 0, count
  end

  test "should return if item is read" do
    u = create_user is_admin: true
    t = create_team
    pm1 = create_project_media team: t
    ProjectMediaUser.create! user: u, project_media: pm1, read: true
    pm2 = create_project_media team: t
    ProjectMediaUser.create! user: create_user, project_media: pm2, read: true
    pm3 = create_project_media team: t
    authenticate_with_user(u)

    {
      pm1.id => [true, true],
      pm2.id => [true, false],
      pm3.id => [false, false]
    }.each do |id, values|
      ids = [id, t.id].join(',')
      query = 'query { project_media(ids: "' + ids + '") { read_by_someone: is_read, read_by_me: is_read(by_me: true) } }'
      post :create, params: { query: query, team: t.slug }
      assert_response :success
      data = JSON.parse(@response.body)['data']['project_media']
      assert_equal values[0], data['read_by_someone']
      assert_equal values[1], data['read_by_me']
    end
  end

  test "should update archived media by owner" do
    pm = create_project_media team: @t, archived: CheckArchivedFlags::FlagCodes::TRASHED
    query = "mutation { updateProjectMedia(input: { clientMutationId: \"1\", id: \"#{pm.graphql_id}\"}) { project_media { permissions } } }"
    post :create, params: { query: query, team: @t.slug }
    assert_response :success
    data = JSON.parse(@response.body)['data']['updateProjectMedia']['project_media']
    permissions = JSON.parse(data['permissions'])
    assert_equal true, permissions['update ProjectMedia']
  end

  test "should not bulk-send project medias to trash if there are more than 10.000 ids" do
    ids = []
    10001.times { ids << random_string }
    query = 'mutation { updateProjectMedias(input: { clientMutationId: "1", ids: ' + ids.to_json + ', action: "archived", params: "{\"archived:\": 1}" }) { ids, team { dbid } } }'
    post :create, params: { query: query, team: @t.slug }
    assert_response 400
    assert_error_message 'maximum'
  end

  test "should create tag and get tag text as parent" do
    u = create_user is_admin: true
    pm = create_project_media
    authenticate_with_user(u)
    query = 'mutation { createTag(input: { annotated_type: "ProjectMedia", annotated_id: "' + pm.id.to_s + '", tag: "Test" }) { tag_text_object { text } } }'
    assert_difference 'Tag.length', 1 do
      post :create, params: { query: query, team: pm.team.slug }
    end
    assert_response :success
    assert_equal 'Test', JSON.parse(@response.body)['data']['createTag']['tag_text_object']['text']
  end

  test "should get relevant articles for ProjectMedia item" do
    t = create_team
    pm = create_project_media quote: 'Foo Bar', team: t
    ex = create_explainer language: 'en', team: t, title: 'Foo Bar'
    pm.explainers << ex
    cd = create_claim_description description: pm.title, project_media: pm
    fc = create_fact_check claim_description: cd, title: pm.title
    items = FactCheck.where(id: fc.id) + Explainer.where(id: ex.id)
    ProjectMedia.any_instance.stubs(:get_similar_articles).returns(items)
    query = "query { project_media(ids: \"#{pm.id}\") { relevant_articles_count, relevant_articles {  edges { node { ... on FactCheck { dbid }, ... on Explainer { dbid } } } } } }"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    data = JSON.parse(@response.body)['data']['project_media']
    assert_equal 2, data['relevant_articles_count']
    item_ids = data['relevant_articles']['edges'].collect{ |i| i['node']['dbid'] }
    assert_equal items.map(&:id).sort, item_ids.sort
    ProjectMedia.any_instance.unstub(:get_similar_articles)
  end

  protected

  def assert_error_message(expected)
    assert_match /#{expected}/, JSON.parse(@response.body)['errors'][0]['message']
  end
end
