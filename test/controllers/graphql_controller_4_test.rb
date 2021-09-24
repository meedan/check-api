require_relative '../test_helper'

class GraphqlController4Test < ActionController::TestCase
  def setup
    require 'sidekiq/testing'
    super
    @controller = Api::V1::GraphqlController.new
    RequestStore.store[:skip_cached_field_update] = false
    Sidekiq::Testing.fake!
    User.unstub(:current)
    Team.unstub(:current)
    User.current = nil
    Team.current = nil
    create_verification_status_stuff
    @t = create_team
    @u = create_user
    @tu = create_team_user team: @t, user: @u, role: 'admin'
    @p1 = create_project team: @t
    @p2 = create_project team: @t
    @p3 = create_project team: @t
    @ps = [@p1, @p2, @p3]
    @pm1 = create_project_media team: @t, disable_es_callbacks: false, project: @p1
    @pm2 = create_project_media team: @t, disable_es_callbacks: false, project: @p2
    @pm3 = create_project_media team: @t, disable_es_callbacks: false, project: @p3
    Sidekiq::Worker.drain_all
    sleep 1
    @pms = [@pm1, @pm2, @pm3]
    @ids = @pms.map(&:graphql_id).to_json
    authenticate_with_user(@u)
  end

  def teardown
    super
    Sidekiq::Worker.drain_all
  end

  test "should not bulk-send project medias to trash if not allowed" do
    u = create_user
    authenticate_with_user(u)
    @pms.each { |pm| assert_equal CheckArchivedFlags::FlagCodes::NONE, pm.archived }
    query = 'mutation { updateProjectMedias(input: { clientMutationId: "1", ids: ' + @ids + ', archived: 1 }) { ids, team { dbid } } }'
    post :create, params: { query: query, team: @t.slug }
    assert_response :success
    assert_error_message 'allowed'
    @pms.each { |pm| assert_equal CheckArchivedFlags::FlagCodes::NONE, pm.reload.archived }
  end

  test "should not bulk-send project medias to trash if there are more than 10.000 ids" do
    ids = []
    10001.times { ids << random_string }
    query = 'mutation { updateProjectMedias(input: { clientMutationId: "1", ids: ' + ids.to_json + ', archived: 1 }) { ids, team { dbid } } }'
    post :create, params: { query: query, team: @t.slug }
    assert_response 400
    assert_error_message 'maximum'
  end

  test "should bulk-send project medias to trash" do
    @pms.each { |pm| assert_equal CheckArchivedFlags::FlagCodes::NONE, pm.archived }
    @ps.each { |p| assert_equal 1, p.reload.medias_count }
    assert_search_finds_all({ archived: CheckArchivedFlags::FlagCodes::NONE })
    assert_search_finds_none({ archived: CheckArchivedFlags::FlagCodes::TRASHED })
    assert_equal 0, CheckPusher::Worker.jobs.size
    
    query = 'mutation { updateProjectMedias(input: { clientMutationId: "1", ids: ' + @ids + ', archived: 1 }) { ids, team { dbid } } }'
    post :create, params: { query: query, team: @t.slug }
    assert_response :success
    
    @pms.each { |pm| assert_equal CheckArchivedFlags::FlagCodes::TRASHED, pm.reload.archived }
    @ps.each { |p| assert_equal 0, p.reload.medias_count }
    assert_search_finds_all({ archived: CheckArchivedFlags::FlagCodes::TRASHED })
    assert_search_finds_none({ archived: CheckArchivedFlags::FlagCodes::NONE })
    assert_equal 1, CheckPusher::Worker.jobs.size
  end

  test "should not bulk-restore project medias from trash if not allowed" do
    u = create_user
    authenticate_with_user(u)
    @pms.each { |pm| pm.archived = CheckArchivedFlags::FlagCodes::TRASHED ; pm.save! }
    @pms.each { |pm| assert_equal CheckArchivedFlags::FlagCodes::TRASHED, pm.reload.archived }
    query = 'mutation { updateProjectMedias(input: { clientMutationId: "1", ids: ' + @ids + ', archived: 0 }) { ids, team { dbid } } }'
    post :create, params: { query: query, team: @t.slug }
    assert_response :success
    assert_error_message 'allowed'
    @pms.each { |pm| assert_equal CheckArchivedFlags::FlagCodes::TRASHED, pm.reload.archived }
  end

  test "should not bulk-restore project medias from trash if there are more than 10.000 ids" do
    ids = []
    10001.times { ids << random_string }
    query = 'mutation { updateProjectMedias(input: { clientMutationId: "1", ids: ' + ids.to_json + ', archived: 0 }) { ids, team { dbid } } }'
    post :create, params: { query: query, team: @t.slug }
    assert_response 400
    assert_error_message 'maximum'
  end

  test "should bulk-restore project medias from trash" do
    @pms.each { |pm| pm.archived = CheckArchivedFlags::FlagCodes::TRASHED ; pm.save! }
    Sidekiq::Worker.drain_all
    sleep 1
    @pms.each { |pm| assert_equal CheckArchivedFlags::FlagCodes::TRASHED, pm.reload.archived }
    @ps.each { |p| assert_equal 0, p.reload.medias_count }
    assert_search_finds_all({ archived: CheckArchivedFlags::FlagCodes::TRASHED })
    assert_search_finds_none({ archived: CheckArchivedFlags::FlagCodes::NONE })
    assert_equal 0, CheckPusher::Worker.jobs.size
    
    query = 'mutation { updateProjectMedias(input: { clientMutationId: "1", ids: ' + @ids + ', archived: 0 }) { ids, team { dbid } } }'
    post :create, params: { query: query, team: @t.slug }
    assert_response :success
    
    @pms.each { |pm| assert_equal CheckArchivedFlags::FlagCodes::NONE, pm.reload.archived }
    @ps.each { |p| assert_equal 1, p.reload.medias_count }
    assert_search_finds_all({ archived: CheckArchivedFlags::FlagCodes::NONE })
    assert_search_finds_none({ archived: CheckArchivedFlags::FlagCodes::TRASHED })
    assert_equal 1, CheckPusher::Worker.jobs.size
  end

  test "should bulk-restore project medias from trash and assign to list" do
    add_to = create_project team: @t
    @pms.each { |pm| pm.archived = CheckArchivedFlags::FlagCodes::TRASHED ; pm.save! }
    Sidekiq::Worker.drain_all
    sleep 1
    @pms.each { |pm| assert_equal CheckArchivedFlags::FlagCodes::TRASHED, pm.reload.archived }
    @ps.each { |p| assert_equal 0, p.reload.medias_count }
    assert_search_finds_all({ archived: CheckArchivedFlags::FlagCodes::TRASHED })
    assert_search_finds_none({ archived: CheckArchivedFlags::FlagCodes::NONE })
    assert_equal 0, CheckPusher::Worker.jobs.size

    query = 'mutation { updateProjectMedias(input: { clientMutationId: "1", ids: ' + @ids + ', archived: 0, project_id: ' + add_to.id.to_s + ' }) { ids, team { dbid } } }'
    post :create, params: { query: query, team: @t.slug }
    assert_response :success

    @pms.each { |pm| assert_equal CheckArchivedFlags::FlagCodes::NONE, pm.reload.archived }
    @ps.each { |p| assert_equal 0, p.reload.medias_count }
    assert_equal @pms.length, add_to.reload.medias_count
    assert_search_finds_all({ archived: CheckArchivedFlags::FlagCodes::NONE })
    assert_search_finds_none({ archived: CheckArchivedFlags::FlagCodes::TRASHED })
    assert_equal 2, CheckPusher::Worker.jobs.size
  end

  test "should not bulk-create tags if not allowed" do
    @tu.update_column(:role, 'collaborator')
    inputs = '{ tag: "test", annotated_type: "ProjectMedia", annotated_id: "0" }'
    query = 'mutation { createTags(input: { clientMutationId: "1", inputs: [' + inputs + '] }) { team { dbid } } }'
    assert_no_difference 'TagText.count' do
      assert_no_difference 'Tag.length' do
        post :create, params: { query: query, team: @t.slug }
        assert_response :success
        assert_error_message 'allowed'
      end
    end
  end

  test "should not bulk-create tags if there are more than 10.000 inputs" do
    inputs = '{ tag: "test", annotated_type: "ProjectMedia", annotated_id: "0" }, ' * 10001
    query = 'mutation { createTags(input: { clientMutationId: "1", inputs: [' + inputs.gsub(/, $/, '') + '] }) { team { dbid } } }'
    assert_no_difference 'TagText.count' do
      assert_no_difference 'Tag.length' do
        post :create, params: { query: query, team: @t.slug }
        assert_response 400
        assert_error_message 'maximum'
      end
    end
  end

  test "should bulk-create tags" do
    TagText.create! text: 'foo', team_id: @t.id
    c = create_comment annotated: @pm1
    pm4 = create_project_media
    query = 'mutation { createTags(input: { clientMutationId: "1", inputs: [{ tag: "foo", annotated_type: "ProjectMedia", annotated_id: "' + @pm1.id.to_s + '" }, { tag: "bar", annotated_type: "ProjectMedia", annotated_id: "' + @pm2.id.to_s + '" }, { tag: "foo", annotated_type: "ProjectMedia", annotated_id: "' + @pm3.id.to_s + '" }, { tag: "test", annotated_type: "ProjectMedia", annotated_id: "' + pm4.id.to_s + '" }, { tag: "bar", annotated_type: "Comment", annotated_id: "' + c.id.to_s + '" }]}) { team { dbid } } }'
    assert_difference 'TagText.count', 1 do
      assert_difference 'Tag.length', 3 do
        post :create, params: { query: query, team: @t.slug }
        assert_response :success
      end
    end
    assert_equal @t.id, JSON.parse(@response.body)['data']['createTags']['team']['dbid']
    assert_equal ['foo'], @pm1.reload.get_annotations('tag').map(&:load).map(&:tag_text)
    assert_equal ['bar'], @pm2.reload.get_annotations('tag').map(&:load).map(&:tag_text)
    assert_nothing_raised do
      Sidekiq::Worker.drain_all
    end
  end

  test "should bulk-assign project medias" do
    u = create_user
    create_team_user team: @t, user: u
    u1 = create_user
    create_team_user team: @t, user: u1
    u2 = create_user
    create_team_user team: @t, user: u2
    u3 = create_user
    status = @pm1.last_status_obj
    with_current_user_and_team(u, @t) do
        Assignment.create!(assigned_type: 'Annotation', assigned_id: status.id, user_id: u.id)
    end
    pm1_assignments = Annotation.joins(:assignments).where(
        'annotations.annotated_type' => 'ProjectMedia',
        'annotations.annotated_id' => @pm1.id,
        'annotations.annotation_type' => 'verification_status'
        ).count
    assert_equal 1, pm1_assignments
    assigned_to_ids = [u1.id, u2.id, u3.id].join(', ')
    assert_equal 1, @pm1.get_versions_log(['create_assignment']).size
    Sidekiq::Testing.inline! do
        query = 'mutation { updateProjectMedias(input: { clientMutationId: "1", ids: ' + @ids + ', assignment_message: "add custom message", assigned_to_ids: "' + assigned_to_ids + '" }) { ids, team { dbid } } }'
        assert_difference 'Assignment.count', 6 do
          post :create, params: { query: query, team: @t.slug }
          assert_response :success
        end
        pm1_assignments = Annotation.joins(:assignments).where(
            'annotations.annotated_type' => 'ProjectMedia',
            'annotations.annotated_id' => @pm1.id,
            'annotations.annotation_type' => 'verification_status'
            ).count
        assert_equal 3, pm1_assignments
        assert_equal 3, @pm1.get_versions_log(['create_assignment']).size
    end
  end

  test "should not bulk-move project medias from a list to another if not allowed" do
    u = create_user
    authenticate_with_user(u)
    p4 = create_project team: @t
    query = 'mutation { updateProjectMedias(input: { clientMutationId: "1", ids: ' + @ids + ', move_to: ' + p4.id.to_s + ' }) { team { dbid } } }'
    post :create, params: { query: query, team: @t.slug }
    assert_response :success
    assert_error_message 'allowed'
  end

  test "should not bulk-move project medias from a list to another if there are more than 10.000 ids" do
    ids = []
    10001.times { ids << random_string }
    p4 = create_project team: @t
    query = 'mutation { updateProjectMedias(input: { clientMutationId: "1", ids: ' + ids.to_json + ', move_to: ' + p4.id.to_s + ' }) { team { dbid } } }'
    post :create, params: { query: query, team: @t.slug }
    assert_response 400
    assert_error_message 'maximum'
  end

  test "should bulk-move project medias from a list to another" do
    inputs = []
    p4 = create_project team: @t
    pm1 = create_project_media project: create_project
    pm2 = create_project_media project: @p1
    # add similar items
    t_pm1 = create_project_media project: @pm1.project
    create_relationship source_id: @pm1.id, target_id: t_pm1.id 
    t2_pm1 = create_project_media project: @pm1.project
    create_relationship source_id: @pm1.id, target_id: t2_pm1.id
    t_pm2 = create_project_media project: @pm2.project
    create_relationship source_id: @pm2.id, target_id: t_pm2.id
    invalid_id_1 = Base64.encode64("ProjectMedia/0")
    invalid_id_2 = Base64.encode64("Project/#{pm1.id}")
    invalid_id_3 = random_string
    assert_equal 4, @p1.reload.medias_count
    assert_equal 2, @p2.reload.medias_count
    assert_equal 0, p4.reload.medias_count
    ids = []
    [@pm1.graphql_id, @pm2.graphql_id, pm1.graphql_id, pm2.graphql_id, invalid_id_1, invalid_id_2, invalid_id_3].each { |id| ids << id }
    query = "mutation { updateProjectMedias(input: { clientMutationId: \"1\", ids: #{ids.to_json}, move_to: #{p4.id} }) { team { dbid } } }"
    post :create, params: { query: query, team: @t.slug }
    assert_response :success
    assert_equal 0, @p1.reload.medias_count
    assert_equal 0, @p2.reload.medias_count
    assert_equal 6, p4.reload.medias_count
    # verify move similar items
    assert_equal p4.id, t_pm1.reload.project_id
    assert_equal p4.id, t2_pm1.reload.project_id
    assert_equal p4.id, t_pm2.reload.project_id
    # verify cached folder for main & similar items
    assert_equal p4.title, Rails.cache.read("check_cached_field:ProjectMedia:#{@pm1.id}:folder")
    assert_equal p4.title, Rails.cache.read("check_cached_field:ProjectMedia:#{@pm2.id}:folder")
    assert_equal p4.title, Rails.cache.read("check_cached_field:ProjectMedia:#{t_pm1.id}:folder")
    assert_equal p4.title, Rails.cache.read("check_cached_field:ProjectMedia:#{t2_pm1.id}:folder")
    assert_equal p4.title, Rails.cache.read("check_cached_field:ProjectMedia:#{t_pm2.id}:folder")
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

  test "should update project media source" do
    s = create_source team: @t
    s2 = create_source team: @t
    pm = create_project_media team: @t, source_id: s.id, skip_autocreate_source: false
    pm2 = create_project_media team: @t, source_id: s2.id, skip_autocreate_source: false
    assert_equal s.id, pm.source_id
    query = "mutation { updateProjectMedia(input: { clientMutationId: \"1\", id: \"#{pm.graphql_id}\", source_id: #{s2.id}}) { project_media { source { dbid, medias_count, medias(first: 10) { edges { node { dbid } } } } } } }"
    post :create, params: { query: query, team: @t.slug }
    assert_response :success
    data = JSON.parse(@response.body)['data']['updateProjectMedia']['project_media']
    assert_equal s2.id, data['source']['dbid']
    assert_equal 2, data['source']['medias_count']
    assert_equal 2, data['source']['medias']['edges'].size
  end

  test "should create related project media for source" do
    t = create_team
    pm = create_project_media team: t
    u = create_user
    create_team_user user: u, team: t, role: 'admin'
    authenticate_with_user(u)
    query = 'mutation create { createSource(input: { name: "new source", slogan: "new source", clientMutationId: "1", add_to_project_media_id: ' + pm.id.to_s + ' }) { source { dbid } } }'
    post :create, params: { query: query, team: t }
    assert_response :success
    source = JSON.parse(@response.body)['data']['createSource']['source']
    assert_equal pm.reload.source_id, source['dbid']
  end

  test "should search team sources by keyword" do
    t = create_team slug: 'sawy'
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    create_source team: t, name: 'keyword begining'
    create_source team: t, name: 'ending keyword'
    create_source team: t, name: 'in the KEYWORD middle'
    create_source team: t
    authenticate_with_user(u)
    query = 'query read { team(slug: "sawy") { sources(first: 1000) { edges { node { dbid } } } } }'
    post :create, params: { query: query }
    assert_response :success
    edges = JSON.parse(@response.body)['data']['team']['sources']['edges']
    assert_equal 4, edges.length
    query = 'query read { team(slug: "sawy") { sources(first: 1000, keyword: "keyword") { edges { node { dbid } } } } }'
    post :create, params: { query: query }
    assert_response :success
    edges = JSON.parse(@response.body)['data']['team']['sources']['edges']
    assert_equal 3, edges.length
  end

  test "should update last_active_at from users before a graphql request" do
    assert_nil @u.last_active_at
    query = "query { user(id: #{@u.id}) { last_active_at } }"
    post :create, params: { query: query }
    assert_response :success
    assert_not_nil JSON.parse(@response.body)['data']['user']['last_active_at']
    assert_not_nil @u.reload.last_active_at
  end

  test "should not get Smooch integrations if not permissioned" do
    t = create_team private: true
    b = create_team_bot login: 'smooch', set_approved: true
    app_id = random_string
    tbi = create_team_bot_installation team_id: t.id, user_id: b.id, settings: { smooch_app_id: app_id }
    u = create_user
    t2 = create_team
    create_team_user user: u, team: t2, role: 'admin'
    
    query = "query { team(slug: \"#{t.slug}\") { team_bot_installations(first: 1) { edges { node { smooch_enabled_integrations } } } } }"
    post :create, params: { query: query }
    assert_error_message 'Not Found'

    authenticate_with_user(u)
    post :create, params: { query: query }
    assert_error_message 'Not Found'
  end

  test "should get Smooch integrations if permissioned" do
    t = create_team private: true
    b = create_team_bot login: 'smooch', set_approved: true
    app_id = random_string
    tbi = create_team_bot_installation team_id: t.id, user_id: b.id, settings: { smooch_app_id: app_id }
    u = create_user
    create_team_user user: u, team: t, role: 'admin'
    
    authenticate_with_user(u)
    query = "query { team(slug: \"#{t.slug}\") { team_bot_installations(first: 1) { edges { node { smooch_enabled_integrations } } } } }"
    post :create, params: { query: query }
    assert_not_nil json_response.dig('data', 'team', 'team_bot_installations', 'edges', 0, 'node', 'smooch_enabled_integrations')
  end

  test "should remove Smooch integration if permissioned" do
    t = create_team private: true
    b = create_team_bot login: 'smooch', set_approved: true
    app_id = random_string
    tbi = create_team_bot_installation team_id: t.id, user_id: b.id, settings: { smooch_app_id: app_id }
    u = create_user
    create_team_user user: u, team: t, role: 'admin'
    
    authenticate_with_user(u)
    query = "mutation { smoochBotRemoveIntegration(input: { clientMutationId: \"1\", team_bot_installation_id: \"#{tbi.graphql_id}\", integration_type: \"whatsapp\" }) { team_bot_installation { smooch_enabled_integrations } } }"
    post :create, params: { query: query }
    assert_not_nil json_response.dig('data', 'smoochBotRemoveIntegration', 'team_bot_installation', 'smooch_enabled_integrations')
  end

  test "should not remove Smooch integration if not permissioned" do
    t = create_team private: true
    b = create_team_bot login: 'smooch', set_approved: true
    app_id = random_string
    tbi = create_team_bot_installation team_id: t.id, user_id: b.id, settings: { smooch_app_id: app_id }
    u = create_user
    t2 = create_team
    create_team_user user: u, team: t2, role: 'admin'
    query = "mutation { smoochBotRemoveIntegration(input: { clientMutationId: \"1\", team_bot_installation_id: \"#{tbi.graphql_id}\", integration_type: \"whatsapp\" }) { team_bot_installation { smooch_enabled_integrations } } }"
    
    post :create, params: { query: query }
    assert_error_message 'Not Found'

    authenticate_with_user(u)
    post :create, params: { query: query }
    assert_error_message 'Not Found'
  end

  test "should add Smooch integration if permissioned" do
    SmoochApi::IntegrationApi.any_instance.stubs(:create_integration).returns(nil)
    t = create_team private: true
    b = create_team_bot login: 'smooch', set_approved: true
    app_id = random_string
    tbi = create_team_bot_installation team_id: t.id, user_id: b.id, settings: { smooch_app_id: app_id }
    u = create_user
    create_team_user user: u, team: t, role: 'admin'
    
    authenticate_with_user(u)
    query = 'mutation { smoochBotAddIntegration(input: { clientMutationId: "1", team_bot_installation_id: "' + tbi.graphql_id + '", integration_type: "messenger", params: "{\"token\":\"abc\"}" }) { team_bot_installation { smooch_enabled_integrations } } }'
    post :create, params: { query: query }
    assert_not_nil json_response.dig('data', 'smoochBotAddIntegration', 'team_bot_installation', 'smooch_enabled_integrations')
  end

  test "should not add Smooch integration if not permissioned" do
    t = create_team private: true
    b = create_team_bot login: 'smooch', set_approved: true
    app_id = random_string
    tbi = create_team_bot_installation team_id: t.id, user_id: b.id, settings: { smooch_app_id: app_id }
    u = create_user
    t2 = create_team
    create_team_user user: u, team: t2, role: 'admin'
    query = 'mutation { smoochBotAddIntegration(input: { clientMutationId: "1", team_bot_installation_id: "' + tbi.graphql_id + '", integration_type: "messenger", params: "{\"token\":\"abc\"}" }) { team_bot_installation { smooch_enabled_integrations } } }'

    post :create, params: { query: query }
    assert_error_message 'Not Found'

    authenticate_with_user(u)
    post :create, params: { query: query }
    assert_error_message 'Not Found'
  end

  test "should get saved search filters" do
    t = create_team
    ss = create_saved_search team: t, filters: { foo: 'bar' }
    query = "query { team(slug: \"#{t.slug}\") { saved_searches(first: 1) { edges { node { filters } } } } }"
    post :create, params: { query: query }
    assert_equal '{"foo":"bar"}', JSON.parse(@response.body).dig('data', 'team', 'saved_searches', 'edges', 0, 'node', 'filters')
    assert_response :success
  end

  test "should search by report status" do
    setup_elasticsearch
    RequestStore.store[:skip_cached_field_update] = false
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    authenticate_with_user(u)

    # Published
    pm1 = create_project_media team: t, disable_es_callbacks: false
    r1 = publish_report(pm1)
    r1 = Dynamic.find(r1.id)
    r1.disable_es_callbacks = false
    r1.set_fields = { state: 'published' }.to_json
    r1.save!

    # Paused
    pm2 = create_project_media team: t, disable_es_callbacks: false
    r2 = publish_report(pm2)
    r2 = Dynamic.find(r2.id)
    r2.disable_es_callbacks = false
    r2.set_fields = { state: 'paused' }.to_json
    r2.save!

    # Not published
    pm3 = create_project_media team: t, disable_es_callbacks: false

    # Search
    sleep 10
    query = 'query CheckSearch { search(query: "{\"report_status\":[\"published\"]}") { medias(first: 20) { edges { node { dbid } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal [pm1.id], JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |e| e['node']['dbid'] }
  end

  test "should get a single bot installation" do
    t = create_team private: true
    b = create_team_bot login: 'smooch', set_approved: true
    app_id = random_string
    tbi = create_team_bot_installation team_id: t.id, user_id: b.id, settings: { smooch_app_id: app_id }
    u = create_user
    create_team_user user: u, team: t, role: 'admin'
    
    authenticate_with_user(u)
    query = "query { team(slug: \"#{t.slug}\") { team_bot_installation(bot_identifier: \"smooch\") { smooch_enabled_integrations(force: true) } } }"
    post :create, params: { query: query }
    assert_not_nil json_response.dig('data', 'team', 'team_bot_installation', 'smooch_enabled_integrations')
  end

  test "should search using OR or AND on PG" do
    t = create_team
    p1 = create_project team: t
    p2 = create_project team: t
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    authenticate_with_user(u)

    pm1 = create_project_media team: t, project: p1, read: true
    pm2 = create_project_media team: t, project: p2, read: false

    query = 'query CheckSearch { search(query: "{\"operator\":\"AND\",\"read\":true,\"projects\":[' + p2.id.to_s + ']}") { medias(first: 20) { edges { node { dbid } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal [], JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |e| e['node']['dbid'] }

    query = 'query CheckSearch { search(query: "{\"operator\":\"OR\",\"read\":true,\"projects\":[' + p2.id.to_s + ']}") { medias(first: 20) { edges { node { dbid } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal [pm1.id, pm2.id].sort, JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |e| e['node']['dbid'] }.sort
  end

  test "should search using OR or AND on ES" do
    setup_elasticsearch
    RequestStore.store[:skip_cached_field_update] = false
    t = create_team
    p1 = create_project team: t
    p2 = create_project team: t
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    authenticate_with_user(u)

    pm1 = create_project_media team: t, project: p1, read: true
    pm2 = create_project_media team: t, project: p2, read: false

    query = 'query CheckSearch { search(query: "{\"operator\":\"AND\",\"read\":[1],\"projects\":[' + p2.id.to_s + '],\"report_status\":\"unpublished\"}") { medias(first: 20) { edges { node { dbid } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal [], JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |e| e['node']['dbid'] }

    query = 'query CheckSearch { search(query: "{\"operator\":\"OR\",\"read\":[1],\"projects\":[' + p2.id.to_s + '],\"report_status\":\"unpublished\"}") { medias(first: 20) { edges { node { dbid } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal [pm1.id, pm2.id].sort, JSON.parse(@response.body)['data']['search']['medias']['edges'].collect{ |e| e['node']['dbid'] }.sort
  end

  test "should search by project" do
    t = create_team
    p = create_project team: t
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    authenticate_with_user(u)

    create_project_media team: t, project: nil, project_id: nil
    create_project_media project: p
    
    query = 'query CheckSearch { search(query: "{}") { medias(first: 20) { edges { node { dbid } } } } }'
    post :create, params: { query: query, team: t.slug }
    assert_response :success
    assert_equal 2, JSON.parse(@response.body)['data']['search']['medias']['edges'].size
  end

  test "should get Smooch newsletter information" do
    setup_smooch_bot(true)
    rss = '<rss version="1"><channel><title>x</title><link>x</link><description>x</description><item><title>x</title><link>x</link></item></channel></rss>'
    WebMock.stub_request(:get, 'http://test.com/feed.rss').to_return(status: 200, body: rss)
    u = create_user is_admin: true
    authenticate_with_user(u)
    query = "query { team(slug: \"#{@team.slug}\") { team_bot_installations(first: 1) { edges { node { smooch_newsletter_information } } } } }"
    post :create, params: { query: query }
    assert_response :success
    assert_not_nil json_response.dig('data', 'team', 'team_bot_installations', 'edges', 0, 'node', 'smooch_newsletter_information')
  end

  protected

  def assert_error_message(expected)
    assert_match /#{expected}/, JSON.parse(@response.body)['errors'][0]['message']
  end

  def search_results(filters)
    sleep 1
    $repository.search(query: { bool: { must: [{ term: filters }, { term: { team_id: @t.id } }] } }).results.collect{|i| i['annotated_id']}.sort
  end

  def assert_search_finds_all(filters)
    assert_equal @pms.map(&:id).sort, search_results(filters)
  end

  def assert_search_finds_none(filters)
    assert_equal [], search_results(filters)
  end
end
