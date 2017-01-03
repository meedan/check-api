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

  test "should update and destroy project media" do
    u = create_user
    t = create_team
    p = create_project team: t
    p2 = create_project team: t
    m = create_valid_media project_id: p.id, user_id: u.id
    create_team_user team: t, user: u
    pm = m.project_medias.last
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
      own_media = create_valid_media project_id: p.id, user: u2
      pm_own = own_media.project_medias.last
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
    m = create_media team: t
    pm = m.project_medias.last
    pu = create_user
    pt = create_team private: true
    create_team_user team: pt, user: pu
    m = create_media team: pt
    ppm = m.project_medias.last
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
    create_team_user team: t, user: u
    p = create_project team: t
    t.set_slack_notifications_enabled = 1; t.set_slack_webhook = 'https://hooks.slack.com/services/123'; t.set_slack_channel = '#test'; t.save!
    with_current_user_and_team(u, t) do
      m = create_valid_media project_id: p.id, origin: 'http://test.localhost:3333'
      pm = create_project_media project: p, media: m, origin: 'http://localhost:3333'
      assert pm.sent_to_slack
      # claim media
      m = create_claim_media project_id: p.id, origin: 'http://localhost:3333'
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
    CheckdeskNotifications::Pusher::Worker.drain
    assert_equal 0, CheckdeskNotifications::Pusher::Worker.jobs.size
    create_project_media
    assert_equal 3, CheckdeskNotifications::Pusher::Worker.jobs.size
    CheckdeskNotifications::Pusher::Worker.drain
    assert_equal 0, CheckdeskNotifications::Pusher::Worker.jobs.size
    Rails.unstub(:env)
  end

  test "should set initial status for media" do
    u = create_user
    t = create_team
    p = create_project team: t
    m = create_valid_media project_id: p.id, user: u
    assert_equal Status.default_id(m, p), m.annotations('status', p).last.status
  end

end
