require_relative '../test_helper'

class TestControllerTest < ActionController::TestCase
  test "should confirm user by email if in test mode" do
    u = create_user confirm: false
    assert_nil u.confirmed_at
    get :confirm_user, params: { email: u.email }
    assert_response :success
    assert_not_nil u.reload.confirmed_at
  end

  test "should not confirm user by email if not in test mode" do
    Rails.stubs(:env).returns('development')
    u = create_user confirm: false
    assert_nil u.confirmed_at
    get :confirm_user, params: { email: u.email }
    assert_response 400
    assert_nil u.reload.confirmed_at
    Rails.unstub(:env)
  end

  test "should make team public if in test mode" do
    t = create_team private: true
    assert t.private
    get :make_team_public, params: { slug: t.slug }
    assert_response :success
    assert !t.reload.private
  end

  test "should not make team public if not in test mode" do
    Rails.stubs(:env).returns('development')
    t = create_team private: true
    assert t.private
    get :make_team_public, params: { slug: t.slug }
    assert_response 400
    assert t.reload.private
    Rails.unstub(:env)
  end

  test "should create user if in test mode" do
    assert_difference 'User.count' do
      get :new_user, params: { email: random_email }
    end
    assert_response :success
  end

  test "should not create user if not in test mode" do
    Rails.stubs(:env).returns('development')
    assert_no_difference 'User.count' do
      get :new_user, params: { email: random_email }
    end
    assert_response 400
    Rails.unstub(:env)
  end

  test "should create team if in test mode" do
    u = create_user
    assert_difference 'Team.count' do
      get :new_team, params: { email: u.email }
    end
    assert_response :success
  end

  test "should not create team if not in test mode" do
    u = create_user
    Rails.stubs(:env).returns('development')
    assert_no_difference 'Team.count' do
      get :new_team, params: { email: u.email }
    end
    assert_response 400
    Rails.unstub(:env)
  end

  test "should create project if in test mode" do
    t = create_team
    assert_difference 'Project.count' do
      get :new_project, params: { team_id: t.id }
    end
    assert_response :success
  end

  test "should not create project if not in test mode" do
    t = create_team
    Rails.stubs(:env).returns('development')
    assert_no_difference 'Project.count' do
      get :new_project, params: { team_id: t.id }
    end
    assert_response 400
    Rails.unstub(:env)
  end

  test "should create session if in test mode" do
    u = create_user
    get :new_session, params: { email: u.email }
    assert_response :success
  end

  test "should not create session if not in test mode" do
    u = create_user
    Rails.stubs(:env).returns('development')
    get :new_session, params: { email: u.email }
    assert_response 400
    Rails.unstub(:env)
  end

  test "should create source if in test mode" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u
    RequestStore.store[:disable_es_callbacks] = true
    get :new_source, params: { email: u.email, team_id: t.id, name: 'Test', slogan: random_string }
    RequestStore.store[:disable_es_callbacks] = false
    assert_response :success
  end

  test "should not create source if not in test mode" do
    Rails.stubs(:env).returns('development')
    u = create_user
    t = create_team
    create_team_user team: t, user: u
    get :new_source, params: { email: u.email, team_id: t.id, name: 'Test', slogan: random_string }
    assert_response 400
    Rails.unstub(:env)
  end

  test "should create claim if in test mode" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u
    RequestStore.store[:disable_es_callbacks] = true
    get :new_claim, params: { email: u.email, team_id: t.id, quote: 'Test' }
    RequestStore.store[:disable_es_callbacks] = false
    assert_response :success
  end

  test "should not create claim if not in test mode" do
    Rails.stubs(:env).returns('development')
    u = create_user
    t = create_team
    create_team_user team: t, user: u
    get :new_claim, params: { email: u.email, team_id: t.id, quote: 'Test' }
    assert_response 400
    Rails.unstub(:env)
  end

  test "should create link if in test mode" do
    url = random_url
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    u = create_user
    t = create_team
    create_team_user team: t, user: u
    RequestStore.store[:disable_es_callbacks] = true
    get :new_link, params: { email: u.email, team_id: t.id, url: url }
    RequestStore.store[:disable_es_callbacks] = false
    assert_response :success
  end

  test "should not create link if not in test mode" do
    url = random_url
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    Rails.stubs(:env).returns('development')
    u = create_user
    t = create_team
    create_team_user team: t, user: u
    get :new_link, params: { email: u.email, team_id: t.id, url: url }
    assert_response 400
    Rails.unstub(:env)
  end

  test "should create team project and two users if in test mode" do
    get :create_team_project_and_two_users, params: {}
    assert_response :success
  end

  test "should not create team project and two users if not in test mode" do
    Rails.stubs(:env).returns('development')
    get :create_team_project_and_two_users, params: {}
    assert_response 400
    Rails.unstub(:env)
  end

  test "should update tag texts if in test mode" do
    t = create_team
    get :update_tag_texts, params: { team_id: t.id, tags: 'TAG' }
    assert_response :success
  end

  test "should not update tag texts if not in test mode" do
    t = create_team
    Rails.stubs(:env).returns('development')
    get :update_tag_texts, params: { team_id: t.id, tags: 'TAG' }
    assert_response 400
    Rails.unstub(:env)
  end

  test "should set media status if in test mode" do
    create_verification_status_stuff
    url = random_url
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    u = create_user
    t = create_team
    create_team_user team: t, user: u
    pm = create_project_media team: t, current_user: u
    get :media_status, params: { pm_id: pm.id, status: 'in_progress' }
    assert_response :success
  end

  test "should not set media status if not in test mode" do
    url = random_url
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    u = create_user
    t = create_team
    create_team_user team: t, user: u
    pm = create_project_media team: t, current_user: u
    Rails.stubs(:env).returns('development')
    get :media_status, params: { pm_id: pm.id, status: 'false' }
    assert_response 400
    Rails.unstub(:env)
  end

  test "should set media tag if in test mode" do
    url = random_url
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    u = create_user
    t = create_team
    create_team_user team: t, user: u
    pm = create_project_media team: t, current_user: u
    get :new_media_tag, params: { email:u.email, pm_id: pm.id, tag: 'TAG' }
    assert_response :success
  end

  test "should not set media tag if not in test mode" do
    url = random_url
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    u = create_user
    t = create_team
    create_team_user team: t, user: u
    pm = create_project_media team: t, current_user: u
    Rails.stubs(:env).returns('development')
    get :new_media_tag, params: { email: u.email, pm_id: pm.id, tag: 'TAG' }
    assert_response 400
    Rails.unstub(:env)
  end

  test "should create test API key if in test mode" do
    get :new_api_key, params: {}
    assert_response :success
  end

  test "should not create test API key if not in test mode" do
    Rails.stubs(:env).returns('development')
    get :new_api_key, params: {}
    assert_response 400
    Rails.unstub(:env)
  end

  test "should get object if in test mode" do
    t = create_team slug: 'test', name: 'Test'
    get :get, params: { class: 'team', id: t.id, fields: 'slug,name' }
    assert_response :success
    res = JSON.parse(@response.body)['data']
    assert_equal 'test', res['slug']
    assert_equal 'Test', res['name']
  end

  test "should not get object if not in test mode" do
    Rails.stubs(:env).returns('development')
    t = create_team slug: 'test', name: 'Test'
    get :get, params: { class: 'team', id: t.id, fields: 'slug,name' }
    assert_response 400
    Rails.unstub(:env)
  end

  test "should create task if in test mode" do
    url = random_url
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    u = create_user
    t = create_team
    create_team_user team: t, user: u
    pm = create_project_media team: t, current_user: u
    get :new_task, params: { email: u.email, pm_id: pm.id }
    assert_response :success
  end

  test "should not create task if not in test mode" do
    Rails.stubs(:env).returns('development')
    url = random_url
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    u = create_user
    t = create_team
    create_team_user team: t, user: u
    pm = create_project_media team: t, current_user: u
    get :new_task, params: { email: u.email, pm_id: pm.id }
    assert_response 400
    Rails.unstub(:env)
  end

  test "should create bot in test mode" do
    get :new_bot, params: {}
    assert_response :success
  end

  test "should not get user if e-mail parameter is not present" do
    u = create_bot_user
    t = create_team
    p = create_project
    get :new_claim, params: { team_id: t.id, quote: 'Test' }
    assert_response :success
    assert_nil User.current
  end

  test "should create team" do
    u = create_user
    assert_difference 'Team.count' do
      get :new_team, params: { email: u.email }
    end
    assert_response :success
  end

  test "should create dynamic annotation" do
    data = { phone: '123', app_name: 'Test' }.to_json
    p = create_project
    assert_difference 'Dynamic.count', 2 do
      get :new_dynamic_annotation, params: { set_action: 'deactivate', annotated_type: 'Project', annotated_id: p.id, annotation_type: 'smooch_user', fields: 'id,app_id,data', types: 'text,text,json', values: 'test,test,' + data }
    end
    assert_equal 'human_mode', CheckStateMachine.new('test').state.value
    assert_response :success
  end

  test "should not create dynamic annotation if not in test mode" do
    Rails.stubs(:env).returns('development')
    data = { phone: '123', app_name: 'Test' }.to_json
    p = create_project
    assert_no_difference 'Dynamic.count' do
      get :new_dynamic_annotation, params: { annotated_type: 'Project', annotated_id: p.id, annotation_type: 'smooch_user', fields: 'id,app_id,data', types: 'text,text,json', values: 'test,test,' + data }
    end
    assert_response 400
    Rails.unstub(:env)
  end

  test "should save cache entry" do
    key = random_string
    value = random_string
    get :new_cache_key, params: { key: key, value: value }
    assert_equal value, Rails.cache.read(key)
    assert_response :success
  end

  test "should not save cache entry if not in test mode" do
    Rails.stubs(:env).returns('development')
    key = random_string
    value = random_string
    get :new_cache_key, params: { key: key, value: value }
    assert_nil Rails.cache.read(key)
    assert_response 400
    Rails.unstub(:env)
  end

  test "should create team task and metadata if in test mode" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u
    get :new_team_data_field, params: { team_id: t.id, fieldset: 'tasks' }
    assert_response :success
    get :new_team_data_field, params: { team_id: t.id, fieldset: 'metadata' }
    assert_response :success
  end

  test "should not create team task and metadata if not in test mode" do
    Rails.stubs(:env).returns('development')
    u = create_user
    t = create_team
    create_team_user team: t, user: u
    get :new_team_data_field, params: { team_id: t.id, fieldset: 'tasks' }
    assert_response 400
    get :new_team_data_field, params: { team_id: t.id, fieldset: 'metadata' }
    assert_response 400
    Rails.unstub(:env)
  end

  test "should create similarity items" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u
    pm1 = create_project_media team: t
    pm2 = create_project_media team: t
    pm3 = create_project_media team: t
    get :suggest_similarity_item, params: { pm1: pm1, pm2: pm2, team_id: t.id }
    get :suggest_similarity_item, params: { pm1: pm1, pm2: pm3, team_id: t.id }
    assert_response 200
    assert pm1.targets.include? pm2
    assert pm1.targets.include? pm3
    assert_equal [pm1], pm2.sources
    assert_equal [pm1], pm3.sources
  end

  test "should not create similarity items if not in test mode" do
    Rails.stubs(:env).returns('development')
    u = create_user
    t = create_team
    create_team_user team: t, user: u
    pm1 = create_project_media team: t
    pm2 = create_project_media team: t
    pm3 = create_project_media team: t
    get :suggest_similarity_item, params: { pm1: pm1, pm2: pm2, team_id: t.id }
    get :suggest_similarity_item, params: { pm1: pm1, pm2: pm3, team_id: t.id }
    assert_response 400
    assert_not pm1.targets.include? pm2
    assert_not pm1.targets.include? pm3
    assert_equal [], pm2.sources
    assert_equal [], pm3.sources
    assert_equal [], pm1.sources
    Rails.unstub(:env)
  end

  test "should install bot" do
    t = create_team
    assert_difference 'TeamBotInstallation.count' do
      get :install_bot, params: { slug: t.slug, bot: 'smooch' }
    end
    assert_response 200
  end

  test "should not install bot if not in test mode" do
    Rails.stubs(:env).returns('development')
    t = create_team
    assert_no_difference 'TeamBotInstallation.count' do
      get :install_bot, params: { slug: t.slug, bot: 'smooch' }
    end
    assert_response 400
    Rails.unstub(:env)
  end

  test "should add team user if in test mode" do
    u = create_user
    t = create_team
    get :add_team_user, params: { email: u.email, slug: t.slug, role: 'editor' }
    assert_response :success
  end

  test "should not add team user if not in test mode" do
    Rails.stubs(:env).returns('development')
    u = create_user
    t = create_team
    get :add_team_user, params: { email: u.email, slug: t.slug, role: 'editor' }
    assert_response 400
    Rails.unstub(:env)
  end

  test "should create standalone fact check and associate with the team" do
    # Test setup
    team = create_team
    user = create_user
    create_team_user(user: user, team: team)

    assert_difference 'FactCheck.count' do
      get :create_imported_standalone_fact_check, params: {
        team_id: team.id,
        email: user.email,
        description: 'Test description',
        context: 'Test context',
        title: 'Test title',
        summary: 'Test summary',
        url: 'http://example.com',
        language: 'en'
      }
    end

    assert_response :success
  end

  test "should create saved search list" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u

    assert_difference 'SavedSearch.count' do
      get :create_saved_search_list, params: { team_id: t.id }
    end

    assert_response :success
  end

  test "should not create saved search list if not in test mode" do
    Rails.stubs(:env).returns('development')
    u = create_user
    t = create_team
    create_team_user team: t, user: u

    assert_no_difference 'SavedSearch.count' do
      get :create_saved_search_list, params: { team_id: t.id }
    end

    assert_response 400
    Rails.unstub(:env)
  end

  test "should create feed with item" do
    u = create_user
    t = create_team

    assert_difference 'Feed.count' do
      get :create_feed_with_item, params: { team_id: t.id, email: u.email }
    end

    assert_response :success
  end

  test "should not create feed with item if not in test mode" do
    Rails.stubs(:env).returns('development')
    u = create_user
    t = create_team

    assert_no_difference 'Feed.count' do
      get :create_feed_with_item, params: { team_id: t.id }
    end

    assert_response 400
    Rails.unstub(:env)
  end

  test "should create feed invitation" do
    u = create_user
    u2 = create_user
    t = create_team
    create_team_user team: t, user: u

    assert_difference 'FeedInvitation.count' do
      get :create_feed_invitation, params: { team_id: t.id, email: u2.email, email2: u.email }
    end

    assert_response :success
  end

  test "should not create feed invitation if not in test mode" do
    Rails.stubs(:env).returns('development') # Simulate non-test mode
    u = create_user
    u2 = create_user
    t = create_team
    create_team_user team: t, user: u

    assert_no_difference 'FeedInvitation.count' do
      get :create_feed_invitation, params: { team_id: t.id, email: u2.email, email2: u.email }
    end

    assert_response 400
    Rails.unstub(:env)
  end

  test "should not create standalone fact check and associate with the team" do
    Rails.stubs(:env).returns('development')

    # Test setup
    team = create_team
    user = create_user
    create_team_user(user: user, team: team)

    assert_no_difference 'FactCheck.count' do
      get :create_imported_standalone_fact_check, params: {
        team_id: team.id,
        email: user.email,
        description: 'Test description',
        context: 'Test context',
        title: 'Test title',
        summary: 'Test summary',
        url: 'http://example.com',
        language: 'en'
      }
    end

    assert_response 400
    Rails.unstub(:env)
  end

  test "should get a random number in HTML" do
    get :random
    assert_response :success
    assert_match /Test [0-9]+/, @response.body
  end
end
