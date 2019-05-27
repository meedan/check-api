require_relative '../test_helper'

class GraphqlController3Test < ActionController::TestCase
  def setup
    @controller = Api::V1::GraphqlController.new
    @url = 'https://www.youtube.com/user/MeedanTube'
    require 'sidekiq/testing'
    Sidekiq::Testing.inline!
    super
    User.unstub(:current)
    Team.unstub(:current)
    User.current = nil
    Team.current = nil
    create_translation_status_stuff
    create_verification_status_stuff(false)
  end
  
  test "should avoid n+1 queries problem" do
    n = 2 # Number of media items to be created
    m = 2 # Number of annotations per media
    u = create_user
    authenticate_with_user(u)
    t = create_team slug: 'team'
    create_team_user user: u, team: t
    p = create_project team: t
    with_current_user_and_team(u, t) do
      n.times do
        pm = create_project_media project: p, disable_es_callbacks: false
        m.times { create_comment annotated: pm, annotator: u, disable_es_callbacks: false } 
      end
    end
    sleep 4

    query = "query { search(query: \"{}\") { medias(first: 10000) { edges { node { dbid, media { dbid } } } } } }"

    # This number should be always CONSTANT regardless the number of medias and annotations above
    assert_queries (15) do
      post :create, query: query, team: 'team'
    end

    assert_response :success
    assert_equal n, JSON.parse(@response.body)['data']['search']['medias']['edges'].size
  end

  test "should get project information fast" do
    n = 2 # Number of media items to be created
    m = 2 # Number of annotations per media (doesn't matter in this case because we use the cached count - using random values to make sure it remains consistent)
    u = create_user
    authenticate_with_user(u)
    t = create_team slug: 'team'
    create_team_user user: u, team: t
    p = create_project team: t
    n.times do
      pm = create_project_media project: p, user: create_user, disable_es_callbacks: false
      s = create_source
      create_project_source project: p, source: s, disable_es_callbacks: false
      create_account_source source: s, disable_es_callbacks: false
      m.times { create_comment annotated: pm, annotator: create_user, disable_es_callbacks: false }
      pm.project_source
    end
    create_project_media project: p, user: u, disable_es_callbacks: false
    pm = create_project_media project: p, disable_es_callbacks: false
    pm.archived = true
    pm.save!
    pm.project_source
    sleep 10

    query = 'query CheckSearch { search(query: "{\"projects\":[' + p.id.to_s + ']}") { id,medias(first:20){edges{node{id,dbid,url,quote,published,updated_at,embed,log_count,verification_statuses,overridden,project_id,pusher_channel,domain,permissions,last_status,last_status_obj{id,dbid},account{id,dbid},project{id,dbid,title},project_source{dbid,id},media{url,quote,embed_path,thumbnail_path,id},user{name,source{dbid,accounts(first:10000){edges{node{url,id}}},id},id},team{slug,id},tags(first:10000){edges{node{tag,id}}}}}}}}'

    # Make sure we only run queries for the 20 first items
    assert_queries 320, '<=' do
      post :create, query: query, team: 'team'
    end

    assert_response :success
    assert_equal 3, JSON.parse(@response.body)['data']['search']['medias']['edges'].size
  end

  test "should filter and sort inside ElasticSearch" do
    u = create_user is_admin: true
    authenticate_with_user(u)
    t1 = create_team
    p1a = create_project team: t1
    p1b = create_project team: t1
    pm1a = create_project_media project: p1a, disable_es_callbacks: false ; sleep 1
    pm1b = create_project_media project: p1b, disable_es_callbacks: false ; sleep 1
    pm1b.disable_es_callbacks = false ; pm1b.updated_at = Time.now ; pm1b.save! ; sleep 1
    pm1a.disable_es_callbacks = false ; pm1a.updated_at = Time.now ; pm1a.save! ; sleep 1
    pm1c = create_project_media project: p1a, disable_es_callbacks: false, archived: true ; sleep 1 
    pm1d = create_project_media project: p1a, disable_es_callbacks: false, inactive: true ; sleep 1 
    t2 = create_team
    p2 = create_project team: t2
    pm2 = []
    6.times do
      pm2 << create_project_media(project: p2, disable_es_callbacks: false)
      sleep 1
    end

    sleep 10

    # Default sort criteria and order: recent added, descending
    query = 'query CheckSearch { search(query: "{}") {medias(first:20){edges{node{dbid}}}}}'
    post :create, query: query, team: t1.slug
    assert_response :success
    results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
    assert_equal [pm1b.id, pm1a.id], results

    # Another sort criteria and default order: recent activity, descending
    query = 'query CheckSearch { search(query: "{\"sort\":\"recent_activity\"}") {medias(first:20){edges{node{dbid}}}}}'
    post :create, query: query, team: t1.slug
    assert_response :success
    results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
    assert_equal [pm1a.id, pm1b.id], results

    # Default sorting criteria and custom order: recent added, ascending
    query = 'query CheckSearch { search(query: "{\"sort_type\":\"asc\"}") {medias(first:20){edges{node{dbid}}}}}'
    post :create, query: query, team: t1.slug
    assert_response :success
    results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
    assert_equal [pm1a.id, pm1b.id], results

    # Another search criteria and another order: recent activity, ascending
    query = 'query CheckSearch { search(query: "{\"sort\":\"recent_activity\",\"sort_type\":\"asc\"}") {medias(first:20){edges{node{dbid}}}}}'
    post :create, query: query, team: t1.slug
    assert_response :success
    results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
    assert_equal [pm1b.id, pm1a.id], results

    # Filter by project
    query = 'query CheckSearch { search(query: "{\"projects\":[' + p1b.id.to_s + ']}") {medias(first:20){edges{node{dbid}}}}}'
    post :create, query: query, team: t1.slug
    assert_response :success
    results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
    assert_equal [pm1b.id], results

    # Get archived items
    query = 'query CheckSearch { search(query: "{\"archived\":1}") {medias(first:20){edges{node{dbid}}}}}'
    post :create, query: query, team: t1.slug
    assert_response :success
    results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
    assert_equal [pm1c.id], results

    # Relationships
    pm1e = create_project_media project: p1a, disable_es_callbacks: false ; sleep 1
    pm1f = create_project_media project: p1a, disable_es_callbacks: false, media: nil, quote: 'Test 1' ; sleep 1 
    pm1g = create_project_media project: p1a, disable_es_callbacks: false, media: nil, quote: 'Test 2' ; sleep 1 
    pm1h = create_project_media project: p1a, disable_es_callbacks: false, media: nil, quote: 'Test 3' ; sleep 1 
    create_relationship source_id: pm1e.id, target_id: pm1f.id, disable_es_callbacks: false ; sleep 1
    create_relationship source_id: pm1e.id, target_id: pm1g.id, disable_es_callbacks: false ; sleep 1
    create_relationship source_id: pm1e.id, target_id: pm1h.id, disable_es_callbacks: false ; sleep 1
    query = 'query CheckSearch { search(query: "{\"keyword\":\"Test\"}") {number_of_results,medias(first:20){edges{node{dbid}}}}}'
    post :create, query: query, team: t1.slug
    assert_response :success
    response = JSON.parse(@response.body)['data']['search']
    assert_equal 3, response['number_of_results']
    results = response['medias']['edges'].collect{ |x| x['node']['dbid'] }
    assert_equal [pm1f.id, pm1g.id, pm1h.id].sort, results.sort

    # Paginate, page 1
    query = 'query CheckSearch { search(query: "{\"projects\":[' + p2.id.to_s + '],\"eslimit\":2,\"esoffset\":0}") {medias(first:20){edges{node{dbid}}}}}'
    post :create, query: query, team: t2.slug
    assert_response :success
    results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
    assert_equal [pm2[5].id, pm2[4].id], results

    # Paginate, page 2
    query = 'query CheckSearch { search(query: "{\"projects\":[' + p2.id.to_s + '],\"eslimit\":2,\"esoffset\":2}") {medias(first:20){edges{node{dbid}}}}}'
    post :create, query: query, team: t2.slug
    assert_response :success
    results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
    assert_equal [pm2[3].id, pm2[2].id], results

    # Paginate, page 3
    query = 'query CheckSearch { search(query: "{\"projects\":[' + p2.id.to_s + '],\"eslimit\":2,\"esoffset\":4}") {number_of_results,medias(first:20){edges{node{dbid}}}}}'
    post :create, query: query, team: t2.slug
    assert_response :success
    response = JSON.parse(@response.body)['data']['search']
    assert_equal 6, response['number_of_results']
    results = response['medias']['edges'].collect{ |x| x['node']['dbid'] }
    assert_equal [pm2[1].id, pm2[0].id], results
  end

  test "should filter search results for annotators" do
    u1 = create_user name: 'Annotator'
    u2 = create_user name: 'Owner'
    t = create_team
    create_team_user user: u1, team: t, role: 'annotator'
    create_team_user user: u2, team: t, role: 'owner'
    p = create_project team: t
    pm1 = create_project_media project: p, disable_es_callbacks: false ; sleep 1
    pm2 = create_project_media project: p, disable_es_callbacks: false ; sleep 1
    tk = create_task annotated: pm1, disable_es_callbacks: false ; sleep 1
    tk.assign_user(u1.id)
    authenticate_with_user(u1)
    query = 'query CheckSearch { search(query: "{\"eslimit\":1}") {medias(first:20){edges{node{dbid}}}}}'
    post :create, query: query, team: t.slug
    assert_response :success
    results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
    assert_equal [pm1.id], results
  end

  test "should filter by date range" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'owner'
    p = create_project team: t

    Time.stubs(:now).returns(Time.new(2019, 05, 18, 13, 00))
    pm1 = create_project_media project: p, quote: 'Test A', disable_es_callbacks: false
    pm1.update_attribute(:updated_at, Time.new(2019, 05, 19))
    sleep 1

    Time.stubs(:now).returns(Time.new(2019, 05, 20, 13, 00))
    pm2 = create_project_media project: p, quote: 'Test B', disable_es_callbacks: false
    pm2.update_attribute(:updated_at, Time.new(2019, 05, 21))
    sleep 1

    Time.stubs(:now).returns(Time.new(2019, 05, 22, 13, 00))
    pm3 = create_project_media project: p, quote: 'Test C', disable_es_callbacks: false
    pm3.update_attribute(:updated_at, Time.new(2019, 05, 23))
    sleep 1

    Time.unstub(:now)
    authenticate_with_user(u)
    queries = []

    # query on ES
    queries << 'query CheckSearch { search(query: "{\"keyword\":\"Test\", \"range\": {\"created_at\":{\"start_time\":\"2019-05-19\",\"end_time\":\"2019-05-24\"},\"updated_at\":{\"start_time\":\"2019-05-20\",\"end_time\":\"2019-05-22\"},\"timezone\":\"America/Bahia\"}}") { id,medias(first:20){edges{node{dbid}}}}}'

    # query on PG
    queries << 'query CheckSearch { search(query: "{\"range\": {\"created_at\":{\"start_time\":\"2019-05-19\",\"end_time\":\"2019-05-24\"},\"updated_at\":{\"start_time\":\"2019-05-20\",\"end_time\":\"2019-05-22\"},\"timezone\":\"America/Bahia\"}}") { id,medias(first:20){edges{node{dbid}}}}}'

    queries.each do |query|
      post :create, query: query, team: t.slug
      assert_response :success
      results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
      assert_equal [pm2.id], results
    end
  end

  test "should get timezone from header" do
    authenticate_with_user
    @request.headers['X-Timezone'] = 'America/Bahia'
    t = create_team slug: 'context'
    post :create, query: 'query Query { me { name } }'
    assert_equal 'America/Bahia', assigns(:context_timezone)
  end

end
