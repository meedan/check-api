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
    assert_difference 'ProjectMedia.count' do
      create_project_media project: p, media: m, current_user: u
    end
    # journalist should assign own media only
    tu.role = 'journalist'; tu.save;
    m2 = create_valid_media
    assert_raise RuntimeError do
      create_project_media project: p, media: m, current_user: u
    end
    m2.user_id = u.id;m2.save!
    assert_difference 'ProjectMedia.count' do
      create_project_media project: p, media: m2, current_user: u
    end
  end

  test "should update and destroy project media" do
    u = create_user
    t = create_team current_user: u
    p = create_project team: t, current_user: u
    p2 = create_project team: t, current_user: u
    m = create_valid_media project_id: p.id, current_user: u
    pm = m.project_medias.last
    pm.current_user = u
    pm.project_id = p2.id; pm.save!
    pm.reload
    assert_equal pm.project_id, p2.id
    u2 = create_user
    tu = create_team_user team: t, user: u2, role: 'journalist'
    assert_raise RuntimeError do
      pm.current_user = u2
      pm.save!
    end
    assert_raise RuntimeError do
      pm.current_user = u2
      pm.destroy!
    end
    own_media = create_valid_media project_id: p.id, user: u2, current_user: u2
    pm_own = own_media.project_medias.last
    pm_own.current_user = u2
    pm_own.project_id = p2.id; pm_own.save!
    pm_own.reload
    assert_equal pm_own.project_id, p2.id
    assert_nothing_raised RuntimeError do
      pm_own.current_user = u2
      pm_own.destroy!
    end
    assert_nothing_raised RuntimeError do
      pm.current_user = u
      pm.destroy!
    end
  end

  test "non memebers should not read project media in private team" do
    u = create_user
    t = create_team current_user: create_user
    m = create_media team: t
    pm = m.project_medias.last
    pu = create_user
    pt = create_team current_user: pu, private: true
    m = create_media team: pt
    ppm = m.project_medias.last
    ProjectMedia.find_if_can(pm.id, u, t)
    assert_raise CheckdeskPermissions::AccessDenied do
      ProjectMedia.find_if_can(ppm.id, u, pt)
    end
    ProjectMedia.find_if_can(ppm.id, pu, pt)
    tu = pt.team_users.last
    tu.status = 'requested'; tu.save!
    assert_raise CheckdeskPermissions::AccessDenied do
      ProjectMedia.find_if_can(ppm.id, pu, pt)
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
    create_team_user team: t, user: u
    p = create_project team: t
    t.set_slack_notifications_enabled = 1; t.set_slack_webhook = 'http://test.slack.com'; t.set_slack_channel = '#test'; t.save!
    m = create_valid_media project_id: p.id, origin: 'http://test.localhost:3333', current_user: u
    pm = create_project_media project: p, media: m, origin: 'http://localhost:3333', current_user: u, context_team: t
    assert pm.sent_to_slack
  end

  test "should notify Pusher when project media is created" do
    pm = create_project_media
    assert pm.sent_to_pusher
  end

  test "should notify Pusher in background" do
    Rails.stubs(:env).returns(:production)
    assert_equal 0, CheckdeskNotifications::Pusher::Worker.jobs.size
    create_project_media
    assert_equal 1, CheckdeskNotifications::Pusher::Worker.jobs.size
    CheckdeskNotifications::Pusher::Worker.drain
    assert_equal 0, CheckdeskNotifications::Pusher::Worker.jobs.size
    Rails.unstub(:env)
  end
end
