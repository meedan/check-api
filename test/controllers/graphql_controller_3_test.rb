require_relative '../test_helper'

class GraphqlController3Test < ActionController::TestCase
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

  test "should filter and sort inside ElasticSearch" do
    Sidekiq::Testing.inline! do
      u = create_user is_admin: true
      authenticate_with_user(u)
      t1 = create_team
      pm1a = create_project_media team: t1, disable_es_callbacks: false ; sleep 1
      pm1b = create_project_media team: t1, disable_es_callbacks: false ; sleep 1
      pm1b.disable_es_callbacks = false ; pm1b.updated_at = Time.now ; pm1b.save! ; sleep 1
      pm1a.disable_es_callbacks = false ; pm1a.updated_at = Time.now ; pm1a.save! ; sleep 1
      pm1c = create_project_media team: t1, disable_es_callbacks: false, archived: CheckArchivedFlags::FlagCodes::TRASHED ; sleep 1
      t2 = create_team
      pm2 = []
      6.times do
        pm2 << create_project_media(team: t2, disable_es_callbacks: false)
      end
      sleep 2

      # Default sort criteria and order: recent added, descending
      query = 'query CheckSearch { search(query: "{}") {medias(first:20){edges{node{dbid}}}}}'
      post :create, params: { query: query, team: t1.slug }
      assert_response :success
      results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
      assert_equal [pm1b.id, pm1a.id], results

      # Another sort criteria and default order: recent activity, descending
      query = 'query CheckSearch { search(query: "{\"sort\":\"recent_activity\"}") {medias(first:20){edges{node{dbid}}}}}'
      post :create, params: { query: query, team: t1.slug }
      assert_response :success
      results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
      assert_equal [pm1a.id, pm1b.id], results

      # Default sorting criteria and custom order: recent added, ascending
      query = 'query CheckSearch { search(query: "{\"sort_type\":\"asc\"}") {medias(first:20){edges{node{dbid}}}}}'
      post :create, params: { query: query, team: t1.slug }
      assert_response :success
      results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
      assert_equal [pm1a.id, pm1b.id], results

      # Another search criteria and another order: recent activity, ascending
      query = 'query CheckSearch { search(query: "{\"sort\":\"recent_activity\",\"sort_type\":\"asc\"}") {medias(first:20){edges{node{dbid}}}}}'
      post :create, params: { query: query, team: t1.slug }
      assert_response :success
      results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
      assert_equal [pm1b.id, pm1a.id], results

      # Get archived items
      query = 'query CheckSearch { search(query: "{\"archived\":1}") {medias(first:20){edges{node{dbid}}}}}'
      post :create, params: { query: query, team: t1.slug }
      assert_response :success
      results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
      assert_equal [pm1c.id], results

      # Relationships
      pm1e = create_project_media team: t1, disable_es_callbacks: false ; sleep 1
      pm1f = create_project_media team: t1, disable_es_callbacks: false, media: nil, quote: 'Test 1' ; sleep 1
      pm1g = create_project_media team: t1, disable_es_callbacks: false, media: nil, quote: 'Test 2' ; sleep 1
      pm1h = create_project_media team: t1, disable_es_callbacks: false, media: nil, quote: 'Test 3' ; sleep 1
      create_relationship source_id: pm1e.id, target_id: pm1f.id, disable_es_callbacks: false ; sleep 1
      create_relationship source_id: pm1e.id, target_id: pm1g.id, disable_es_callbacks: false ; sleep 1
      create_relationship source_id: pm1e.id, target_id: pm1h.id, disable_es_callbacks: false ; sleep 1
      query = 'query CheckSearch { search(query: "{\"keyword\":\"Test\", \"show_similar\":true}") {number_of_results,medias(first:20){edges{node{dbid}}}}}'
      post :create, params: { query: query, team: t1.slug }
      assert_response :success
      response = JSON.parse(@response.body)['data']['search']
      assert_equal 3, response['number_of_results']
      results = response['medias']['edges'].collect{ |x| x['node']['dbid'] }
      assert_equal [pm1f.id, pm1g.id, pm1h.id].sort, results.sort

      # Paginate, page 1
      query = 'query CheckSearch { search(query: "{\"eslimit\":2,\"esoffset\":0}") {medias(first:20){edges{node{dbid}}}}}'
      post :create, params: { query: query, team: t2.slug }
      assert_response :success
      results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
      assert_equal [pm2[5].id, pm2[4].id], results

      # Paginate, page 2
      query = 'query CheckSearch { search(query: "{\"eslimit\":2,\"esoffset\":2}") {medias(first:20){edges{node{dbid}}}}}'
      post :create, params: { query: query, team: t2.slug }
      assert_response :success
      results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
      assert_equal [pm2[3].id, pm2[2].id], results

      # Paginate, page 3
      query = 'query CheckSearch { search(query: "{\"eslimit\":2,\"esoffset\":4}") {number_of_results,medias(first:20){edges{node{dbid}}}}}'
      post :create, params: { query: query, team: t2.slug }
      assert_response :success
      response = JSON.parse(@response.body)['data']['search']
      assert_equal 6, response['number_of_results']
      results = response['medias']['edges'].collect{ |x| x['node']['dbid'] }
      assert_equal [pm2[1].id, pm2[0].id], results
    end
  end

  test "should filter by date range" do
    Sidekiq::Testing.inline! do
      u = create_user
      t = create_team
      create_team_user user: u, team: t, role: 'admin'

      Time.stubs(:now).returns(Time.new(2019, 05, 18, 13, 00))
      pm1 = create_project_media team: t, quote: 'Test A', disable_es_callbacks: false
      pm1.update_attribute(:updated_at, Time.new(2019, 05, 19))
      sleep 1

      Time.stubs(:now).returns(Time.new(2019, 05, 20, 13, 00))
      pm2 = create_project_media team: t, quote: 'Test B', disable_es_callbacks: false
      pm2.update_attribute(:updated_at, Time.new(2019, 05, 21, 12, 00))
      sleep 1

      Time.stubs(:now).returns(Time.new(2019, 05, 22, 13, 00))
      pm3 = create_project_media team: t, quote: 'Test C', disable_es_callbacks: false
      pm3.update_attribute(:updated_at, Time.new(2019, 05, 23))
      sleep 1

      Time.unstub(:now)
      authenticate_with_user(u)
      queries = []

      # query on ES
      queries << 'query CheckSearch { search(query: "{\"keyword\":\"Test\", \"range\": {\"created_at\":{\"start_time\":\"2019-05-19\",\"end_time\":\"2019-05-24\"},\"updated_at\":{\"start_time\":\"2019-05-20\",\"end_time\":\"2019-05-21\"},\"timezone\":\"America/Bahia\"}}") { id,medias(first:20){edges{node{dbid}}}}}'

      # query on PG
      queries << 'query CheckSearch { search(query: "{\"range\": {\"created_at\":{\"start_time\":\"2019-05-19\",\"end_time\":\"2019-05-24\"},\"updated_at\":{\"start_time\":\"2019-05-20\",\"end_time\":\"2019-05-21\"},\"timezone\":\"America/Bahia\"}}") { id,medias(first:20){edges{node{dbid}}}}}'

      queries.each do |query|
        post :create, params: { query: query, team: t.slug }
        assert_response :success
        results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
        assert_equal [pm2.id], results
      end
    end
  end


  test "should filter by date range with less_than and more_than options" do
    Sidekiq::Testing.inline! do
      u = create_user
      t = create_team
      create_team_user user: u, team: t, role: 'admin'

      Time.stubs(:now).returns(Time.new - 5.week)
      pm1 = create_project_media team: t, quote: 'Test A', disable_es_callbacks: false
      Time.stubs(:now).returns(Time.new - 3.week)
      pm2 = create_project_media team: t, quote: 'Test B', disable_es_callbacks: false
      sleep 1

      Time.unstub(:now)
      authenticate_with_user(u)

      queries = []
      # query on ES
      queries << 'query CheckSearch { search(query: "{\"keyword\":\"Test\", \"range\": {\"created_at\":{\"condition\":\"less_than\",\"period\":\"1\",\"period_type\":\"m\"},\"timezone\":\"America/Bahia\"}}") { id,medias(first:20){edges{node{dbid}}}}}'
      # query on PG
      queries << 'query CheckSearch { search(query: "{\"range\": {\"created_at\":{\"condition\":\"less_than\",\"period\":\"1\",\"period_type\":\"m\"},\"timezone\":\"America/Bahia\"}}") { id,medias(first:20){edges{node{dbid}}}}}'
      queries.each do |query|
        post :create, params: { query: query, team: t.slug }
        assert_response :success
        results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
        assert_equal [pm2.id], results
      end
      # Filter by more_than
      queries = []
      # query on ES
      queries << 'query CheckSearch { search(query: "{\"keyword\":\"Test\", \"range\": {\"created_at\":{\"condition\":\"more_than\",\"period\":\"1\",\"period_type\":\"m\"},\"timezone\":\"America/Bahia\"}}") { id,medias(first:20){edges{node{dbid}}}}}'
      # query on PG
      queries << 'query CheckSearch { search(query: "{\"range\": {\"created_at\":{\"condition\":\"more_than\",\"period\":\"1\",\"period_type\":\"m\"},\"timezone\":\"America/Bahia\"}}") { id,medias(first:20){edges{node{dbid}}}}}'
      queries.each do |query|
        post :create, params: { query: query, team: t.slug }
        assert_response :success
        results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
        assert_equal [pm1.id], results
      end
      # query with period_type = w
      queries = []
      # query on ES
      queries << 'query CheckSearch { search(query: "{\"keyword\":\"Test\", \"range\": {\"created_at\":{\"condition\":\"less_than\",\"period\":\"4\",\"period_type\":\"w\"},\"timezone\":\"America/Bahia\"}}") { id,medias(first:20){edges{node{dbid}}}}}'
      # query on PG
      queries << 'query CheckSearch { search(query: "{\"range\": {\"created_at\":{\"condition\":\"less_than\",\"period\":\"4\",\"period_type\":\"w\"},\"timezone\":\"America/Bahia\"}}") { id,medias(first:20){edges{node{dbid}}}}}'
      queries.each do |query|
        post :create, params: { query: query, team: t.slug }
        assert_response :success
        results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
        assert_equal [pm2.id], results
      end
      # query with period_type = y
      queries = []
      # query on ES
      queries << 'query CheckSearch { search(query: "{\"keyword\":\"Test\", \"range\": {\"created_at\":{\"condition\":\"less_than\",\"period\":\"1\",\"period_type\":\"y\"},\"timezone\":\"America/Bahia\"}}") { id,medias(first:20){edges{node{dbid}}}}}'
      # query on PG
      queries << 'query CheckSearch { search(query: "{\"range\": {\"created_at\":{\"condition\":\"less_than\",\"period\":\"1\",\"period_type\":\"y\"},\"timezone\":\"America/Bahia\"}}") { id,medias(first:20){edges{node{dbid}}}}}'
      queries.each do |query|
        post :create, params: { query: query, team: t.slug }
        assert_response :success
        results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
        assert_equal [pm1.id, pm2.id], results.sort
      end
      # query with period_type = d
      queries = []
      # query on ES
      queries << 'query CheckSearch { search(query: "{\"keyword\":\"Test\", \"range\": {\"created_at\":{\"condition\":\"less_than\",\"period\":\"7\",\"period_type\":\"d\"},\"timezone\":\"America/Bahia\"}}") { id,medias(first:20){edges{node{dbid}}}}}'
      # query on PG
      queries << 'query CheckSearch { search(query: "{\"range\": {\"created_at\":{\"condition\":\"less_than\",\"period\":\"7\",\"period_type\":\"d\"},\"timezone\":\"America/Bahia\"}}") { id,medias(first:20){edges{node{dbid}}}}}'
      queries.each do |query|
        post :create, params: { query: query, team: t.slug }
        assert_response :success
        results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
        assert_empty results
      end
    end
  end

  test "should retrieve information for grid" do
    Sidekiq::Testing.inline! do
      RequestStore.store[:skip_cached_field_update] = false
      u = create_user
      authenticate_with_user(u)
      t = create_team slug: 'team'
      create_team_user user: u, team: t
      m = create_uploaded_image
      pm = create_project_media team: t, user: create_user, media: m, disable_es_callbacks: false
      info = { title: random_string, content: random_string }; pm.analysis = info; pm.save!
      create_tipline_request team_id: t.id, associated: pm, smooch_data: {}
      pm2 = create_project_media team: t
      r = create_relationship source_id: pm.id, target_id: pm2.id, relationship_type: Relationship.confirmed_type
      create_tipline_request team_id: t.id, associated: pm2, smooch_data: {}
      create_claim_description project_media: pm, description: 'Test'

      sleep 10

      query = '
        query CheckSearch { search(query: "{}") {
          id
          number_of_results
          medias(first: 1) {
            edges {
              node {
                id
                dbid
                picture
                title
                description
                virality
                demand
                linked_items_count
                type
                status
                first_seen: created_at
                last_seen
              }
            }
          }
        }}
      '

      assert_queries 25, '<=' do
        post :create, params: { query: query, team: 'team' }
      end

      assert_response :success
      result = JSON.parse(@response.body)['data']['search']
      assert_equal 1, result['number_of_results']
      assert_equal 1, result['medias']['edges'].size
      result['medias']['edges'].each do |pm_node|
        pm = pm_node['node']
        assert_equal 'Test', pm['title']
        assert_equal 'Test', pm['description']
        assert_equal 0, pm['virality']
        assert_equal 2, pm['linked_items_count']
        assert_equal 'UploadedImage', pm['type']
        assert_not_equal pm['first_seen'], pm['last_seen']
        assert_equal 2, pm['demand']
      end
    end
  end

  test "should return cached value for dynamic annotation" do
    team = create_team
    d = create_dynamic_annotation annotation_type: 'smooch_user', set_fields: { smooch_user_data: { app_name: 'foo', identifier: 'bar' }.to_json, smooch_user_app_id: 'fake', smooch_user_id: 'fake' }.to_json
    api_key = create_api_key team: team
    authenticate_with_token(api_key)
    assert_nil ApiKey.current

    post :create, params: { query: 'query Query { dynamic_annotation_field(only_cache: true, query: "{\"field_name\":\"smooch_user_data\",\"json\":{\"app_name\":\"foo\",\"identifier\":\"bar\"}}") { annotation { dbid } } }' }
    assert_response :success
    assert_nil JSON.parse(@response.body)['data']['dynamic_annotation_field']

    query = 'query Query { dynamic_annotation_field(query: "{\"field_name\":\"smooch_user_data\",\"json\":{\"app_name\":\"foo\",\"identifier\":\"bar\"}}") { annotation { dbid } } }'
    post :create, params: { query:  query, team: team.slug }
    assert_response :success
    assert_equal d.id, JSON.parse(@response.body)['data']['dynamic_annotation_field']['annotation']['dbid'].to_i

    query = { field_name: 'smooch_user_data', json: { app_name: 'foo', identifier: 'bar' } }.to_json
    cache_key = 'dynamic-annotation-field-' + Digest::MD5.hexdigest(query)
    Rails.cache.write(cache_key, DynamicAnnotation::Field.where(annotation_id: d.id, field_name: 'smooch_user_data').last&.id)
    query = 'query Query { dynamic_annotation_field(query: "{\"field_name\":\"smooch_user_data\",\"json\":{\"app_name\":\"foo\",\"identifier\":\"bar\"}}") { annotation { dbid } } }'
    post :create, params: { query: query, team: team.slug }
    assert_response :success
    assert_equal d.id, JSON.parse(@response.body)['data']['dynamic_annotation_field']['annotation']['dbid'].to_i
  end

  test "should return updated offset from ES" do
    Sidekiq::Testing.inline! do
      RequestStore.store[:skip_cached_field_update] = false
      u = create_user is_admin: true
      authenticate_with_user(u)
      t = create_team
      pm1 = create_project_media team: t, disable_es_callbacks: false
      create_relationship source_id: pm1.id, target_id: create_project_media(team: t).id, relationship_type: Relationship.confirmed_type
      pm2 = create_project_media team: t, disable_es_callbacks: false
      create_relationship source_id: pm2.id, target_id: create_project_media(team: t).id, relationship_type: Relationship.confirmed_type
      create_relationship source_id: pm2.id, target_id: create_project_media(team: t).id, relationship_type: Relationship.confirmed_type
      sleep 2
      query = 'query CheckSearch { search(query: "{\"sort\":\"related\",\"id\":' + pm1.id.to_s + ',\"esoffset\":0,\"eslimit\":1}") {item_navigation_offset,medias(first:20){edges{node{dbid}}}}}'
      post :create, params: { query: query, team: t.slug }
      assert_response :success
      response = JSON.parse(@response.body)['data']['search']
      assert_equal pm1.id, response['medias']['edges'][0]['node']['dbid']
      assert_equal 1, response['item_navigation_offset']
    end
  end

  test "should get requests from media" do
    u = create_user is_admin: true
    t = create_team
    create_team_user team: t, user: u, role: 'admin'
    pm = create_project_media team: t
    pm2 = create_project_media team: t
    authenticate_with_user(u)
    create_tipline_request team_id: t.id, associated: pm, smooch_data: { 'authorId' => random_string }
    create_tipline_request team_id: t.id, associated: pm, smooch_data: { 'authorId' => random_string }
    create_tipline_request team_id: t.id, associated: pm2, smooch_data: { 'authorId' => random_string }
    r = create_relationship source_id: pm.id, target_id: pm2.id, relationship_type: Relationship.confirmed_type
    query = "query { project_media(ids: \"#{pm.id}\") { requests(first: 10, includeChildren: true) { edges { node { dbid } } } } }"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    data = JSON.parse(@response.body)['data']['project_media']['requests']['edges']
    assert_equal 3, data.length
    query = "query { project_media(ids: \"#{pm2.id}\") { requests(first: 10) { edges { node { dbid, smooch_user_external_identifier, smooch_data } } } } }"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    data = JSON.parse(@response.body)['data']['project_media']['requests']['edges']
    assert_equal 1, data.length
  end

  test "should get related items if filters are null" do
    u = create_user is_admin: true
    t = create_team
    pm1 = create_project_media team: t
    pm2 = create_project_media team: t
    create_relationship source_id: pm1.id, target_id: pm2.id
    authenticate_with_user(u)
    query = "query { project_media(ids: \"#{pm1.id}\") { relationships { targets(first: 10, filters: \"null\") { edges { node { id } } } } } }"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
  end

  test "should filter by user in ElasticSearch" do
    Sidekiq::Testing.inline! do
      u = create_user
      t = create_team
      create_team_user user: u, team: t
      pm = create_project_media team: t, quote: 'This is a test', media: nil, user: u, disable_es_callbacks: false
      create_project_media team: t, user: u, disable_es_callbacks: false
      create_project_media team: t, disable_es_callbacks: false
      sleep 1
      authenticate_with_user(u)

      query = 'query CheckSearch { search(query: "{\"keyword\":\"test\",\"users\":[' + u.id.to_s + ']}") { medias(first: 10) { edges { node { dbid } } } } }'
      post :create, params: { query: query, team: t.slug }

      assert_response :success
      assert_equal [pm.id], JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
    end
  end

  test "should filter by read in ElasticSearch" do
    Sidekiq::Testing.inline! do
      u = create_user
      t = create_team
      create_team_user user: u, team: t
      pm1 = create_project_media team: t, quote: 'This is a test', media: nil, read: true, disable_es_callbacks: false
      pm2 = create_project_media team: t, quote: 'This is another test', media: nil, disable_es_callbacks: false
      pm3 = create_project_media quote: 'This is another test', media: nil, disable_es_callbacks: false
      sleep 1
      authenticate_with_user(u)

      query = 'query CheckSearch { search(query: "{\"keyword\":\"test\",\"read\":[1]}") { medias(first: 10) { edges { node { dbid } } } } }'
      post :create, params: { query: query, team: t.slug }
      assert_response :success
      assert_equal [pm1.id], JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }

      query = 'query CheckSearch { search(query: "{\"keyword\":\"test\",\"read\":[0]}") { medias(first: 10) { edges { node { dbid } } } } }'
      post :create, params: { query: query, team: t.slug }
      assert_response :success
      assert_equal [pm2.id], JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }

      query = 'query CheckSearch { search(query: "{\"keyword\":\"test\"}") { medias(first: 10) { edges { node { dbid } } } } }'
      post :create, params: { query: query, team: t.slug }
      assert_response :success
      assert_equal [pm1.id, pm2.id].sort, JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }.sort
    end
  end
end
