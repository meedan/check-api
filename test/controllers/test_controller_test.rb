require_relative '../test_helper'

class TestControllerTest < ActionController::TestCase
  test "should confirm user by email if in test mode" do
    u = create_user provider: ''
    assert_nil u.confirmed_at
    get :confirm_user, email: u.email
    assert_response :success
    assert_not_nil u.reload.confirmed_at
  end

  test "should not confirm user by email if not in test mode" do
    Rails.stubs(:env).returns('development')
    u = create_user provider: ''
    assert_nil u.confirmed_at
    get :confirm_user, email: u.email
    assert_response 400
    assert_nil u.reload.confirmed_at
    Rails.unstub(:env)
  end

  test "should make team public if in test mode" do
    t = create_team private: true
    assert t.private
    get :make_team_public, slug: t.slug
    assert_response :success
    assert !t.reload.private
  end

  test "should not make team public if not in test mode" do
    Rails.stubs(:env).returns('development')
    t = create_team private: true
    assert t.private
    get :make_team_public, slug: t.slug
    assert_response 400
    assert t.reload.private
    Rails.unstub(:env)
  end

  test "should create user if in test mode" do
    assert_difference 'User.count' do
      get :new_user, email: random_email
    end
    assert_response :success
  end

  test "should not create user if not in test mode" do
    Rails.stubs(:env).returns('development')
    assert_no_difference 'User.count' do
      get :new_user, email: random_email
    end
    assert_response 400
    Rails.unstub(:env)
  end

  test "should create team if in test mode" do
    u = create_user
    assert_difference 'Team.count' do
      get :new_team, email: u.email
    end
    assert_response :success
  end

  test "should not create team if not in test mode" do
    u = create_user
    Rails.stubs(:env).returns('development')
    assert_no_difference 'Team.count' do
      get :new_team, email: u.email
    end
    assert_response 400
    Rails.unstub(:env)
  end

  test "should create project if in test mode" do
    t = create_team
    assert_difference 'Project.count' do
      get :new_project, team_id: t.id
    end
    assert_response :success
  end

  test "should not create project if not in test mode" do
    t = create_team
    Rails.stubs(:env).returns('development')
    assert_no_difference 'Project.count' do
      get :new_project, team_id: t.id
    end
    assert_response 400
    Rails.unstub(:env)
  end

  test "should create session if in test mode" do
    u = create_user
    get :new_session, email: u.email
    assert_response :success
  end

  test "should not create session if not in test mode" do
    u = create_user
    Rails.stubs(:env).returns('development')
    get :new_session, email: u.email
    assert_response 400
    Rails.unstub(:env)
  end

  test "should create source if in test mode" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u
    p = create_project team: t
    RequestStore.store[:disable_es_callbacks] = true
    get :new_source, email: u.email, team_id: t.id, project_id: p.id, name: 'Test'
    RequestStore.store[:disable_es_callbacks] = false
    assert_response :success
  end

  test "should not create source if not in test mode" do
    Rails.stubs(:env).returns('development')
    u = create_user
    t = create_team
    create_team_user team: t, user: u
    p = create_project team: t
    get :new_source, email: u.email, team_id: t.id, project_id: p.id, name: 'Test'
    assert_response 400
    Rails.unstub(:env)
  end

  test "should create claim if in test mode" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u
    p = create_project team: t
    RequestStore.store[:disable_es_callbacks] = true
    get :new_claim, email: u.email, team_id: t.id, project_id: p.id, quote: 'Test'
    RequestStore.store[:disable_es_callbacks] = false
    assert_response :success
  end

  test "should not create claim if not in test mode" do
    Rails.stubs(:env).returns('development')
    u = create_user
    t = create_team
    create_team_user team: t, user: u
    p = create_project team: t
    get :new_claim, email: u.email, team_id: t.id, project_id: p.id, quote: 'Test'
    assert_response 400
    Rails.unstub(:env)
  end

  test "should create link if in test mode" do
    url = random_url
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    u = create_user
    t = create_team
    create_team_user team: t, user: u
    p = create_project team: t
    RequestStore.store[:disable_es_callbacks] = true
    get :new_link, email: u.email, team_id: t.id, project_id: p.id, url: url
    RequestStore.store[:disable_es_callbacks] = false
    assert_response :success
  end

  test "should not create link if not in test mode" do
    url = random_url
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    Rails.stubs(:env).returns('development')
    u = create_user
    t = create_team
    create_team_user team: t, user: u
    p = create_project team: t
    get :new_link, email: u.email, team_id: t.id, project_id: p.id, url: url
    assert_response 400
    Rails.unstub(:env)
  end

  test "should create team project and two users if in test mode" do
    get :create_team_project_and_two_users
    assert_response :success
  end

  test "should not create team project and two users if not in test mode" do
    Rails.stubs(:env).returns('development')
    get :create_team_project_and_two_users
    assert_response 400
    Rails.unstub(:env)
  end

  test "should update suggested tags if in test mode" do
    t = create_team
    get :update_suggested_tags, team_id: t.id, tags: 'TAG'
    assert_response :success
  end

  test "should not update suggested tags if not in test mode" do
    t = create_team
    Rails.stubs(:env).returns('development')
    get :update_suggested_tags, team_id: t.id, tags: 'TAG'
    assert_response 400
    Rails.unstub(:env)
  end

  test "should set media status if in test mode" do
    url = random_url
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    u = create_user
    t = create_team
    create_team_user team: t, user: u
    p = create_project team: t
    pm = create_project_media project: p, current_user: u
    get :media_status, pm_id: pm.id, status: 'false'
    assert_response :success
  end

  test "should not set media status if not in test mode" do
    url = random_url
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    u = create_user
    t = create_team
    create_team_user team: t, user: u
    p = create_project team: t
    pm = create_project_media project: p, current_user: u
    Rails.stubs(:env).returns('development')
    get :media_status, pm_id: pm.id, status: 'false'
    assert_response 400
    Rails.unstub(:env)
  end

  test "should set media tag if in test mode" do
    url = random_url
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    u = create_user
    t = create_team
    create_team_user team: t, user: u
    p = create_project team: t
    pm = create_project_media project: p, current_user: u
    get :new_media_tag, email:u.email, pm_id: pm.id, tag: 'TAG'
    assert_response :success
  end

  test "should not set media tag if not in test mode" do
    url = random_url
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    u = create_user
    t = create_team
    create_team_user team: t, user: u
    p = create_project team: t
    pm = create_project_media project: p, current_user: u
    Rails.stubs(:env).returns('development')
    get :new_media_tag, email:u.email, pm_id: pm.id, tag: 'TAG'
    assert_response 400
    Rails.unstub(:env)
  end

  test "should create test API key if in test mode" do
    get :new_api_key
    assert_response :success
  end

  test "should not create test API key if not in test mode" do
    Rails.stubs(:env).returns('development')
    get :new_api_key
    assert_response 400
    Rails.unstub(:env)
  end
end
