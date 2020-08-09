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
    assert_queries (16) do
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
      create_account_source source: s, disable_es_callbacks: false
      m.times { create_comment annotated: pm, annotator: create_user, disable_es_callbacks: false }
    end
    create_project_media project: p, user: u, disable_es_callbacks: false
    pm = create_project_media project: p, disable_es_callbacks: false
    pm.archived = true
    pm.save!
    sleep 10

    query = 'query CheckSearch { search(query: "{\"projects\":[' + p.id.to_s + ']}") { id,medias(first:20){edges{node{id,dbid,url,quote,created_at,updated_at,metadata,log_count,overridden,pusher_channel,domain,permissions,last_status,last_status_obj{id,dbid},account{id,dbid},media{url,quote,embed_path,thumbnail_path,id},user{name,source{dbid,accounts(first:10000){edges{node{url,id}}},id},id},team{slug,id},tags(first:10000){edges{node{tag,id}}}}}}}}'

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
    assert_equal [pm1a.id, pm1b.id], results

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
    assert_equal [pm1b.id, pm1a.id], results

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
    query = 'query CheckSearch { search(query: "{\"keyword\":\"Test\", \"include_related_items\":true}") {number_of_results,medias(first:20){edges{node{dbid}}}}}'
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
    queries << 'query CheckSearch { search(query: "{\"range\": {\"created_at\":{\"start_time\":\"2019-05-19\",\"end_time\":\"2019-05-24\"},\"updated_at\":{\"start_time\":\"2019-05-20\",\"end_time\":\"2019-05-21\"},\"timezone\":\"America/Bahia\"}}") { id,medias(first:20){edges{node{dbid}}}}}'

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

  test "should get dynamic annotation field" do
    create_annotation_type_and_fields('Smooch User', { 'Id' => ['Text', false], 'App Id' => ['Text', false], 'Data' => ['JSON', false] })
    name = random_string
    phone = random_string
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'editor'
    p = create_project team: t
    pm = create_project_media project: p
    d = create_dynamic_annotation annotated: pm, annotation_type: 'smooch_user', set_fields: { smooch_user_id: random_string, smooch_user_app_id: random_string, smooch_user_data: { phone: phone, app_name: name }.to_json }.to_json
    authenticate_with_token
    query = 'query { dynamic_annotation_field(query: "{\"field_name\": \"smooch_user_data\", \"json\": { \"phone\": \"' + phone + '\", \"app_name\": \"' + name + '\" } }") { annotation { dbid } } }'
    post :create, query: query
    assert_response :success
    assert_equal d.id, JSON.parse(@response.body)['data']['dynamic_annotation_field']['annotation']['dbid']
  end

  test "should not get dynamic annotation field if does not have permission" do
    create_annotation_type_and_fields('Smooch User', { 'Id' => ['Text', false], 'App Id' => ['Text', false], 'Data' => ['JSON', false] })
    name = random_string
    phone = random_string
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'editor'
    p = create_project team: t
    pm = create_project_media project: p
    d = create_dynamic_annotation annotated: pm, annotation_type: 'smooch_user', set_fields: { smooch_user_id: random_string, smooch_user_app_id: random_string, smooch_user_data: { phone: phone, app_name: name }.to_json }.to_json
    authenticate_with_user(u)
    query = 'query { dynamic_annotation_field(query: "{\"field_name\": \"smooch_user_data\", \"json\": { \"phone\": \"' + phone + '\", \"app_name\": \"' + name + '\" } }") { annotation { dbid } } }'
    post :create, query: query
    assert_response :success
    assert_nil JSON.parse(@response.body)['data']['dynamic_annotation_field']
  end

  test "should not get dynamic annotation field if parameters do not match" do
    create_annotation_type_and_fields('Smooch User', { 'Id' => ['Text', false], 'App Id' => ['Text', false], 'Data' => ['JSON', false] })
    name = random_string
    phone = random_string
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'editor'
    p = create_project team: t
    pm = create_project_media project: p
    d = create_dynamic_annotation annotated: pm, annotation_type: 'smooch_user', set_fields: { smooch_user_id: random_string, smooch_user_app_id: random_string, smooch_user_data: { phone: phone, app_name: name }.to_json }.to_json
    authenticate_with_user(u)
    query = 'query { dynamic_annotation_field(query: "{\"field_name\": \"smooch_user_data\", \"json\": { \"phone\": \"' + phone + '\", \"app_name\": \"' + random_string + '\" } }") { annotation { dbid } } }'
    post :create, query: query
    assert_response :success
    assert_nil JSON.parse(@response.body)['data']['dynamic_annotation_field']
  end

  test "should handle user 2FA" do
    u = create_user password: 'test1234'
    t = create_team
    create_team_user team: t, user: u
    authenticate_with_user(u)
    u.two_factor
    # generate backup codes with valid uid
    query = "mutation generateTwoFactorBackupCodes { generateTwoFactorBackupCodes(input: { clientMutationId: \"1\", id: #{u.id} }) { success, codes } }"
    post :create, query: query, team: t.slug
    assert_response :success
    assert_equal 5, JSON.parse(@response.body)['data']['generateTwoFactorBackupCodes']['codes'].size
    # generate backup codes with invalid uid
    invalid_uid = u.id + rand(10..100)
    query = "mutation generateTwoFactorBackupCodes { generateTwoFactorBackupCodes(input: { clientMutationId: \"1\", id: #{invalid_uid} }) { success, codes } }"
    post :create, query: query, team: t.slug
    assert_response :success
    # Enable/Disable 2FA
    query = "mutation userTwoFactorAuthentication {userTwoFactorAuthentication(input: { clientMutationId: \"1\", id: #{u.id}, otp_required: #{true}, password: \"test1234\", qrcode: \"#{u.current_otp}\" }) { success }}"
    post :create, query: query, team: t.slug
    assert_response :success
    assert u.reload.otp_required_for_login?
    query = "mutation userTwoFactorAuthentication {userTwoFactorAuthentication(input: { clientMutationId: \"1\", id: #{u.id}, otp_required: #{false}, password: \"test1234\" }) { success }}"
    post :create, query: query, team: t.slug
    assert_response :success
    assert_not u.reload.otp_required_for_login?
    # Disable with invalid uid
    query = "mutation userTwoFactorAuthentication {userTwoFactorAuthentication(input: { clientMutationId: \"1\", id: #{invalid_uid}, otp_required: #{false}, password: \"test1234\" }) { success }}"
    post :create, query: query, team: t.slug
    assert_response :success
  end

  test "should handle nested error" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u
    authenticate_with_user(u)
    p = create_project team: t
    pm = create_project_media project: p
    RelayOnRailsSchema.stubs(:execute).raises(GraphQL::Batch::NestedError)
    query = "query GetById { project_media(ids: \"#{pm.id},#{p.id}\") { dbid } }"
    post :create, query: query, team: t.slug
    assert_response 400
    RelayOnRailsSchema.unstub(:execute)
  end

  test "should return project medias with provided URL that user has access to" do
    l = create_valid_media
    u = create_user
    t = create_team
    t2 = create_team
    create_team_user team: t, user: u
    create_team_user team: t2, user: u
    authenticate_with_user(u)
    p1 = create_project team: t
    p2 = create_project team: t2
    pm1 = create_project_media project: p1, media: l
    pm2 = create_project_media project: p2, media: l
    pm3 = create_project_media media: l
    query = "query GetById { project_medias(url: \"#{l.url}\", first: 10000) { edges { node { dbid } } } }"
    post :create, query: query, team: t.slug
    assert_response :success
    assert_equal [pm1.id, pm2.id].sort, JSON.parse(@response.body)['data']['project_medias']['edges'].collect{ |x| x['node']['dbid'] }.sort
  end

  test "should change role of bot" do
    u = create_user is_admin: true
    i = create_team_bot_installation
    authenticate_with_user(u)

    id = Base64.encode64("TeamUser/#{i.id}")
    query = 'mutation update { updateTeamUser(input: { clientMutationId: "1", id: "' + id + '", role: "journalist" }) { team_user { id } } }'
    post :create, query: query, team: i.team.slug
    assert_response :success
  end

  test "should return project medias when provided URL is not normalized and it exists on db" do
    url = 'http://www.atarde.uol.com.br/bahia/salvador/noticias/2089363-comunidades-recebem-caminhao-da-biometria-para-regularizacao-eleitoral'
    url_normalized = 'http://www.atarde.com.br/bahia/salvador/noticias/2089363-comunidades-recebem-caminhao-da-biometria-para-regularizacao-eleitoral'
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: '{"type":"media","data":{"url":"' + url_normalized + '","type":"item"}}')
    m = create_media url: url
    u = create_user
    t = create_team
    create_team_user team: t, user: u
    authenticate_with_user(u)
    p = create_project team: t
    pm = create_project_media project: p, media: m
    query = "query GetById { project_medias(url: \"#{url}\", first: 10000) { edges { node { dbid } } } }"
    post :create, query: query, team: t.slug
    assert_response :success
    assert_equal [pm.id], JSON.parse(@response.body)['data']['project_medias']['edges'].collect{ |x| x['node']['dbid'] }
  end

  test "should send GraphQL queries in batch" do
    u = create_user is_admin: true
    authenticate_with_user(u)
    t1 = create_team slug: 'batch-1', name: 'Batch 1'
    t2 = create_team slug: 'batch-2', name: 'Batch 2'
    t3 = create_team slug: 'batch-3', name: 'Batch 3'
    post :batch, _json: [
      { query: 'query { team(slug: "batch-1") { name } }', variables: {}, id: 'q1' },
      { query: 'query { team(slug: "batch-2") { name } }', variables: {}, id: 'q2' },
      { query: 'query { team(slug: "batch-3") { name } }', variables: {}, id: 'q3' }
    ]
    result = JSON.parse(@response.body)
    assert_equal 'Batch 1', result.find{ |t| t['id'] == 'q1' }['payload']['data']['team']['name']
    assert_equal 'Batch 2', result.find{ |t| t['id'] == 'q2' }['payload']['data']['team']['name']
    assert_equal 'Batch 3', result.find{ |t| t['id'] == 'q3' }['payload']['data']['team']['name']
  end

  test "should update tag" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'journalist'
    authenticate_with_user(u)
    p = create_project team: t
    pm = create_project_media project: p
    tg = create_tag annotated: pm
    id = Base64.encode64("Tag/#{tg.id}")
    query = 'mutation update { updateTag(input: { clientMutationId: "1", id: "' + id + '", fragment: "t=1,2" }) { tag { id } } }'
    post :create, query: query
    assert_response :success
  end

  test "should retrieve information for grid" do
    RequestStore.store[:skip_cached_field_update] = false
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
    pm.metadata = { title: random_string, description: random_string }; pm.save!
    create_dynamic_annotation(annotation_type: 'smooch', annotated: pm, set_fields: { smooch_data: '{}' }.to_json)
    pm2 = create_project_media project: p
    r = create_relationship source_id: pm.id, target_id: pm2.id
    create_dynamic_annotation(annotation_type: 'smooch', annotated: pm2, set_fields: { smooch_data: '{}' }.to_json)
    pm.metadata = { title: 'Title Test', description: 'Description Test' }; pm.save!

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
              requests_related_count
              related_count
              type
              status
              first_seen: created_at
              last_seen
            }
          }
        }
      }}
    '

    assert_queries 18, '=' do
      post :create, query: query, team: 'team'
    end

    assert_response :success
    result = JSON.parse(@response.body)['data']['search']
    assert_equal 1, result['number_of_results']
    assert_equal 1, result['medias']['edges'].size
    result['medias']['edges'].each do |pm_node|
      pm = pm_node['node']
      assert_equal 'Title Test', pm['title']
      assert_equal 'Description Test', pm['description']
      assert_equal 1, pm['related_count']
      assert_equal 'UploadedImage', pm['type']
      assert_not_equal pm['first_seen'], pm['last_seen']
      assert_equal 2, pm['requests_related_count']
    end
  end

  test "should get items that belong to multiple lists (from PostgreSQL)" do
    u = create_user is_admin: true
    authenticate_with_user(u)
    t = create_team
    p1 = create_project team: t
    p2 = create_project team: t
    p3 = create_project team: t

    pm1 = create_project_media project: p1, disable_es_callbacks: false
    create_project_media_project project_media: pm1, project: p2, disable_es_callbacks: false

    pm2 = create_project_media project: p2, disable_es_callbacks: false
    create_project_media_project project_media: pm2, project: p3, disable_es_callbacks: false

    pm3 = create_project_media project: p1, disable_es_callbacks: false
    create_project_media_project project_media: pm3, project: p3, disable_es_callbacks: false

    sleep 10

    query = 'query CheckSearch { search(query: "{}") { medias(first: 20) { edges { node { dbid } } } } }'
    post :create, query: query, team: t.slug
    assert_response :success
    results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }.sort
    assert_equal [pm1.id, pm2.id, pm3.id].sort, results

    query = 'query CheckSearch { search(query: "{\"projects\":[' + p1.id.to_s + ']}") { medias(first: 20) { edges { node { dbid } } } } }'
    post :create, query: query, team: t.slug
    assert_response :success
    results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }.sort
    assert_equal [pm1.id, pm3.id].sort, results

    query = 'query CheckSearch { search(query: "{\"projects\":[' + p2.id.to_s + ']}") { medias(first: 20) { edges { node { dbid } } } } }'
    post :create, query: query, team: t.slug
    assert_response :success
    results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }.sort
    assert_equal [pm1.id, pm2.id].sort, results

    query = 'query CheckSearch { search(query: "{\"projects\":[' + p3.id.to_s + ']}") { medias(first: 20) { edges { node { dbid } } } } }'
    post :create, query: query, team: t.slug
    assert_response :success
    results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }.sort
    assert_equal [pm2.id, pm3.id].sort, results
  end

  test "should get items that belong to multiple lists (from ElasticSearch)" do
    u = create_user is_admin: true
    authenticate_with_user(u)
    t = create_team
    p1 = create_project team: t
    p2 = create_project team: t
    p3 = create_project team: t

    pm1 = create_project_media project: p1, media: create_claim_media(quote: 'test 1'), disable_es_callbacks: false
    create_project_media_project project_media: pm1, project: p2, disable_es_callbacks: false

    pm2 = create_project_media project: p2, media: create_claim_media(quote: 'test 2'), disable_es_callbacks: false
    create_project_media_project project_media: pm2, project: p3, disable_es_callbacks: false

    pm3 = create_project_media project: p1, media: create_claim_media(quote: 'test 3'), disable_es_callbacks: false
    create_project_media_project project_media: pm3, project: p3, disable_es_callbacks: false

    sleep 10

    query = 'query CheckSearch { search(query: "{\"keyword\":\"test\"}") { medias(first: 20) { edges { node { dbid } } } } }'
    post :create, query: query, team: t.slug
    assert_response :success
    results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }.sort
    assert_equal [pm1.id, pm2.id, pm3.id].sort, results

    query = 'query CheckSearch { search(query: "{\"projects\":[' + p1.id.to_s + '],\"keyword\":\"test\"}") { medias(first: 20) { edges { node { dbid } } } } }'
    post :create, query: query, team: t.slug
    assert_response :success
    results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }.sort
    assert_equal [pm1.id, pm3.id].sort, results

    query = 'query CheckSearch { search(query: "{\"projects\":[' + p2.id.to_s + '],\"keyword\":\"test\"}") { medias(first: 20) { edges { node { dbid } } } } }'
    post :create, query: query, team: t.slug
    assert_response :success
    results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }.sort
    assert_equal [pm1.id, pm2.id].sort, results

    query = 'query CheckSearch { search(query: "{\"projects\":[' + p3.id.to_s + '],\"keyword\":\"test\"}") { medias(first: 20) { edges { node { dbid } } } } }'
    post :create, query: query, team: t.slug
    assert_response :success
    results = JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }.sort
    assert_equal [pm2.id, pm3.id].sort, results
  end

  test "should create project media project" do
    u = create_user is_admin: true
    authenticate_with_user(u)

    t = create_team
    p1 = create_project team: t
    p2 = create_project team: t
    pm = create_project_media project: p1

    query = 'mutation addToList { createProjectMediaProject(input: { clientMutationId: "1", project_id: ' + p2.id.to_s + ', project_media_id: ' + pm.id.to_s + ' }) { project_media_project { id } } }'
    assert_difference 'ProjectMediaProject.count' do
      post :create, query: query, team: t
    end
    assert_response :success
    assert_equal [p1.id, p2.id].sort, pm.reload.project_ids.sort
  end

  test "should destroy project media project" do
    u = create_user is_admin: true
    authenticate_with_user(u)

    t = create_team
    p = create_project team: t
    pm = create_project_media project: p
    pmp = pm.project_media_projects.last
    assert_not_nil pmp

    query = 'mutation { destroyProjectMediaProject(input: { clientMutationId: "1", id: "' + pmp.graphql_id + '" }) { deletedId } }'
    assert_difference 'ProjectMediaProject.count', -1 do
      post :create, query: query, team: t
    end
    assert_response :success
    assert_empty pm.reload.project_ids
  end

  test "should return cached value for dynamic annotation" do
    create_annotation_type_and_fields('Smooch User', { 'Data' => ['JSON', false] })
    d = create_dynamic_annotation annotation_type: 'smooch_user', set_fields: { smooch_user_data: { app_name: 'foo', identifier: 'bar' }.to_json }.to_json
    authenticate_with_token
    assert_nil ApiKey.current

    post :create, query: 'query Query { dynamic_annotation_field(only_cache: true, query: "{\"field_name\":\"smooch_user_data\",\"json\":{\"app_name\":\"foo\",\"identifier\":\"bar\"}}") { annotation { dbid } } }'
    assert_response :success
    assert_nil JSON.parse(@response.body)['data']['dynamic_annotation_field']

    post :create, query: 'query Query { dynamic_annotation_field(query: "{\"field_name\":\"smooch_user_data\",\"json\":{\"app_name\":\"foo\",\"identifier\":\"bar\"}}") { annotation { dbid } } }'
    assert_response :success
    assert_equal d.id, JSON.parse(@response.body)['data']['dynamic_annotation_field']['annotation']['dbid'].to_i

    query = { field_name: 'smooch_user_data', json: { app_name: 'foo', identifier: 'bar' } }.to_json
    cache_key = 'dynamic-annotation-field-' + Digest::MD5.hexdigest(query)
    Rails.cache.write(cache_key, DynamicAnnotation::Field.where(annotation_id: d.id, field_name: 'smooch_user_data').last&.id)

    post :create, query: 'query Query { dynamic_annotation_field(query: "{\"field_name\":\"smooch_user_data\",\"json\":{\"app_name\":\"foo\",\"identifier\":\"bar\"}}") { annotation { dbid } } }'
    assert_response :success
    assert_equal d.id, JSON.parse(@response.body)['data']['dynamic_annotation_field']['annotation']['dbid'].to_i
  end

  test "should return updated offset from PG" do
    RequestStore.store[:skip_cached_field_update] = false
    u = create_user is_admin: true
    authenticate_with_user(u)
    t = create_team
    p = create_project team: t
    pm1 = create_project_media project: p
    sleep 1
    pm2 = create_project_media project: p
    query = 'query CheckSearch { search(query: "{\"sort\":\"recent_activity\",\"id\":' + pm1.id.to_s + ',\"esoffset\":0,\"eslimit\":1}") {item_navigation_offset,medias(first:20){edges{node{dbid}}}}}'
    post :create, query: query, team: t.slug
    assert_response :success
    response = JSON.parse(@response.body)['data']['search']
    assert_equal pm1.id, response['medias']['edges'][0]['node']['dbid']
    assert_equal 1, response['item_navigation_offset']
  end

  test "should return updated offset from ES" do
    RequestStore.store[:skip_cached_field_update] = false
    u = create_user is_admin: true
    authenticate_with_user(u)
    t = create_team
    p = create_project team: t
    pm1 = create_project_media project: p
    create_relationship source_id: pm1.id, target_id: create_project_media(project: p).id
    pm2 = create_project_media project: p
    create_relationship source_id: pm2.id, target_id: create_project_media(project: p).id
    create_relationship source_id: pm2.id, target_id: create_project_media(project: p).id
    sleep 10
    query = 'query CheckSearch { search(query: "{\"sort\":\"related\",\"id\":' + pm1.id.to_s + ',\"esoffset\":0,\"eslimit\":1}") {item_navigation_offset,medias(first:20){edges{node{dbid}}}}}'
    post :create, query: query, team: t.slug
    assert_response :success
    response = JSON.parse(@response.body)['data']['search']
    assert_equal pm1.id, response['medias']['edges'][0]['node']['dbid']
    assert_equal 1, response['item_navigation_offset']
  end

  test "should return secondary items by type" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'owner'
    authenticate_with_user(u)
    p = create_project team: t
    p1 = create_project_media project: p
    p1a = create_project_media project: p
    p1b = create_project_media project: p
    create_relationship source_id: p1.id, target_id: p1a.id, relationship_type: { source: 'parent', target: 'child' }
    create_relationship source_id: p1.id, target_id: p1b.id, relationship_type: { source: 'full_video', target: 'clip' }
    p2 = create_project_media project: p
    p2a = create_project_media project: p
    p2b = create_project_media project: p
    create_relationship source_id: p2.id, target_id: p2a.id
    create_relationship source_id: p2.id, target_id: p2b.id, relationship_type: { source: 'full_video', target: 'clip' }
    post :create, query: "query { project_media(ids: \"#{p1.id},#{p.id}\") { secondary_items(source_type: \"full_video\", target_type: \"clip\", first: 10000) { edges { node { dbid } } } } }", team: t.slug
    assert_equal [p1b.id], JSON.parse(@response.body)['data']['project_media']['secondary_items']['edges'].collect{ |x| x['node']['dbid'] }
  end

  test "should set smooch user slack channel url in background" do
    Sidekiq::Testing.fake! do
        create_annotation_type_and_fields('Smooch User', {
            'Data' => ['JSON', false],
            'Slack Channel Url' => ['Text', true]
        })
        u = create_user
        t = create_team
        create_team_user team: t, user: u, role: 'owner'
        p = create_project team: t
        author_id = random_string
        set_fields = { smooch_user_data: { id: author_id }.to_json }.to_json
        d = create_dynamic_annotation annotated: p, annotation_type: 'smooch_user', set_fields: set_fields
        Sidekiq::Worker.drain_all
        assert_equal 0, Sidekiq::Worker.jobs.size
        authenticate_with_token
        url = random_url
        query = 'mutation { updateDynamic(input: { annotation_type: "smooch_user", clientMutationId: "1", id: "' + d.graphql_id + '", set_fields: "{\"smooch_user_slack_channel_url\":\"' + url + '\"}" }) { project { dbid } } }'
        post :create, query: query
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
        post :create, query: query
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
        post :create, query: query
        assert_response :success
    end
  end

  test "should check permission before setting Slack channel URL" do
    create_annotation_type_and_fields('Smooch User', {
      'Slack Channel Url' => ['Text', true]
    })
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    d = create_dynamic_annotation annotated: p, annotation_type: 'smooch_user'
    u2 = create_user
    authenticate_with_user(u2)
    query = 'mutation { smoochBotAddSlackChannelUrl(input: { clientMutationId: "1", id: "' + d.id.to_s + '", set_fields: "{\"smooch_user_slack_channel_url\":\"' + random_url+ '\"}" }) { annotation { dbid } } }'
    post :create, query: query
    assert_response 400
  end

  test "should delete tag" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'owner'
    authenticate_with_user(u)
    p = create_project team: t
    pm = create_project_media project: p
    tg = create_tag annotated: pm
    id = Base64.encode64("Tag/#{tg.id}")
    query = 'mutation destroy { destroyTag(input: { clientMutationId: "1", id: "' + id + '" }) { deletedId } }'
    post :create, query: query
    assert_response :success
  end

  test "should create relationship" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'owner'
    authenticate_with_user(u)
    pm1 = create_project_media team: t
    pm2 = create_project_media team: t
    assert_difference 'Relationship.count' do
      query = 'mutation { createRelationship(input: { clientMutationId: "1", source_id: ' + pm1.id.to_s + ', target_id: ' + pm2.id.to_s + ', relationship_type: "{\"source\":\"full_video\",\"target\":\"clip\"}" }) { relationship { dbid } } }'
      post :create, query: query
    end
    assert_response :success
  end

  test "should get statuses from team" do
    u = create_user is_admin: true
    t = create_team
    authenticate_with_user(u)
    query = "query { team(slug: \"#{t.slug}\") { verification_statuses } }"
    post :create, query: query
    assert_response :success
    assert_not_nil JSON.parse(@response.body)['data']['team']['verification_statuses']
  end

  test "should create comment with fragment" do
    u = create_user is_admin: true
    pm = create_project_media
    authenticate_with_user(u)
    query = 'mutation { createComment(input: { fragment: "t=10,20", annotated_type: "ProjectMedia", annotated_id: "' + pm.id.to_s + '", text: "Test" }) { comment { parsed_fragment } } }'
    assert_difference 'Comment.length', 1 do
      post :create, query: query, team: pm.team.slug
    end
    assert_response :success
    assert_equal({ 't' => [10, 20] }, JSON.parse(@response.body)['data']['createComment']['comment']['parsed_fragment'])
    assert_equal({ 't' => [10, 20] }, pm.get_annotations('comment').last.load.parsed_fragment)
  end

  test "should search by flag without likelihood" do
    create_flag_annotation_type
    u = create_user is_admin: true
    authenticate_with_user(u)
    t = create_team
    pm1 = create_project_media team: t, project: nil, disable_es_callbacks: false
    pm2 = create_project_media team: t, project: nil, disable_es_callbacks: false
    data = valid_flags_data(false)
    create_flag annotated: pm1, disable_es_callbacks: false, set_fields: data.to_json
    sleep 5
    query = 'query { search(query: "{\"dynamic\":{\"flag_name\":[\"adult\"]}}") { medias(first: 10000) { edges { node { dbid } } } } }'
    post :create, query: query, team: t.slug
    assert_response :success
    assert_equal [pm1.id], JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |pm| pm['node']['dbid'] }
  end

  test "should create tag and get tag text as parent" do
    u = create_user is_admin: true
    pm = create_project_media
    authenticate_with_user(u)
    query = 'mutation { createTag(input: { annotated_type: "ProjectMedia", annotated_id: "' + pm.id.to_s + '", tag: "Test" }) { tag_text_object { text } } }'
    assert_difference 'Tag.length', 1 do
      post :create, query: query, team: pm.team.slug
    end
    assert_response :success
    assert_equal 'Test', JSON.parse(@response.body)['data']['createTag']['tag_text_object']['text']
  end

  test "should get comments from media" do
    u = create_user is_admin: true
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p
    c = create_comment annotated: pm, fragment: 't=10,20'
    authenticate_with_user(u)
    query = "query { project_media(ids: \"#{pm.id},#{p.id}\") { comments(first: 10) { edges { node { parsed_fragment } } } } }"
    post :create, query: query, team: t.slug
    assert_response :success
    assert_equal({ 't' => [10, 20] }, JSON.parse(@response.body)['data']['project_media']['comments']['edges'][0]['node']['parsed_fragment'])
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
    post :create, query: query, team: t.slug
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
    post :create, query: query
    assert_response :success
    assert_nil JSON.parse(@response.body)['data']['search']
    assert_not_nil JSON.parse(@response.body)['errors']

    # Anonymous user searching for a public team
    post :create, query: query, team: t3.slug
    assert_response :success
    assert_not_nil JSON.parse(@response.body)['data']['search']
    assert_nil JSON.parse(@response.body)['errors']

    # Anonymous user searching for a team
    post :create, query: query, team: t1.slug
    assert_response :success
    assert_nil JSON.parse(@response.body)['data']['search']
    assert_not_nil JSON.parse(@response.body)['errors']

    # Unpermissioned user searching across all teams
    authenticate_with_user(u)
    post :create, query: query, team: t1.slug
    assert_response :success
    assert_nil JSON.parse(@response.body)['data']['search']
    assert_not_nil JSON.parse(@response.body)['errors']

    # Unpermissioned user searching for a team
    authenticate_with_user(u)
    post :create, query: query, team: t1.slug
    assert_response :success
    assert_nil JSON.parse(@response.body)['data']['search']
    assert_not_nil JSON.parse(@response.body)['errors']

    # Permissioned user searching for a team
    authenticate_with_user(u)
    post :create, query: query, team: t2.slug
    assert_response :success
    assert_not_nil JSON.parse(@response.body)['data']['search']
    assert_nil JSON.parse(@response.body)['errors']
  end

  test "should get nested comment" do
    u = create_user is_admin: true
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p
    c1 = create_comment annotated: pm, text: 'Parent'
    c2 = create_comment annotated: c1, text: 'Child'
    authenticate_with_user(u)
    query = %{
      query {
        project_media(ids: "#{pm.id},#{p.id}") {
          comments: annotations(first: 10000, annotation_type: "comment") {
            edges {
              node {
                ... on Comment {
                  id
                  text
                  comments: annotations(first: 10000, annotation_type: "comment") {
                    edges {
                      node {
                        ... on Comment {
                          id
                          text
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
    post :create, query: query, team: t.slug
    assert_response :success
    comments = JSON.parse(@response.body)['data']['project_media']['comments']['edges']
    assert_equal 1, comments.size
    assert_equal 'Parent', comments[0]['node']['text']
    child_comments = comments[0]['node']['comments']['edges']
    assert_equal 1, child_comments.size
    assert_equal 'Child', child_comments[0]['node']['text']
  end

  test "should create and retrieve clips" do
    json_schema = {
      type: 'object',
      required: ['label'],
      properties: {
        label: { type: 'string' }
      }
    }
    DynamicAnnotation::AnnotationType.reset_column_information
    create_annotation_type_and_fields('Clip', {}, json_schema)
    u = create_user is_admin: true
    p = create_project
    pm = create_project_media project: p
    authenticate_with_user(u)

    query = 'mutation { createDynamic(input: { annotation_type: "clip", annotated_type: "ProjectMedia", annotated_id: "' + pm.id.to_s + '", fragment: "t=10,20", set_fields: "{\"label\":\"Clip Label\"}" }) { dynamic { data, parsed_fragment } } }'
    assert_difference 'Annotation.where(annotation_type: "clip").count', 1 do
      post :create, query: query, team: pm.team.slug
    end
    assert_response :success
    annotation = JSON.parse(@response.body)['data']['createDynamic']['dynamic']
    assert_equal 'Clip Label', annotation['data']['label']
    assert_equal({ 't' => [10, 20] }, annotation['parsed_fragment'])

    query = %{
      query {
        project_media(ids: "#{pm.id},#{p.id}") {
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
    post :create, query: query, team: pm.team.slug
    assert_response :success
    clips = JSON.parse(@response.body)['data']['project_media']['clips']['edges']
    assert_equal 1, clips.size
    assert_equal 'Clip Label', clips[0]['node']['data']['label']
    assert_equal({ 't' => [10, 20] }, clips[0]['node']['parsed_fragment'])
  end

  test "should re-order tasks" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    pm = create_project_media project: p
    t1 = create_task annotated: pm
    t2 = create_task
    authenticate_with_user(u)
    tasks = '[{\"id\":' + "#{t1.id}" + ',\"order\":3},{\"id\":' + "#{t2.id}" + ',\"order\":2}, {\"id\":99999,\"order\":2}]'
    query = "mutation tasksOrder { tasksOrder(input: { clientMutationId: \"1\", tasks: \"#{tasks}\" }) { success, errors } }"
    post :create, query: query, team: t.slug
    assert_response :success
    assert_equal 3, t1.reload.order
    assert_equal 2, JSON.parse(@response.body)['data']['tasksOrder']['errors'].size
    query = "query GetById { task(id: \"#{t1.id}\") { dbid, order } }"
    post :create, query: query, team: t.slug
    assert_response :success
    assert 3, JSON.parse(@response.body)['data']['task']['order']
  end

  test "should get team user from user" do
    u = create_user
    t = create_team
    tu = create_team_user user: u, team: t
    authenticate_with_user(u)

    query = 'query { me { team_user(team_slug: "' + t.slug + '") { dbid } } }'
    post :create, query: query
    assert_response :success
    assert_equal tu.id, JSON.parse(@response.body)['data']['me']['team_user']['dbid']

    query = 'query { me { team_user(team_slug: "' + random_string + '") { dbid } } }'
    post :create, query: query
    assert_response :success
    assert_nil JSON.parse(@response.body)['data']['me']['team_user']
  end

  test "should create report with multiple images" do
    create_report_design_annotation_type
    u = create_user is_admin: true
    pm = create_project_media
    authenticate_with_user(u)
    path1 = File.join(Rails.root, 'test', 'data', 'rails.png')
    path2 = File.join(Rails.root, 'test', 'data', 'rails2.png')
    file1 = Rack::Test::UploadedFile.new(path1, 'image/png')
    file2 = Rack::Test::UploadedFile.new(path2, 'image/png')
    query = 'mutation create { createDynamic(input: { annotation_type: "report_design", action: "save", clientMutationId: "1", annotated_type: "ProjectMedia", annotated_id: "' + pm.id.to_s + '", set_fields: "{\"options\":[{\"language\":\"en\"},{\"language\":\"es\",\"image\":\"http://test.com/test.png\"},{\"language\":\"pt\"}]}" }) { dynamic { dbid } } }'
    post :create, query: query, file: { '2' => file2, '0' => file1 }
    assert_response :success
    d = Dynamic.find(JSON.parse(@response.body)['data']['createDynamic']['dynamic']['dbid']).data.with_indifferent_access
    assert_match /rails\.png/, d[:options][0]['image']
    assert_match /^http/, d[:options][1]['image']
    assert_match /rails2\.png/, d[:options][2]['image']
  end

  test "should update project media project without an id" do
    u = create_user is_admin: true
    authenticate_with_user(u)

    t = create_team
    p1 = create_project team: t
    p2 = create_project team: t
    pm = create_project_media project: p1
    assert_not_nil ProjectMediaProject.where(project_id: p1.id, project_media_id: pm.id).last
    assert_nil ProjectMediaProject.where(project_id: p2.id, project_media_id: pm.id).last

    query = 'mutation { updateProjectMediaProject(input: { clientMutationId: "1", previous_project_id: ' + p1.id.to_s + ', project_id: ' + p2.id.to_s + ', project_media_id: ' + pm.id.to_s + ' }) { project_media_project { id } } }'
    assert_no_difference 'ProjectMediaProject.count' do
      post :create, query: query, team: t
      assert_response :success
    end

    assert_nil ProjectMediaProject.where(project_id: p1.id, project_media_id: pm.id).last
    assert_not_nil ProjectMediaProject.where(project_id: p2.id, project_media_id: pm.id).last
  end

  test "should destroy project media project without an id" do
    u = create_user is_admin: true
    authenticate_with_user(u)

    t = create_team
    p = create_project team: t
    pm = create_project_media project: p
    assert_not_nil ProjectMediaProject.where(project_id: p.id, project_media_id: pm.id).last

    query = 'mutation { destroyProjectMediaProject(input: { clientMutationId: "1", project_id: ' + p.id.to_s + ', project_media_id: ' + pm.id.to_s + ' }) { deletedId } }'
    assert_difference 'ProjectMediaProject.count', -1 do
      post :create, query: query, team: t
      assert_response :success
    end

    assert_nil ProjectMediaProject.where(project_id: p.id, project_media_id: pm.id).last
  end

  test "should define team languages settings" do
    u = create_user is_admin: true
    authenticate_with_user(u)
    t = create_team
    t.set_language nil
    t.set_languages nil
    t.save!

    assert_nil t.reload.get_language
    assert_nil t.reload.get_languages

    query = 'mutation { updateTeam(input: { clientMutationId: "1", id: "' + t.graphql_id + '", language: "por" }) { team { id } } }'
    post :create, query: query, team: t.slug
    assert_response 400

    query = 'mutation { updateTeam(input: { clientMutationId: "1", id: "' + t.graphql_id + '", languages: "[\"por\"]" }) { team { id } } }'
    post :create, query: query, team: t.slug
    assert_response 400

    assert_nil t.reload.get_language
    assert_nil t.reload.get_languages

    query = 'mutation { updateTeam(input: { clientMutationId: "1", id: "' + t.graphql_id + '", language: "pt_BR", languages: "[\"es\", \"pt\"]" }) { team { id } } }'
    post :create, query: query, team: t.slug
    assert_response :success

    assert_equal 'pt_BR', t.reload.get_language
    assert_equal ['es', 'pt'], t.reload.get_languages
  end

  test "should define team custom statuses" do
    u = create_user is_admin: true
    authenticate_with_user(u)
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

    query = 'mutation { updateTeam(input: { clientMutationId: "1", id: "' + t.graphql_id + '", language: "pt_BR", media_verification_statuses: ' + custom_statuses.to_json.to_json + ' }) { team { id, verification_statuses_with_counters: verification_statuses(items_count: true, published_reports_count: true), verification_statuses } } }'
    post :create, query: query, team: t.slug
    assert_response :success
    data = JSON.parse(@response.body).dig('data', 'updateTeam', 'team')
    assert_match /items_count/, data['verification_statuses_with_counters'].to_json
    assert_no_match /items_count/, data['verification_statuses'].to_json
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
    post :create, query: query, team: t.slug

    assert_response :success
    assert_equal [pm.id], JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
  end

  test "should filter by user in PostgreSQL" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t
    pm = create_project_media team: t, user: u
    create_project_media team: t
    authenticate_with_user(u)

    query = 'query CheckSearch { search(query: "{\"users\":[' + u.id.to_s + ']}") { medias(first: 10) { edges { node { dbid } } } } }'
    post :create, query: query, team: t.slug

    assert_response :success
    assert_equal [pm.id], JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }
  end

  test "should get project using API key" do
    t = create_team
    a = create_api_key
    b = create_bot_user api_key_id: a.id, team: t
    p = create_project team: t
    authenticate_with_token(a)

    query = 'query { me { dbid } }'
    post :create, query: query, team: t.slug
    assert_response :success
    assert_equal b.id, JSON.parse(@response.body)['data']['me']['dbid']

    query = 'query { project(id: "' + p.id.to_s + '") { dbid } }'
    post :create, query: query, team: t.slug
    assert_response :success
    assert_equal p.id, JSON.parse(@response.body)['data']['project']['dbid']
  end

  test "should mark item as read" do
    pm = create_project_media
    assert !pm.reload.read
    u = create_user is_admin: true
    authenticate_with_user(u)

    assert_difference 'ProjectMediaUser.count' do
      query = 'mutation { createProjectMediaUser(input: { clientMutationId: "1", project_media_id: ' + pm.id.to_s + ', read: true }) { project_media { is_read } } }'
      post :create, query: query, team: pm.team.slug
      assert_response :success
      assert pm.reload.read

      query = 'mutation { createProjectMediaUser(input: { clientMutationId: "1", project_media_id: ' + pm.id.to_s + ', read: true }) { project_media { is_read } } }'
      post :create, query: query, team: pm.team.slug
      assert_response 400
    end
  end

  test "should return if item is read" do
    u = create_user is_admin: true
    t = create_team
    p = create_project team: t
    pm1 = create_project_media project: p
    ProjectMediaUser.create! user: u, project_media: pm1, read: true
    pm2 = create_project_media project: p
    ProjectMediaUser.create! user: create_user, project_media: pm2, read: true
    pm3 = create_project_media project: p
    authenticate_with_user(u)

    {
      pm1.id => [true, true],
      pm2.id => [true, false],
      pm3.id => [false, false]
    }.each do |id, values|
      ids = [id, p.id, t.id].join(',')
      query = 'query { project_media(ids: "' + ids + '") { read_by_someone: is_read, read_by_me: is_read(by_me: true) } }'
      post :create, query: query, team: t.slug
      assert_response :success
      data = JSON.parse(@response.body)['data']['project_media']
      assert_equal values[0], data['read_by_someone']
      assert_equal values[1], data['read_by_me']
    end
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

    query = 'query CheckSearch { search(query: "{\"keyword\":\"test\",\"read\":true}") { medias(first: 10) { edges { node { dbid } } } } }'
    post :create, query: query, team: t.slug
    assert_response :success
    assert_equal [pm1.id], JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }

    query = 'query CheckSearch { search(query: "{\"keyword\":\"test\",\"read\":false}") { medias(first: 10) { edges { node { dbid } } } } }'
    post :create, query: query, team: t.slug
    assert_response :success
    assert_equal [pm2.id], JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }

    query = 'query CheckSearch { search(query: "{\"keyword\":\"test\"}") { medias(first: 10) { edges { node { dbid } } } } }'
    post :create, query: query, team: t.slug
    assert_response :success
    assert_equal [pm1.id, pm2.id].sort, JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }.sort
  end

  test "should filter by read in PostgreSQL" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t
    pm1 = create_project_media team: t, read: true
    pm2 = create_project_media team: t
    pm3 = create_project_media
    authenticate_with_user(u)

    query = 'query CheckSearch { search(query: "{\"read\":true}") { medias(first: 10) { edges { node { dbid } } } } }'
    post :create, query: query, team: t.slug
    assert_response :success
    assert_equal [pm1.id], JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }

    query = 'query CheckSearch { search(query: "{\"read\":false}") { medias(first: 10) { edges { node { dbid } } } } }'
    post :create, query: query, team: t.slug
    assert_response :success
    assert_equal [pm2.id], JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }

    query = 'query CheckSearch { search(query: "{}") { medias(first: 10) { edges { node { dbid } } } } }'
    post :create, query: query, team: t.slug
    assert_response :success
    assert_equal [pm1.id, pm2.id].sort, JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |x| x['node']['dbid'] }.sort
  end

  test "should return version when updating dynamic" do
    u = create_user is_admin: true
    t = create_team
    create_team_user user: u, team: t
    json_schema = {
      type: 'object',
      properties: {
        test: { type: 'string' }
      }
    }
    create_annotation_type_and_fields('Test', {}, json_schema)
    pm = create_project_media team: t
    d = nil
    with_current_user_and_team(u, t) do
      d = create_dynamic_annotation annotated: pm, annotation_type: 'test', set_fields: { test: random_string }.to_json
    end
    authenticate_with_user(u)

    assert_difference 'Version.count' do
      query = 'mutation { updateDynamic(input: { clientMutationId: "1", id: "' + d.graphql_id + '", locked: true }) { version { dbid, object_changes_json, event_type }, versionEdge { node { dbid, object_changes_json, event_type } } } }'
      post :create, query: query, team: t.slug
      assert_response :success
      data = JSON.parse(@response.body)['data']['updateDynamic']
      vo = data['version']
      ve = data['versionEdge']['node']
      [vo, ve].each do |v|
        assert_equal Version.last.id, v['dbid']
        assert_equal 'update_dynamic', v['event_type']
        assert_equal({ 'locked' => [false, true] }, JSON.parse(v['object_changes_json']))
      end
    end
  end

  test "should return version when answering task" do
    u = create_user is_admin: true
    t = create_team
    pm = create_project_media team: t
    at = create_annotation_type annotation_type: 'task_response'
    create_field_instance annotation_type_object: at, name: 'response_test'
    tk = create_task annotated: pm
    authenticate_with_user(u)

    assert_difference 'Version.count', 2 do
      query = 'mutation { updateTask(input: { clientMutationId: "1", response: "{\"annotation_type\":\"task_response\",\"set_fields\":\"{\\\"response_test\\\":\\\"test\\\"}\"}", id: "' + tk.graphql_id + '" }) { version { event_type }, versionEdge { node { event_type } } } }'
      post :create, query: query, team: t.slug
      assert_response :success
      data = JSON.parse(@response.body)['data']['updateTask']
      assert_equal 'create_dynamicannotationfield', data['version']['event_type']
      assert_equal 'create_dynamicannotationfield', data['versionEdge']['node']['event_type']
    end
  end
end
