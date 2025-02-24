require_relative '../test_helper'

class GraphqlControllerTest < ActionController::TestCase
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
    @team = create_team
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
    pm1 = create_project_media project: nil, team: t
    s = pm1.annotations.where(annotation_type: 'verification_status').last.load
    s.status = 'id1'
    s.disable_es_callbacks = false
    s.save!
    r1 = publish_report(pm1)
    pm2 = create_project_media project: nil, team: t
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

  # Test CRUD operations for each model

  test "should create account source" do
    a = create_valid_account
    s = create_source
    assert_graphql_create('account_source', { account_id: a.id, source_id: s.id })
    url = random_url
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: '{"type":"media","data":{"url":"' + url + '","type":"profile"}}')
    assert_graphql_create('account_source', { source_id: s.id, url: url })
  end

  test "should create media" do
    p = create_project team: @team
    url = random_url
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    assert_graphql_create('project_media', { project_id: p.id, url: url, media_type: 'Link' })
    # create claim report
    assert_graphql_create('project_media', { project_id: p.id, media_type: 'Claim', quote: 'media quote', quote_attributions: {name: 'source name'}.to_json })
  end

  test "should create project media" do
    p = create_project team: @team
    m = create_valid_media
    assert_graphql_create('project_media', { media_id: m.id, project_id: p.id })
  end

  test "should read project media flag and source" do
    u = create_user is_admin: true
    authenticate_with_user(u)
    pm = create_project_media
    create_flag annotated: pm
    query = "query GetById { project_media(ids: \"#{pm.id},nil,#{pm.team_id}\") { source { id }, flags(first: 10) { edges { node { id } } }, annotation(annotation_type: \"flag\") { permissions, medias(first: 1) { edges { node { id } } } project_media { id } }, annotations(annotation_type: \"flag\") { edges { node { ... on Flag { id } } } } } }"
    post :create, params: { query: query, team: pm.team.slug }
    assert_response :success
  end

  test "should read project medias" do
    authenticate_with_user
    p = create_project team: @team
    tt = create_team_task team_id: @team.id, project_ids: [p.id], order: 2
    tt2 = create_team_task team_id: @team.id, project_ids: [p.id], order: 1
    pm = create_project_media project: p
    u = create_user name: 'The Annotator'
    create_team_user user: u, team: @team
    tg = create_tag annotated: pm, annotator: u
    tg.assign_user(u.id)
    query = "query GetById { project_media(ids: \"#{pm.id},#{p.id}\") { tasks { edges { node { dbid } } }, tasks_count, published, language, language_code, last_status_obj {dbid}, annotations(annotation_type: \"tag\") { edges { node { ... on Tag { dbid, assignments { edges { node { name } } }, annotator { user { name } } } } } } } }"
    post :create, params: { query: query, team: @team.slug }
    assert_response :success
    data = JSON.parse(@response.body)['data']['project_media']
    assert_not_empty data['published']
    assert_not_empty data['last_status_obj']['dbid']
    assert data.has_key?('language')
    assert data.has_key?('language_code')
    assert_equal 1, data['annotations']['edges'].size
    users = data['annotations']['edges'].collect{ |e| e['node']['annotator']['user']['name'] }
    assert users.include?('The Annotator')
    users = data['annotations']['edges'].collect{ |e| e['node']['assignments']['edges'][0]['node']['name'] }
    assert users.include?('The Annotator')
    # test task
    assert_equal 2, data['tasks']['edges'].size
    pm_tt = pm.annotations('task').select{|t| t.team_task_id == tt.id}.last
    pm_tt2 = pm.annotations('task').select{|t| t.team_task_id == tt2.id}.last
    assert_equal pm_tt2.id, data['tasks']['edges'][0]['node']['dbid'].to_i
    assert_equal pm_tt.id, data['tasks']['edges'][1]['node']['dbid'].to_i
  end

  test "should read project medias with team_id as argument" do
    authenticate_with_token
    p = create_project team: @team
    pm = create_project_media project: p
    query = "query GetById { project_media(ids: \"#{pm.id},#{p.id},#{@team.id}\") { published, language, last_status_obj {dbid} } }"
    post :create, params: { query: query }
    assert_response :success
    assert_not_empty JSON.parse(@response.body)['data']['project_media']['published']
    assert_not_empty JSON.parse(@response.body)['data']['project_media']['last_status_obj']['dbid']
    assert JSON.parse(@response.body)['data']['project_media'].has_key?('language')
  end

  test "should read project media and fallback to media" do
    authenticate_with_user
    p = create_project team: @team
    p2 = create_project team: @team
    pm = create_project_media project: p
    pm2 = create_project_media project: p2
    m2 = create_valid_media
    pm3 = create_project_media project: p, media: m2

    query = "query GetById { project_media(ids: \"#{pm3.id},#{p.id}\") { dbid } }"
    post :create, params: { query: query, team: @team.slug }
    assert_response :success
    assert_equal pm3.id, JSON.parse(@response.body)['data']['project_media']['dbid']

    query = "query GetById { project_media(ids: \"#{m2.id},#{p.id}\") { dbid } }"
    post :create, params: { query: query, team: @team.slug }
    assert_response :success
    assert_equal pm3.id, JSON.parse(@response.body)['data']['project_media']['dbid']

    query = "query GetById { project_media(ids: \"#{pm3.id},0,#{@team.id}\") { dbid } }"
    post :create, params: { query: query, team: @team.slug }
    assert_response :success
    assert_equal pm3.id, JSON.parse(@response.body)['data']['project_media']['dbid']
  end

  test "should read project media versions to find previous project" do
    with_versioning do
      authenticate_with_user
      p = create_project team: @team
      p2 = create_project team: @team
      pm = create_project_media project: p
      query = "query GetById { project_media(ids: \"#{pm.id},#{p.id}\") { dbid } }"
      post :create, params: { query: query, team: @team.slug }
      assert_response :success
      assert_equal pm.id, JSON.parse(@response.body)['data']['project_media']['dbid']
      pm.project_id = p2.id
      pm.save!
      query = "query GetById { project_media(ids: \"#{pm.id},#{p.id}\") { dbid } }"
      post :create, params: { query: query, team: @team.slug }
      assert_response :success
      assert_equal pm.id, JSON.parse(@response.body)['data']['project_media']['dbid']
    end
  end

  test "should create project" do
    assert_graphql_create('project', { title: 'test', description: 'test' })
  end

  test "should read project with team_id as argument" do
    authenticate_with_token
    p = create_project team: @team
    pm = create_project_media project: p
    query = "query GetById { project(ids: \"#{p.id},#{@team.id}\") { title, description} }"
    post :create, params: { query: query }
    assert_response :success
    assert_equal p.title, JSON.parse(@response.body)['data']['project']['title']
    assert_equal p.description, JSON.parse(@response.body)['data']['project']['description']
  end

  test "should update project" do
    assert_graphql_update('project', :title, 'foo', 'bar')
  end

  test "should destroy project" do
    Sidekiq::Testing.inline! do
      assert_graphql_destroy('project')
    end
  end

  test "should create source" do
    assert_graphql_create('source', { name: 'test', slogan: 'test' })
  end

  test "should update source" do
    assert_graphql_update('source', :name, 'foo', 'bar')
  end

  test "should create team" do
    assert_graphql_create('team', { name: 'test', description: 'test', slug: 'test' })
  end

  test "should update team" do
    assert_graphql_update('team', :name, 'foo', 'bar')
  end

  test "should destroy team" do
    Sidekiq::Testing.inline! do
      assert_graphql_destroy('team')
    end
  end

  test "should update user" do
    assert_graphql_update('user', :name, 'Foo', 'Bar')
  end

  test "should create tag" do
    p = create_project team: @team
    pm = create_project_media project: p
    assert_graphql_create('tag', { tag: 'egypt', annotated_type: 'ProjectMedia', annotated_id: pm.id.to_s })
  end

  test "should destroy tag" do
    assert_graphql_destroy('tag')
  end

  test "should get source by id" do
    assert_graphql_get_by_id('source', 'name', 'Test')
  end

  test "should get user by id" do
    assert_graphql_get_by_id('user', 'name', 'Test')
  end

  test "should get team by id" do
    assert_graphql_get_by_id('team', 'name', 'Test')
  end

  test "should get access denied on source by id" do
    authenticate_with_user
    s = create_source user: create_user
    query = "query GetById { source(id: \"#{s.id}\") { name } }"
    post :create, params: { query: query }
    assert_response 200
  end

  test "should refresh account" do
    u = create_user
    authenticate_with_user(u)
    url = "http://twitter.com/example#{Time.now.to_i}"
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias?url=' + url
    pender_refresh_url = CheckConfig.get('pender_url_private') + '/api/medias?refresh=1&url=' + url + '/'
    ret = { body: '{"type":"media","data":{"url":"' + url + '/","type":"profile"}}' }
    WebMock.stub_request(:get, pender_url).to_return(ret)
    WebMock.stub_request(:get, pender_refresh_url).to_return(ret)
    a = create_account user: u, url: url, team_id: @team.id
    PenderClient::Mock.mock_medias_returns_parsed_data(CheckConfig.get('pender_url_private')) do
      WebMock.disable_net_connect!
      id = a.graphql_id
      query = 'mutation update { updateAccount(input: { clientMutationId: "1", id: "' + id.to_s + '", refresh_account: 1 }) { account { id } } }'
      post :create, params: { query: query }
      assert_response :success
    end
  end

  test "should not get teams marked as deleted" do
    u = create_user
    t = create_team slug: 'team-to-be-deleted'
    create_team_user user: u, team: t, role: 'editor'

    authenticate_with_user(u)
    post :create, params: { query: 'query Team { team { name } }', team: 'team-to-be-deleted' }
    assert_response :success
    t.inactive = true; t.save
    post :create, params: { query: 'query Team { team { name } }', team: 'team-to-be-deleted' }
    assert_response :success
  end

  test "should not get projects from teams marked as deleted" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'editor'
    p = create_project team: t

    authenticate_with_user(u)
    query = "query GetById { project(id: \"#{p.id},#{t.id}\") { title } }"
    post :create, params: { query: query }
    assert_response :success
    assert_equal p.title, JSON.parse(@response.body)['data']['project']['title']

    t.inactive = true; t.save
    query = "query GetById { project(id: \"#{p.id},#{t.id}\") { title } }"
    post :create, params: { query: query }
    assert_response :success
  end

  test "should not get project medias from teams marked as deleted" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'editor'
    p = create_project team: t
    pm = create_project_media project: p

    authenticate_with_user(u)
    query = "query GetById { project_media(ids: \"#{pm.id},#{p.id}\") { dbid } }"
    post :create, params: { query: query }
    assert_response :success
    assert_equal pm.id, JSON.parse(@response.body)['data']['project_media']['dbid']

    t.inactive = true; t.save
    query = "query GetById { project_media(ids: \"#{pm.id},#{p.id}\") { dbid } }"
    post :create, params: { query: query }
    assert_response :success
  end

  test "should get project media annotations" do
    with_versioning do
      u = create_user
      authenticate_with_user(u)
      t = create_team slug: 'team'
      create_team_user user: u, team: t
      p = create_project team: t
      m = create_media
      pm = nil
      with_current_user_and_team(u, t) do
        pm = create_project_media project: p, media: m
        create_tag annotated: pm, annotator: u
        create_dynamic_annotation annotated: pm, annotator: u, annotation_type: 'metadata'
      end
      query = "query GetById { project_media(ids: \"#{pm.id},#{p.id}\") { last_status, domain, pusher_channel, account { url }, dbid, tags(first: 1) { edges { node { tag } } }, project { title }, log(first: 1000) { edges { node { event_type, object_after, updated_at, created_at, meta, object_changes_json, user { name }, annotation { id, created_at, updated_at }, task { id }, tag { id } } } } } }"
      post :create, params: { query: query, team: 'team' }
      assert_response :success
      assert_not_equal 0, JSON.parse(@response.body)['data']['project_media']['log']['edges'].size
    end
  end

  test "should get permissions for child objects" do
    u = create_user
    authenticate_with_user(u)
    t = create_team slug: 'team'
    create_team_user user: u, team: t
    p = create_project team: t
    pm = create_project_media project: p
    create_tag annotated: pm, annotator: u
    query = "query GetById { project(id: \"#{p.id}\") { project_medias(first: 1) { edges { node { permissions } } } } }"
    post :create, params: { query: query, team: 'team' }
    assert_response :success
    assert_not_equal '{}', JSON.parse(@response.body)['data']['project']['project_medias']['edges'][0]['node']['permissions']
  end

  test "should get team with statuses" do
    u = create_user
    authenticate_with_user(u)
    t = create_team slug: 'team'
    create_team_user user: u, team: t, role: 'admin'
    query = "query GetById { team(id: \"#{t.id}\") { verification_statuses } }"
    post :create, params: { query: query, team: 'team' }
    assert_response :success
  end

  test "should get project media team" do
    u = create_user
    authenticate_with_user(u)
    t = create_team slug: 'team'
    create_team_user user: u, team: t
    p = create_project team: t
    pm = create_project_media project: p
    query = "query GetById { project_media(ids: \"#{pm.id},#{p.id}\") { team { name }, public_team { name } } }"
    post :create, params: { query: query, team: 'team' }
    assert_response :success
    assert_equal t.name, JSON.parse(@response.body)['data']['project_media']['team']['name']
    assert_equal t.name, JSON.parse(@response.body)['data']['project_media']['public_team']['name']
  end

  test "should run few queries to get project data" do
    n = 18 # Number of media items to be created
    m = 5 # Number of annotations per media
    u = create_user
    authenticate_with_user(u)
    t = create_team slug: 'team'
    create_team_user user: u, team: t
    p = create_project team: t
    with_current_user_and_team(u, t) do
      n.times do
        pm = create_project_media project: p
        m.times {  create_tag annotated: pm, annotator: u }
      end
    end

    query = "query { project(id: \"#{p.id}\") { project_medias(first: 10000) { edges { node { permissions, log(first: 10000) { edges { node { permissions, annotation { permissions, medias { edges { node { id } } } } } }  } } } } } }"

    assert_queries 380, '<' do
      post :create, params: { query: query, team: 'team' }
    end

    assert_response :success
    assert_equal n, JSON.parse(@response.body)['data']['project']['project_medias']['edges'].size
  end

  test "should get node from global id for search" do
   authenticate_with_user
   options = {"keyword"=>"foo", "sort"=>"recent_added", "sort_type"=>"DESC"}.to_json
   id = Base64.strict_encode64("CheckSearch/#{options}")
   post :create, params: { query: "query Query { node(id: \"#{id}\") { id } }" }
   assert_equal id, JSON.parse(@response.body)['data']['node']['id']
 end

  test "should create project media with image" do
    create_bot name: 'Check Bot'
    u = create_user
    t = create_team
    create_team_user team: t, user: u
    p = create_project team: t
    authenticate_with_user(u)
    path = File.join(Rails.root, 'test', 'data', 'rails.png')
    file = Rack::Test::UploadedFile.new(path, 'image/png')
    query = 'mutation create { createProjectMedia(input: { media_type: "UploadedImage", url: "", quote: "", clientMutationId: "1", project_id: ' + p.id.to_s + ' }) { project_media { id } } }'
    assert_difference 'UploadedImage.count' do
      post :create, params: { query: query, file: file }
    end
    assert_response :success
  end

  test "should get ordered medias" do
    u = create_user
    authenticate_with_user(u)
    t = create_team slug: 'team'
    create_team_user user: u, team: t
    p = create_project team: t
    pms = []
    5.times do
      pms << create_project_media(project: p)
    end
    query = "query { project(id: \"#{p.id}\") { project_medias(first: 4) { edges { node { dbid } } } } }"

    post :create, params: { query: query, team: 'team' }

    assert_response :success
    assert_equal pms.last.dbid, JSON.parse(@response.body)['data']['project']['project_medias']['edges'].first['node']['dbid']
  end

  test "should get language from header" do
    authenticate_with_user
    @request.headers['Accept-Language'] = 'pt-BR'
    post :create, params: { query: 'query Query { me { name } }' }
    assert_equal :pt, I18n.locale
  end

  test "should get default if language is not supported" do
    authenticate_with_user
    @request.headers['Accept-Language'] = 'xx-XX'
    post :create, params: { query: 'query Query { me { name } }' }
    assert_equal :en, I18n.locale
  end

  test "should get closest language" do
    authenticate_with_user
    @request.headers['Accept-Language'] = 'xx-XX, fr-FR'
    post :create, params: { query: 'query Query { me { name } }' }
    assert_equal :fr, I18n.locale
  end

  test "should create dynamic annotation" do
    p = create_project team: @team
    pm = create_project_media project: p
    fields = { geolocation_viewport: '', geolocation_location: { type: "Feature", properties: { name: "Dingbat Islands" } , geometry: { type: "Point", coordinates: [125.6, 10.1] } }.to_json }.to_json
    assert_graphql_create('dynamic', { set_fields: fields, annotated_type: 'ProjectMedia', annotated_id: pm.id.to_s, annotation_type: 'geolocation' })
  end

  test "should not query invalid type" do
    u = create_user
    p = create_project team: @team
    create_team_user user: u, team: @team, role: 'admin'
    authenticate_with_user(u)
    id = Base64.encode64("InvalidType/#{p.id}")
    query = "mutation destroy { destroyProject(input: { clientMutationId: \"1\", id: \"#{id}\" }) { deletedId } }"
    post :create, params: { query: query, team: @team.slug }
    assert_response 400
  end

  test "should destroy project and assign related items to destination project" do
    u = create_user
    p = create_project team: @team
    p2 = create_project team: @team
    pm = create_project_media project: p
    create_team_user user: u, team: @team, role: 'admin'
    authenticate_with_user(u)
    query = "mutation destroy { destroyProject(input: { clientMutationId: \"1\", id: \"#{p.graphql_id}\", items_destination_project_id: #{p2.id} }) { deletedId } }"
    post :create, params: { query: query, team: @team.slug }
    assert_response :success
    assert_equal p.graphql_id, JSON.parse(response.body)['data']['destroyProject']['deletedId']
    assert_equal p2.id, pm.reload.project_id
  end

  test "should reset password if email is found" do
    u = create_user email: 'foo@bar.com'
    p = create_project team: @team
    create_team_user user: u, team: @team, role: 'admin'
    query = "mutation resetPassword { resetPassword(input: { clientMutationId: \"1\", email: \"foo@bar.com\" }) { success } }"
    post :create, params: { query: query, team: @team.slug }
    assert_response :success
  end

  test "should not reset password if email is not found" do
    u = create_user email: 'test@bar.com'
    p = create_project team: @team
    create_team_user user: u, team: @team, role: 'admin'
    query = "mutation resetPassword { resetPassword(input: { clientMutationId: \"1\", email: \"foo@bar.com\" }) { success } }"
    post :create, params: { query: query, team: @team.slug }
    assert_response :success
  end

  test "should resend confirmation" do
    u = create_user
    # Query with valid id
    query = "mutation resendConfirmation { resendConfirmation(input: { clientMutationId: \"1\", id: #{u.id} }) { success } }"
    post :create, params: { query: query, team: @team.slug }
    assert_response :success
    # Query with non existing ID
    id = rand(6 ** 6)
    query = "mutation resendConfirmation { resendConfirmation(input: { clientMutationId: \"1\", id: #{id} }) { success } }"
    post :create, params: { query: query, team: @team.slug }
    assert_response :success
  end

  test "should handle user invitations" do
    u = create_user
    authenticate_with_user(u)
    # send invitation
    members = '[{\"role\":\"collaborator\",\"email\":\"test1@local.com, test2@local.com\"},{\"role\":\"editor\",\"email\":\"test3@local.com\"}]'
    query = 'mutation userInvitation { userInvitation(input: { clientMutationId: "1", members: "'+ members +'" }) { errors } }'
    post :create, params: { query: query, team: @team.slug }
    assert_response :success
    # check invited by
    u = User.find_by_email 'test1@local.com'
    data = u.team_users.where(team_id: @team.id).last
    assert_equal User.current.id, data.invited_by_id
    # resend/cancel invitation
    query = 'mutation resendCancelInvitation { resendCancelInvitation(input: { clientMutationId: "1", email: "notexist@local.com", action: "resend" }) { success } }'
    post :create, params: { query: query, team: @team.slug }
    assert_response :success
    query = 'mutation resendCancelInvitation { resendCancelInvitation(input: { clientMutationId: "1", email: "test1@local.com", action: "resend" }) { success } }'
    post :create, params: { query: query, team: @team.slug }
    assert_response :success
    query = 'mutation resendCancelInvitation { resendCancelInvitation(input: { clientMutationId: "1", email: "test1@local.com", action: "cancel" }) { success } }'
    post :create, params: { query: query, team: @team.slug }
    assert_response :success
  end

  test "should handle delete user" do
    u = create_user
    authenticate_with_user(u)
    query = 'mutation deleteCheckUser { deleteCheckUser(input: { clientMutationId: "1", id: 111 }) { success } }'
    post :create, params: { query: query, team: @team.slug }
    assert_response :success
    query = "mutation deleteCheckUser { deleteCheckUser(input: { clientMutationId: \"1\", id: #{u.id} }) { success } }"
    post :create, params: { query: query, team: @team.slug }
    assert_response :success
  end

  test "should disconnect user login account" do
    u = create_user
    s = u.source
    omniauth_info = {"info"=> { "name" => "test" } }
    a = create_account source: s, user: u, provider: 'slack', uid: '123456', omniauth_info: omniauth_info
    authenticate_with_user(u)
    query = "mutation userDisconnectLoginAccount { userDisconnectLoginAccount(input: { clientMutationId: \"1\", provider: \"#{a.provider}\", uid: \"#{a.uid}\" }) { success } }"
    post :create, params: { query: query, team: @team.slug }
    assert_response :success
    User.stubs(:current).returns(nil)
    query = "mutation userDisconnectLoginAccount { userDisconnectLoginAccount(input: { clientMutationId: \"1\", provider: \"#{a.provider}\", uid: \"#{a.uid}\" }) { success } }"
    post :create, params: { query: query, team: @team.slug }
    assert_response :success
  end

  test "should change password if token is found and passwords are present and match" do
    p1 = random_complex_password
    u = create_user
    t = u.send_reset_password_instructions
    query = "mutation changePassword { changePassword(input: { clientMutationId: \"1\", reset_password_token: \"#{t}\", password: \"#{p1}\", password_confirmation: \"#{p1}\" }) { success } }"
    post :create, params: { query: query }
    sleep 1
    assert_response :success
    assert !JSON.parse(@response.body).has_key?('errors')
  end

  test "should not change password if token is not found and passwords are present and match" do
    p1 = random_complex_password
    u = create_user
    t = u.send_reset_password_instructions
    query = "mutation changePassword { changePassword(input: { clientMutationId: \"1\", reset_password_token: \"#{t}x\", password: \"#{p1}\", password_confirmation: \"#{p1}\" }) { success } }"
    post :create, params: { query: query }
    sleep 1
    assert_response 400
  end

  test "should not change password if token is found but passwords are not present" do
    p1 = random_complex_password
    u = create_user
    t = u.send_reset_password_instructions
    query = "mutation changePassword { changePassword(input: { clientMutationId: \"1\", reset_password_token: \"#{t}\", password: \"#{p1}\" }) { success } }"
    post :create, params: { query: query }
    sleep 1
    assert_response :success
    assert JSON.parse(@response.body).has_key?('errors')
  end

  test "should not change password if token is found but passwords do not match" do
    p1 = random_complex_password
    u = create_user
    t = u.send_reset_password_instructions
    query = "mutation changePassword { changePassword(input: { clientMutationId: \"1\", reset_password_token: \"#{t}\", password: \"#{p1}\", password_confirmation: \"12345678\" }) { success } }"
    post :create, params: { query: query }
    sleep 1
    assert_response 400
  end

  test "should access GraphQL if authenticated with API key" do
    authenticate_with_token
    assert_nil ApiKey.current
    post :create, params: { query: 'query Query { about { name, version } }' }
    assert_response :success
    assert_not_nil ApiKey.current
  end

  test "should get supported languages" do
    authenticate_with_user
    @request.headers['Accept-Language'] = 'pt-BR'
    post :create, params: { query: 'query Query { about { languages_supported } }' }
    assert_equal :pt, I18n.locale
    assert_response :success
    languages = JSON.parse(JSON.parse(@response.body)['data']['about']['languages_supported'])
    assert_equal 'Francês', languages['fr']
  end

  test "should get field value and dynamic annotation(s)" do
    authenticate_with_user
    p = create_project team: @team
    pm = create_project_media project: p
    a = create_dynamic_annotation annotation_type: 'verification_status', annotated: pm, set_fields: { verification_status_status: 'verified' }.to_json
    query = "query GetById { project_media(ids: \"#{pm.id},#{p.id}\") { annotation(annotation_type: \"verification_status\") { dbid }, field_value(annotation_type_field_name: \"verification_status:verification_status_status\"), annotations(annotation_type: \"verification_status\") { edges { node { ... on Dynamic { dbid } } } } } }"
    post :create, params: { query: query, team: @team.slug }
    assert_response :success
    data = JSON.parse(@response.body)['data']['project_media']
    assert_equal a.id, data['annotation']['dbid'].to_i
    assert_equal a.id, data['annotations']['edges'][0]['node']['dbid'].to_i
    assert_equal 'verified', data['field_value']
  end

  test "should create media with custom field" do
    authenticate_with_user
    p = create_project team: @team
    fields = '{\"annotation_type\":\"syrian_archive_data\",\"set_fields\":\"{\\\\\"syrian_archive_data_id\\\\\":\\\\\"123456\\\\\"}\"}'
    query = 'mutation create { createProjectMedia(input: { url: "", media_type: "Claim", quote: "Test", clientMutationId: "1", set_annotation: "' + fields + '", project_id: ' + p.id.to_s + ' }) { project_media { id } } }'
    post :create, params: { query: query, team: @team.slug }
    assert_response :success
    assert_equal '123456', ProjectMedia.last.get_annotations('syrian_archive_data').last.load.get_field_value('syrian_archive_data_id')
  end

  test "should manage auto tasks of a team" do
    u = create_user
    t = create_team
    create_team_task label: 'A', team_id: t.id
    id = t.graphql_id
    create_team_user user: u, team: t, role: 'admin'
    authenticate_with_user(u)
    assert_equal ['A'], t.team_tasks.map(&:label)
    task = '{\"fieldset\":\"tasks\",\"label\":\"B\",\"task_type\":\"free_text\",\"description\":\"\",\"options\":[]}'
    query = 'mutation { updateTeam(input: { clientMutationId: "1", id: "' + id + '", remove_auto_task: "A", add_auto_task: "' + task + '" }) { team { id } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal ['B'], t.reload.team_tasks.map(&:label)
  end

  test "should manage admin ui settings" do
    u = create_user
    t = create_team
    id = t.graphql_id
    create_team_user user: u, team: t, role: 'admin'
    authenticate_with_user(u)
    # media verification status
    statuses = {
      label: 'Field label',
      active: '2',
      default: '1',
      statuses: [
        { id: '1', locales: { en: { label: 'Custom Status 1', description: 'The meaning of this status' } }, style: { color: 'red' } },
        { id: '2', locales: { en: { label: 'Custom Status 2', description: 'The meaning of that status' } }, style: { color: 'blue' } },
        { id: '3', locales: { en: { label: 'Custom Status 3', description: 'The meaning of that status' } }, style: { color: 'green' } }
      ]
    }.to_json.gsub('"', '\"')
    query = 'mutation { updateTeam(input: { clientMutationId: "1", id: "' + id + '", media_verification_statuses: "' + statuses + '" }) { team { id } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal ["1", "2", "3"], t.reload.get_media_verification_statuses[:statuses].collect{ |t| t[:id] }.sort
    # add team tasks
    tasks = '[{\"fieldset\":\"tasks\",\"label\":\"A?\",\"description\":\"\",\"required\":\"\",\"type\":\"free_text\",\"mapping\":{\"type\":\"text\",\"match\":\"\",\"prefix\":\"\"}},{\"fieldset\":\"tasks\",\"label\":\"B?\",\"description\":\"\",\"required\":\"\",\"type\":\"single_choice\",\"options\":[{\"label\":\"A\"},{\"label\":\"B\"}],\"mapping\":{\"type\":\"text\",\"match\":\"\",\"prefix\":\"\"}}]'
    query = 'mutation { updateTeam(input: { clientMutationId: "1", id: "' + id + '", set_team_tasks: "' + tasks + '", report: "{}" }) { team { id } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal ['A?', 'B?'], t.reload.team_tasks.map(&:label).sort
    assert_equal({}, t.reload.get_report)
  end

  test "should read account sources from source" do
    u = create_user
    authenticate_with_user(u)
    s = create_source user: u
    create_account_source source_id: s.id
    query = "query GetById { source(id: \"#{s.id}\") { account_sources { edges { node { source { id }, account { id } } } } } }"
    post :create, params: { query: query }
    assert_response :success
  end

  test "should search for archived items" do
    RequestStore.store[:skip_delete_for_ever] = true
    u = create_user
    authenticate_with_user(u)
    t = create_team slug: 'team'
    create_team_user user: u, team: t
    p = create_project team: t
    2.times do
      pm = create_project_media project: p, disable_es_callbacks: false
      pm.archived = 1
      pm.save!
      sleep 1
    end

    query = 'query CheckSearch { search(query: "{\"archived\":1}") { id,medias(first:20){edges{node{id,dbid,url,quote,published,updated_at,pusher_channel,domain,permissions,last_status,last_status_obj{id,dbid},media{url,quote,embed_path,thumbnail_path,id},user{name,source{dbid,accounts(first:10000){edges{node{url,id}}},id},id},team{slug,id},tags(first:10000){edges{node{tag,id}}}}}}}}'

    post :create, params: { query: query, team: 'team' }

    assert_response :success
    assert_equal 2, JSON.parse(@response.body)['data']['search']['medias']['edges'].size
  end

  test "should search for single item" do
    u = create_user
    authenticate_with_user(u)
    t = create_team slug: 'team'
    create_team_user user: u, team: t
    p = create_project team: t
    pm = create_project_media project: p, disable_es_callbacks: false
    sleep 1

    query = 'query CheckSearch { search(query: "{}") { id,medias(first:20){edges{node{id,dbid,url,quote,published,updated_at,pusher_channel,domain,permissions,last_status,last_status_obj{id,dbid},media{url,quote,embed_path,thumbnail_path,id},user{name,source{dbid,accounts(first:10000){edges{node{url,id}}},id},id},team{slug,id},tags(first:10000){edges{node{tag,id}}}}}}}}'

    post :create, params: { query: query, team: 'team' }

    assert_response :success
    assert_equal 1, JSON.parse(@response.body)['data']['search']['medias']['edges'].size
  end

  test "should get core statuses with items count and published reports count" do
    u = create_user
    authenticate_with_user(u)
    t = create_team slug: 'team'
    DynamicAnnotation::Field.delete_all
    pm = create_project_media project: nil, team: t
    s = pm.annotations.where(annotation_type: 'verification_status').last.load
    s.status = 'false'
    s.save!
    2.times { publish_report(pm) }
    create_team_user user: u, team: t, role: 'admin'
    query = "query GetById { team(id: \"#{t.id}\") { verification_statuses(items_count_for_status: \"false\", published_reports_count_for_status: \"false\") } }"
    post :create, params: { query: query, team: 'team' }
    assert_response :success
    data = JSON.parse(@response.body)['data']['team']['verification_statuses']['statuses']
    assert_equal 1, data.select{ |s| s['id'] == 'false' }[0]['items_count']
    assert_equal 2, data.select{ |s| s['id'] == 'false' }[0]['published_reports_count']
  end

  test "should get custom statuses with items count and published reports count" do
    u = create_user
    authenticate_with_user(u)
    t = create_team slug: 'team'
    value = {
      label: 'Field label',
      active: '2',
      default: '1',
      statuses: [
        { id: '1', locales: { en: { label: 'Custom Status 1', description: 'The meaning of this status' } }, style: { color: 'red' } },
        { id: '2', locales: { en: { label: 'Custom Status 2', description: 'The meaning of that status' } }, style: { color: 'blue' } }
      ]
    }
    t.set_media_verification_statuses(value)
    t.save!
    DynamicAnnotation::Field.delete_all
    pm = create_project_media project: nil, team: t
    s = pm.annotations.where(annotation_type: 'verification_status').last.load
    s.status = '1'
    s.save!
    2.times { publish_report(pm) }
    create_team_user user: u, team: t, role: 'admin'
    query = "query GetById { team(id: \"#{t.id}\") { verification_statuses(items_count_for_status: \"1\", published_reports_count_for_status: \"1\") } }"
    post :create, params: { query: query, team: 'team' }
    assert_response :success
    data = JSON.parse(@response.body)['data']['team']['verification_statuses']['statuses']
    assert_equal 1, data.select{ |s| s['id'] == '1' }[0]['items_count']
    assert_equal 2, data.select{ |s| s['id'] == '1' }[0]['published_reports_count']
  end

  test "should create metadata field with conditionalInfo key in option" do
    u = create_user
    t = create_team
    id = t.graphql_id
    create_team_user user: u, team: t, role: 'admin'
    authenticate_with_user(u)
    tasks = '[{\"fieldset\":\"tasks\",\"label\":\"A?\",\"description\":\"\",\"required\":\"\",\"type\":\"free_text\",\"mapping\":{\"type\":\"text\",\"match\":\"\",\"prefix\":\"\"}},{\"fieldset\":\"tasks\",\"label\":\"B?\",\"description\":\"\",\"required\":\"\",\"type\":\"single_choice\",\"conditional_info\":\"{}\",\"options\":[{\"label\":\"A\"},{\"label\":\"B\"}],\"mapping\":{\"type\":\"text\",\"match\":\"\",\"prefix\":\"\"}}]'
    query = 'mutation { updateTeam(input: { clientMutationId: "1", id: "' + id + '", set_team_tasks: "' + tasks + '", report: "{}" }) { team { id } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
  end

  test "should have a base interface for GraphQL types" do
    assert_nothing_raised do
      class TestType < BaseObject
        implements BaseInterface
        field :test, ::BaseEnum.connection_type, null: false
      end
    end
  end
end
