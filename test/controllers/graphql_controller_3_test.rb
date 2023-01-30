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
    create_verification_status_stuff
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
    pm1c = create_project_media project: p1a, disable_es_callbacks: false, archived: CheckArchivedFlags::FlagCodes::TRASHED ; sleep 1
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

    # Filter by project
    query = 'query CheckSearch { search(query: "{\"projects\":[' + p1b.id.to_s + ']}") {medias(first:20){edges{node{dbid}}}}}'
    post :create, params: { query: query, team: t1.slug }
    assert_response :success
    results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
    assert_equal [pm1b.id], results

    # Get archived items
    query = 'query CheckSearch { search(query: "{\"archived\":1}") {medias(first:20){edges{node{dbid}}}}}'
    post :create, params: { query: query, team: t1.slug }
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
    query = 'query CheckSearch { search(query: "{\"keyword\":\"Test\", \"show_similar\":true}") {number_of_results,medias(first:20){edges{node{dbid}}}}}'
    post :create, params: { query: query, team: t1.slug }
    assert_response :success
    response = JSON.parse(@response.body)['data']['search']
    assert_equal 3, response['number_of_results']
    results = response['medias']['edges'].collect{ |x| x['node']['dbid'] }
    assert_equal [pm1f.id, pm1g.id, pm1h.id].sort, results.sort

    # Paginate, page 1
    query = 'query CheckSearch { search(query: "{\"projects\":[' + p2.id.to_s + '],\"eslimit\":2,\"esoffset\":0}") {medias(first:20){edges{node{dbid}}}}}'
    post :create, params: { query: query, team: t2.slug }
    assert_response :success
    results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
    assert_equal [pm2[5].id, pm2[4].id], results

    # Paginate, page 2
    query = 'query CheckSearch { search(query: "{\"projects\":[' + p2.id.to_s + '],\"eslimit\":2,\"esoffset\":2}") {medias(first:20){edges{node{dbid}}}}}'
    post :create, params: { query: query, team: t2.slug }
    assert_response :success
    results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
    assert_equal [pm2[3].id, pm2[2].id], results

    # Paginate, page 3
    query = 'query CheckSearch { search(query: "{\"projects\":[' + p2.id.to_s + '],\"eslimit\":2,\"esoffset\":4}") {number_of_results,medias(first:20){edges{node{dbid}}}}}'
    post :create, params: { query: query, team: t2.slug }
    assert_response :success
    response = JSON.parse(@response.body)['data']['search']
    assert_equal 6, response['number_of_results']
    results = response['medias']['edges'].collect{ |x| x['node']['dbid'] }
    assert_equal [pm2[1].id, pm2[0].id], results
  end

  test "should filter by date range" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'admin'
    p = create_project team: t

    Time.stubs(:now).returns(Time.new(2019, 05, 18, 13, 00))
    pm1 = create_project_media project: p, quote: 'Test A', disable_es_callbacks: false
    pm1.update_attribute(:updated_at, Time.new(2019, 05, 19))
    sleep 1

    Time.stubs(:now).returns(Time.new(2019, 05, 20, 13, 00))
    pm2 = create_project_media project: p, quote: 'Test B', disable_es_callbacks: false
    pm2.update_attribute(:updated_at, Time.new(2019, 05, 21, 12, 00))
    sleep 1

    Time.stubs(:now).returns(Time.new(2019, 05, 22, 13, 00))
    pm3 = create_project_media project: p, quote: 'Test C', disable_es_callbacks: false
    pm3.update_attribute(:updated_at, Time.new(2019, 05, 23))
    sleep 1

    Time.unstub(:now)
    authenticate_with_user(u)
    queries = []

    # query on ES
    queries << 'query CheckSearch { search(query: "{\"keyword\":\"Test\", \"range\": {\"created_at\":{\"start_time\":\"2019-05-19\",\"end_time\":\"2019-05-24\"},\"updated_at\":{\"start_time\":\"2019-05-20\",\"end_time\":\"2019-05-21\"},\"timezone\":\"America/Bahia\"}}") { id,medias(first:20){edges{node{dbid}}}}}'

    # query on PG
    queries << 'query CheckSearch { search(query: "{\"projects\":[' + p.id.to_s + '], \"range\": {\"created_at\":{\"start_time\":\"2019-05-19\",\"end_time\":\"2019-05-24\"},\"updated_at\":{\"start_time\":\"2019-05-20\",\"end_time\":\"2019-05-21\"},\"timezone\":\"America/Bahia\"}}") { id,medias(first:20){edges{node{dbid}}}}}'

    queries.each do |query|
      post :create, params: { query: query, team: t.slug }
      assert_response :success
      results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
      assert_equal [pm2.id], results
    end
  end


  test "should filter by date range with less_than option" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'admin'
    p = create_project team: t

    Time.stubs(:now).returns(Time.new - 5.week)
    pm1 = create_project_media project: p, quote: 'Test A', disable_es_callbacks: false
    Time.stubs(:now).returns(Time.new - 3.week)
    pm2 = create_project_media project: p, quote: 'Test B', disable_es_callbacks: false
    sleep 1

    Time.unstub(:now)
    authenticate_with_user(u)

    queries = []
    # query on ES
    queries << 'query CheckSearch { search(query: "{\"keyword\":\"Test\", \"range\": {\"created_at\":{\"condition\":\"less_than\",\"period\":\"1\",\"period_type\":\"m\"},\"timezone\":\"America/Bahia\"}}") { id,medias(first:20){edges{node{dbid}}}}}'
    # query on PG
    queries << 'query CheckSearch { search(query: "{\"projects\":[' + p.id.to_s + '], \"range\": {\"created_at\":{\"condition\":\"less_than\",\"period\":\"1\",\"period_type\":\"m\"},\"timezone\":\"America/Bahia\"}}") { id,medias(first:20){edges{node{dbid}}}}}'
    queries.each do |query|
      post :create, params: { query: query, team: t.slug }
      assert_response :success
      results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
      assert_equal [pm2.id], results
    end
    # query with period_type = w
    queries = []
    # query on ES
    queries << 'query CheckSearch { search(query: "{\"keyword\":\"Test\", \"range\": {\"created_at\":{\"condition\":\"less_than\",\"period\":\"4\",\"period_type\":\"w\"},\"timezone\":\"America/Bahia\"}}") { id,medias(first:20){edges{node{dbid}}}}}'
    # query on PG
    queries << 'query CheckSearch { search(query: "{\"projects\":[' + p.id.to_s + '], \"range\": {\"created_at\":{\"condition\":\"less_than\",\"period\":\"4\",\"period_type\":\"w\"},\"timezone\":\"America/Bahia\"}}") { id,medias(first:20){edges{node{dbid}}}}}'
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
    queries << 'query CheckSearch { search(query: "{\"projects\":[' + p.id.to_s + '], \"range\": {\"created_at\":{\"condition\":\"less_than\",\"period\":\"1\",\"period_type\":\"y\"},\"timezone\":\"America/Bahia\"}}") { id,medias(first:20){edges{node{dbid}}}}}'
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
    queries << 'query CheckSearch { search(query: "{\"projects\":[' + p.id.to_s + '], \"range\": {\"created_at\":{\"condition\":\"less_than\",\"period\":\"7\",\"period_type\":\"d\"},\"timezone\":\"America/Bahia\"}}") { id,medias(first:20){edges{node{dbid}}}}}'
    queries.each do |query|
      post :create, params: { query: query, team: t.slug }
      assert_response :success
      results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
      assert_empty results
    end
  end

  test "should retrieve information for grid" do
    RequestStore.store[:skip_cached_field_update] = false
    create_verification_status_stuff
    create_annotation_type_and_fields('Smooch', { 'Data' => ['JSON', false] })
    ft = create_field_type field_type: 'image_path', label: 'Image Path'
    at = create_annotation_type annotation_type: 'reverse_image', label: 'Reverse Image'
    create_field_instance annotation_type_object: at, name: 'reverse_image_path', label: 'Reverse Image', field_type_object: ft, optional: false
    u = create_user
    authenticate_with_user(u)
    t = create_team slug: 'team'
    create_team_user user: u, team: t
    p = create_project team: t

    m = create_uploaded_image
    pm = create_project_media project: p, user: create_user, media: m, disable_es_callbacks: false
    info = { title: random_string, content: random_string }; pm.analysis = info; pm.save!
    create_dynamic_annotation(annotation_type: 'smooch', annotated: pm, set_fields: { smooch_data: '{}' }.to_json)
    pm2 = create_project_media project: p
    r = create_relationship source_id: pm.id, target_id: pm2.id, relationship_type: Relationship.confirmed_type
    create_dynamic_annotation(annotation_type: 'smooch', annotated: pm2, set_fields: { smooch_data: '{}' }.to_json)
    create_claim_description project_media: pm, description: 'Test'

    sleep 10

    query = '
      query CheckSearch { search(query: "{\"projects\":[' + p.id.to_s + ']}") {
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
      assert_equal 1, pm['linked_items_count']
      assert_equal 'UploadedImage', pm['type']
      assert_not_equal pm['first_seen'], pm['last_seen']
      assert_equal 2, pm['demand']
    end
  end

  test "should return cached value for dynamic annotation" do
    create_annotation_type_and_fields('Smooch User', { 'Data' => ['JSON', false] })
    d = create_dynamic_annotation annotation_type: 'smooch_user', set_fields: { smooch_user_data: { app_name: 'foo', identifier: 'bar' }.to_json }.to_json
    authenticate_with_token
    assert_nil ApiKey.current

    post :create, params: { query: 'query Query { dynamic_annotation_field(only_cache: true, query: "{\"field_name\":\"smooch_user_data\",\"json\":{\"app_name\":\"foo\",\"identifier\":\"bar\"}}") { annotation { dbid } } }' }
    assert_response :success
    assert_nil JSON.parse(@response.body)['data']['dynamic_annotation_field']

    post :create, params: { query: 'query Query { dynamic_annotation_field(query: "{\"field_name\":\"smooch_user_data\",\"json\":{\"app_name\":\"foo\",\"identifier\":\"bar\"}}") { annotation { dbid } } }' }
    assert_response :success
    assert_equal d.id, JSON.parse(@response.body)['data']['dynamic_annotation_field']['annotation']['dbid'].to_i

    query = { field_name: 'smooch_user_data', json: { app_name: 'foo', identifier: 'bar' } }.to_json
    cache_key = 'dynamic-annotation-field-' + Digest::MD5.hexdigest(query)
    Rails.cache.write(cache_key, DynamicAnnotation::Field.where(annotation_id: d.id, field_name: 'smooch_user_data').last&.id)

    post :create, params: { query: 'query Query { dynamic_annotation_field(query: "{\"field_name\":\"smooch_user_data\",\"json\":{\"app_name\":\"foo\",\"identifier\":\"bar\"}}") { annotation { dbid } } }' }
    assert_response :success
    assert_equal d.id, JSON.parse(@response.body)['data']['dynamic_annotation_field']['annotation']['dbid'].to_i
  end

  test "should return updated offset from ES" do
    RequestStore.store[:skip_cached_field_update] = false
    u = create_user is_admin: true
    authenticate_with_user(u)
    t = create_team
    p = create_project team: t
    pm1 = create_project_media project: p
    create_relationship source_id: pm1.id, target_id: create_project_media(project: p).id, relationship_type: Relationship.confirmed_type
    pm2 = create_project_media project: p
    create_relationship source_id: pm2.id, target_id: create_project_media(project: p).id, relationship_type: Relationship.confirmed_type
    create_relationship source_id: pm2.id, target_id: create_project_media(project: p).id, relationship_type: Relationship.confirmed_type
    sleep 10
    query = 'query CheckSearch { search(query: "{\"sort\":\"related\",\"id\":' + pm1.id.to_s + ',\"esoffset\":0,\"eslimit\":1}") {item_navigation_offset,medias(first:20){edges{node{dbid}}}}}'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    response = JSON.parse(@response.body)['data']['search']
    assert_equal pm1.id, response['medias']['edges'][0]['node']['dbid']
    assert_equal 1, response['item_navigation_offset']
  end

  test "should set smooch user slack channel url in background" do
    Sidekiq::Testing.fake! do
        create_annotation_type_and_fields('Smooch User', {
            'Data' => ['JSON', false],
            'Slack Channel Url' => ['Text', true]
        })
        u = create_user
        t = create_team
        create_team_user team: t, user: u, role: 'admin'
        p = create_project team: t
        author_id = random_string
        set_fields = { smooch_user_data: { id: author_id }.to_json }.to_json
        d = create_dynamic_annotation annotated: p, annotation_type: 'smooch_user', set_fields: set_fields
        Sidekiq::Worker.drain_all
        assert_equal 0, Sidekiq::Worker.jobs.size
        authenticate_with_token
        url = random_url
        query = 'mutation { updateDynamicAnnotationSmoochUser(input: { clientMutationId: "1", id: "' + d.graphql_id + '", set_fields: "{\"smooch_user_slack_channel_url\":\"' + url + '\"}" }) { project { dbid } } }'
        post :create, params: { query: query }
        assert_response :success
        assert_equal url, d.reload.get_field_value('smooch_user_slack_channel_url')
        # check that cache key exists
        key = "SmoochUserSlackChannelUrl:Team:#{d.team_id}:#{author_id}"
        assert_equal url, Rails.cache.read(key)
        # test using a new mutation `smoochBotAddSlackChannelUrl`
        Sidekiq::Worker.drain_all
        assert_equal 0, Sidekiq::Worker.jobs.size
        url2 = random_url
        query = 'mutation { smoochBotAddSlackChannelUrl(input: { clientMutationId: "1", id: "' + d.id.to_s + '", set_fields: "{\"smooch_user_slack_channel_url\":\"' + url2 + '\"}" }) { annotation { dbid } } }'
        post :create, params: { query: query }
        assert_response :success
        assert Sidekiq::Worker.jobs.size > 0
        assert_equal url, d.reload.get_field_value('smooch_user_slack_channel_url')
        # execute job and check that url was set
        Sidekiq::Worker.drain_all
        assert_equal url2, d.get_field_value('smooch_user_slack_channel_url')
        # check that cache key exists
        assert_equal url2, Rails.cache.read(key)
        # call mutation with non existing id
        query = 'mutation { smoochBotAddSlackChannelUrl(input: { clientMutationId: "1", id: "99999", set_fields: "{\"smooch_user_slack_channel_url\":\"' + url2 + '\"}" }) { annotation { dbid } } }'
        post :create, params: { query: query }
        assert_response :success
    end
  end

  test "should get requests from media" do
    create_annotation_type_and_fields('Smooch', { 'Data' => ['JSON', false] })
    u = create_user is_admin: true
    t = create_team
    create_team_user team: t, user: u, role: 'admin'
    pm = create_project_media team: t
    pm2 = create_project_media team: t
    authenticate_with_user(u)
    create_dynamic_annotation annotation_type: 'smooch', annotated: pm, set_fields: { smooch_data: { 'authorId' => random_string }.to_json }.to_json
    create_dynamic_annotation annotation_type: 'smooch', annotated: pm, set_fields: { smooch_data: { 'authorId' => random_string }.to_json }.to_json
    create_dynamic_annotation annotation_type: 'smooch', annotated: pm2, set_fields: { smooch_data: { 'authorId' => random_string }.to_json }.to_json
    r = create_relationship source_id: pm.id, target_id: pm2.id, relationship_type: Relationship.confirmed_type
    query = "query { project_media(ids: \"#{pm.id}\") { requests(first: 10) { edges { node { dbid } } } } }"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    data = JSON.parse(@response.body)['data']['project_media']['requests']['edges']
    assert_equal 3, data.length
    query = "query { project_media(ids: \"#{pm2.id}\") { requests(first: 10) { edges { node { dbid } } } } }"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    data = JSON.parse(@response.body)['data']['project_media']['requests']['edges']
    assert_equal 1, data.length
  end

  test "should get related items if filters are null" do
    u = create_user is_admin: true
    t = create_team
    p = create_project team: t
    pm1 = create_project_media project: p
    pm2 = create_project_media project: p
    create_relationship source_id: pm1.id, target_id: pm2.id
    authenticate_with_user(u)
    query = "query { project_media(ids: \"#{pm1.id},#{p.id}\") { relationships { targets(first: 10, filters: \"null\") { edges { node { id } } } } } }"
    post :create, params: { query: query, team: t.slug }
    assert_response :success
  end

  test "should not search without permission" do
    t1 = create_team private: true
    t2 = create_team private: true
    t3 = create_team private: false
    u = create_user
    create_team_user team: t2, user: u
    pm1 = create_project_media team: t1, project: nil
    pm2 = create_project_media team: t2, project: nil
    pm3a = create_project_media team: t3, project: nil
    pm3b = create_project_media team: t3, project: nil
    query = 'query { search(query: "{}") { number_of_results, medias(first: 10) { edges { node { dbid, permissions } } } } }'

    # Anonymous user searching across all teams
    post :create, params: { query: query }
    assert_response :success
    assert_nil JSON.parse(@response.body)['data']['search']
    assert_not_nil JSON.parse(@response.body)['errors']

    # Anonymous user searching for a public team
    post :create, params: { query: query, team: t3.slug }
    assert_response :success
    assert_not_nil JSON.parse(@response.body)['data']['search']
    assert_nil JSON.parse(@response.body)['errors']

    # Anonymous user searching for a team
    post :create, params: { query: query, team: t1.slug }
    assert_response :success
    assert_nil JSON.parse(@response.body)['data']['search']
    assert_not_nil JSON.parse(@response.body)['errors']

    # Unpermissioned user searching across all teams
    authenticate_with_user(u)
    post :create, params: { query: query, team: t1.slug }
    assert_response :success
    assert_nil JSON.parse(@response.body)['data']['search']
    assert_not_nil JSON.parse(@response.body)['errors']

    # Unpermissioned user searching for a team
    authenticate_with_user(u)
    post :create, params: { query: query, team: t1.slug }
    assert_response :success
    assert_nil JSON.parse(@response.body)['data']['search']
    assert_not_nil JSON.parse(@response.body)['errors']

    # Permissioned user searching for a team
    authenticate_with_user(u)
    post :create, params: { query: query, team: t2.slug }
    assert_response :success
    assert_not_nil JSON.parse(@response.body)['data']['search']
    assert_nil JSON.parse(@response.body)['errors']
  end

  test "should filter by user in ElasticSearch" do
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

  test "should filter by read in ElasticSearch" do
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
