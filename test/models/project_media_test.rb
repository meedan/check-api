require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class ProjectMediaTest < ActiveSupport::TestCase
  def setup
    super
    require 'sidekiq/testing'
    Sidekiq::Testing.fake!
  end

  test "should create project media" do
    assert_difference 'ProjectMedia.count' do
      create_project_media
    end
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    m = create_valid_media
    User.stubs(:current).returns(u)
    Team.stubs(:current).returns(t)
    assert_difference 'ProjectMedia.count' do
      create_project_media project: p, media: m
    end
    # journalist should assign any media
    Rails.cache.clear
    tu.update_column(:role, 'journalist')
    assert_difference 'ProjectMedia.count' do
      pm = create_project_media project: p, media: m
      assert_raise RuntimeError do
        pm.project = create_project team: t
        pm.save!
      end
    end
    m2 = create_valid_media
    m2.user_id = u.id; m2.save!
    assert_difference 'ProjectMedia.count' do
      pm = create_project_media project: p, media: m2
      pm.project = create_project team: t
      pm.save!
    end
    User.unstub(:current)
    Team.unstub(:current)
  end

  test "should have a project and media" do
    assert_no_difference 'ProjectMedia.count' do
      assert_raise ActiveRecord::RecordInvalid do
        create_project_media project: nil
      end
      assert_raise ActiveRecord::RecordInvalid do
        create_project_media media: nil
      end
    end
  end

  test "should create media if url or quote set" do
    assert_difference 'ProjectMedia.count', 2 do
      create_project_media media: nil, quote: 'Claim report'
      create_project_media media: nil, url: 'http://test.com'
    end
  end

  test "should find media by normalized url" do
    url = 'http://test.com'
    pender_url = CONFIG['pender_host'] + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m = create_media url: url
    url2 = 'http://test2.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url2 } }).to_return(body: response)
    pm = create_project_media url: url2
    assert_equal pm.media, m
  end

  test "should create with exisitng media if url exists" do
    m = create_valid_media
    pm = create_project_media media: nil, url: m.url
    assert_equal m, pm.media
  end

  test "should update and destroy project media" do
    u = create_user
    t = create_team
    p = create_project team: t
    p2 = create_project team: t
    m = create_valid_media user_id: u.id
    create_team_user team: t, user: u
    pm = create_project_media project: p, media: m
    with_current_user_and_team(u, t) do
      pm.project_id = p2.id; pm.save!
      pm.reload
      assert_equal pm.project_id, p2.id
    end
    u2 = create_user
    tu = create_team_user team: t, user: u2, role: 'journalist'
    assert_raise RuntimeError do
      with_current_user_and_team(u2, t) do
        pm.save!
      end
    end
    assert_raise RuntimeError do
      with_current_user_and_team(u2, t) do
        pm.destroy!
      end
    end
    pm_own = nil
    with_current_user_and_team(u2, t) do
      own_media = create_valid_media user: u2
      pm_own = create_project_media project: p, media: own_media, user: u2
      pm_own.project_id = p2.id; pm_own.save!
      pm_own.reload
      assert_equal pm_own.project_id, p2.id
    end
    assert_nothing_raised RuntimeError do
      with_current_user_and_team(u2, t) do
        pm_own.destroy!
      end

      with_current_user_and_team(u, t) do
        pm.destroy!
      end
    end
  end

  test "non members should not read project media in private team" do
    u = create_user
    t = create_team
    p = create_project team: t
    m = create_media project: p
    pm = create_project_media project: p, media: m
    pu = create_user
    pt = create_team private: true
    create_team_user team: pt, user: pu
    pp = create_project team: pt
    m = create_media project: pp
    ppm = create_project_media project: pp, media: m
    ProjectMedia.find_if_can(pm.id)
    assert_raise CheckdeskPermissions::AccessDenied do
      with_current_user_and_team(u, pt) do
        ProjectMedia.find_if_can(ppm.id)
      end
    end
    with_current_user_and_team(pu, pt) do
      ProjectMedia.find_if_can(ppm.id)
    end
    tu = pt.team_users.last
    tu.update_column(:status, 'requested')
    assert_raise CheckdeskPermissions::AccessDenied do
      with_current_user_and_team(pu, pt) do
        ProjectMedia.find_if_can(ppm.id)
      end
    end
  end

  test "should get media from callback" do
    pm = create_project_media
    assert_equal 2, pm.media_id_callback(1, [1, 2, 3])
  end

  test "should get project from callback" do
    tm = create_project_media
    assert_equal 2, tm.project_id_callback(1, [1, 2, 3])
  end

  test "should notify Slack when project media is created" do
    t = create_team subdomain: 'test'
    u = create_user
    tu = create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    t.set_slack_notifications_enabled = 1; t.set_slack_webhook = 'https://hooks.slack.com/services/123'; t.set_slack_channel = '#test'; t.save!
    with_current_user_and_team(u, t) do
      m = create_valid_media origin: 'http://test.localhost:3333'
      pm = create_project_media project: p, media: m, origin: 'http://localhost:3333'
      assert pm.sent_to_slack
      # claim media
      m = create_claim_media origin: 'http://localhost:3333'
      pm = create_project_media project: p, media: m, origin: 'http://localhost:3333'
      assert pm.sent_to_slack
    end
  end

  test "should notify Pusher when project media is created" do
    pm = create_project_media
    assert pm.sent_to_pusher
    # claim media
    t = create_team
    p = create_project team: t
    m = create_claim_media project_id: p.id
    pm = create_project_media project: p, media: m
    assert pm.sent_to_pusher
  end

  test "should notify Pusher in background" do
    Rails.stubs(:env).returns(:production)
    t = create_team
    p = create_project team:  t
    CheckdeskNotifications::Pusher::Worker.drain
    assert_equal 0, CheckdeskNotifications::Pusher::Worker.jobs.size
    create_project_media project: p
    assert_equal 2, CheckdeskNotifications::Pusher::Worker.jobs.size
    CheckdeskNotifications::Pusher::Worker.drain
    assert_equal 0, CheckdeskNotifications::Pusher::Worker.jobs.size
    Rails.unstub(:env)
  end

  test "should set initial status for media" do
    u = create_user
    t = create_team
    p = create_project team: t
    m = create_valid_media user: u
    pm = create_project_media project: p, media: m
    assert_equal Status.default_id(m, p), pm.annotations('status').last.status
  end

  test "should update project media embed data" do
    pender_url = CONFIG['pender_host'] + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "test media", "description":"add desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m = create_media(account: create_valid_account, url: url)
    p1 = create_project
    p2 = create_project
    pm1 = create_project_media project: p1, media: m
    pm2 = create_project_media project: p2, media: m
    # fetch data (without overridden)
    data = pm1.embed
    assert_equal 'test media', data['title']
    assert_equal 'add desc', data['description']
    # Update media title and description for pm1
    info = {title: 'Title A', description: 'Desc A'}.to_json
    pm1.embed= info
    info = {title: 'Title AA', description: 'Desc AA'}.to_json
    pm1.embed= info
    # Update media title and description for pm2
    info = {title: 'Title B', description: 'Desc B'}.to_json
    pm2.embed= info
    info = {title: 'Title BB', description: 'Desc BB'}.to_json
    pm2.embed= info
    # fetch data for pm1
    data = pm1.embed
    assert_equal 'Title AA', data['title']
    assert_equal 'Desc AA', data['description']
    # fetch data for pm2
    data = pm2.embed
    assert_equal 'Title BB', data['title']
    assert_equal 'Desc BB', data['description']
  end

  test "should get published time" do
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p
    assert_not_nil pm.published
    assert_not_nil pm.send(:published)
  end

  test "should have annotations" do
    pm = create_project_media
    c1 = create_comment annotated: pm
    c2 = create_comment annotated: pm
    c3 = create_comment annotated: nil
    assert_equal [c1.id, c2.id].sort, pm.reload.annotations('comment').map(&:id).sort
  end

  test "should get permissions" do
    u = create_user
    t = create_team current_user: u
    tu = create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    pm = create_project_media project: p, current_user: u
    perm_keys = ["read ProjectMedia", "update ProjectMedia", "destroy ProjectMedia", "create Comment", "create Flag", "create Status", "create Tag"].sort
    User.stubs(:current).returns(u)
    Team.stubs(:current).returns(t)
    # load permissions as owner
    assert_equal perm_keys, JSON.parse(pm.permissions).keys.sort
    # load as editor
    tu.update_column(:role, 'editor')
    assert_equal perm_keys, JSON.parse(pm.permissions).keys.sort
    # load as editor
    tu.update_column(:role, 'editor')
    assert_equal perm_keys, JSON.parse(pm.permissions).keys.sort
    # load as journalist
    tu.update_column(:role, 'journalist')
    assert_equal perm_keys, JSON.parse(pm.permissions).keys.sort
    # load as contributor
    tu.update_column(:role, 'contributor')
    assert_equal perm_keys, JSON.parse(pm.permissions).keys.sort
    # load as authenticated
    tu.update_column(:team_id, nil)
    assert_equal perm_keys, JSON.parse(pm.permissions).keys.sort
    User.unstub(:current)
    Team.unstub(:current)
  end

  test "should journalist edit own status" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'journalist'
    p = create_project team: t, user: create_user
    pm = create_project_media project: p, user: u
    with_current_user_and_team(u, t) do
      assert JSON.parse(pm.permissions)['create Status']
    end
  end

end
