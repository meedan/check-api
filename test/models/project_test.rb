require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class ProjectTest < ActiveSupport::TestCase
  def setup
    super
    require 'sidekiq/testing'
    Sidekiq::Testing.fake!
  end

  test "should create project" do
    assert_difference 'Project.count' do
      create_project
    end
    u = create_user
    t = create_team current_user: u
    assert_difference 'Project.count' do
      p = create_project team: t, current_user: u
    end
  end

  test "should not create project by contributor" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'contributor'
    assert_raise RuntimeError do
      with_current_user_and_team(u, t) { create_project team: t }
    end
  end

  test "should update and destroy project" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'owner'

    p = nil
    with_current_user_and_team(u, t) do
      p = create_project team: t, user: u
      p.title = 'Project A'; p.save!
      p.reload
      assert_equal p.title, 'Project A'
    end

    u2 = create_user
    tu = create_team_user team: t, user: u2, role: 'journalist'

    with_current_user_and_team(u2, t) do
      assert_raise RuntimeError do
        p.save!
      end
      assert_raise RuntimeError do
        p.destroy!
      end
      own_project = create_project team: t, user: u2
      own_project.title = 'Project A'
      own_project.save!
      assert_equal own_project.title, 'Project A'
      assert_raise RuntimeError do
        own_project.destroy!
      end
    end

    with_current_user_and_team(u, t) do
      assert_nothing_raised RuntimeError do
        p.destroy!
      end
    end
  end

  test "non members should not read project in private team" do
    u = create_user
    t = create_team
    p = create_project team: t
    pu = create_user
    pt = create_team private: true
    create_team_user team: pt, user: pu, role: 'owner'
    pp = create_project team: pt
    with_current_user_and_team(u, t) { Project.find_if_can(p.id) }
    assert_raise CheckdeskPermissions::AccessDenied do
      with_current_user_and_team(u, pt) { Project.find_if_can(pp.id) }
    end
    with_current_user_and_team(pu, pt) { Project.find_if_can(pp.id) }
    tu = pt.team_users.last
    tu.status = 'requested'; tu.save!
    assert_raise CheckdeskPermissions::AccessDenied do
      with_current_user_and_team(pu.reload, pt) { Project.find_if_can(pp.id) }
    end
  end

  test "should not save project without title" do
    project = Project.new
    assert_not project.save
  end

  test "should have user" do
    assert_kind_of User, create_project.user
  end

  test "should have media" do
    m1 = create_valid_media
    m2 = create_valid_media
    p = create_project
    p.medias << m1
    p.medias << m2
    assert_equal [m1, m2], p.medias
  end

  test "should get project medias count" do
    t = create_team
    p = create_project team: t
    create_project_media project: p
    create_project_media project: p
    assert_equal 2, p.medias_count
  end

  test "should have project sources" do
    ps1 = create_project_source
    ps2 = create_project_source
    p = create_project
    p.project_sources << ps1
    p.project_sources << ps2
    assert_equal [ps1, ps2], p.project_sources
  end

  test "should have sources" do
    s1 = create_source
    s2 = create_source
    ps1 = create_project_source(source: s1)
    ps2 = create_project_source(source: s2)
    p = create_project
    p.project_sources << ps1
    p.project_sources << ps2
    assert_equal [s1, s2], p.sources
  end

  test "should have annotations" do
    pm = create_project_media
    c1 = create_comment annotated: nil
    c2 = create_comment annotated: nil
    c3 = create_comment annotated: nil
    pm.add_annotation(c1)
    pm.add_annotation(c2)
    assert_equal [c1.id, c2.id].sort, pm.reload.annotations('comment').map(&:id).sort
  end

  test "should get user id through callback" do
    p = create_project
    assert_nil p.send(:user_id_callback, 'test@test.com')
    u = create_user email: 'test@test.com'
    assert_equal u.id, p.send(:user_id_callback, 'test@test.com')
  end

  test "should get team from callback" do
    p = create_project
    assert_equal 2, p.team_id_callback(1, [1, 2, 3])
  end

  test "should get lead image from callback" do
    p = create_project
    assert_nil p.lead_image_callback('')
    file = 'http://checkdesk.org/users/1/photo.png'
    assert_nil p.lead_image_callback(file)
    file = 'http://ca.ios.ba/files/others/rails.png'
    assert_not_nil p.lead_image_callback(file)
  end

  test "should not upload a logo that is not an image" do
    assert_no_difference 'Project.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_project lead_image: 'not-an-image.txt'
      end
    end
  end

  test "should not upload a big logo" do
    assert_no_difference 'Project.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_project lead_image: 'ruby-big.png'
      end
    end
  end

  test "should not upload a small logo" do
    assert_no_difference 'Project.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_project lead_image: 'ruby-small.png'
      end
    end
  end

  test "should have a default uploaded image" do
    p = create_project lead_image: nil
    assert_match /project\.png$/, p.lead_image.url
  end

  test "should assign current team to project" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'owner'
    p = create_project current_user: nil
    assert_not_equal t, p.team
    p = create_project team: t, current_user: u
    assert_equal t, p.team
  end

  test "should have avatar" do
    p = create_project lead_image: nil
    assert_match /^http/, p.avatar
  end

  test "should have a JSON version" do
    assert_kind_of Hash, create_project.as_json
  end

  test "should create project with team" do
    t1 = create_team
    t2 = create_team
    p = create_project team_id: t2.id
    assert_equal t2, p.reload.team
  end

  test "should set user" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'owner'
    p = create_project team: t, user: nil
    assert_nil p.user
    with_current_user_and_team(u, t) do
      p = create_project user: nil, team: t
      assert_equal u, p.user
    end
  end

  test "should have settings" do
    p = create_project
    assert_nil p.settings
    assert_nil p.setting(:foo)
    p.set_foo = 'bar'
    p.save!
    assert_equal 'bar', p.reload.setting(:foo)

    assert_raise NoMethodError do
      p.something
    end
  end

  test "should notify Slack when project is created if there are settings and user and notifications are enabled" do
    t = create_team subdomain: 'test'
    t.set_slack_notifications_enabled = 1; t.set_slack_webhook = 'https://hooks.slack.com/services/123'; t.set_slack_channel = '#test'; t.save!
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    with_current_user_and_team(u, t) do
      p = create_project origin: 'http://test.localhost:3333', team: t
      assert p.sent_to_slack
    end
  end

  test "should not notify Slack when project is created if there are no settings" do
    t = create_team subdomain: 'test'
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    p = create_project origin: 'http://test.localhost:3333', current_user: u, context_team: t, team: t
    assert_nil p.sent_to_slack
  end

  test "should not notify Slack when project is created if there is no user" do
    t = create_team subdomain: 'test'
    t.set_slack_notifications_enabled = 1; t.set_slack_webhook = 'https://hooks.slack.com/services/123'; t.set_slack_channel = '#test'; t.save!
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    p = create_project origin: 'http://test.localhost:3333', context_team: t, team: t
    assert_nil p.sent_to_slack
  end

  test "should not notify Slack when project is created if not enabled" do
    t = create_team subdomain: 'test'
    t.set_slack_notifications_enabled = 0; t.set_slack_webhook = 'https://hooks.slack.com/services/123'; t.set_slack_channel = '#test'; t.save!
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    p = create_project origin: 'http://test.localhost:3333', context_team: t, team: t, current_user: u
    assert_nil p.sent_to_slack
  end

  test "should notify Slack in background" do
    Rails.stubs(:env).returns(:production)
    t = create_team subdomain: 'test'
    t.set_slack_notifications_enabled = 1; t.set_slack_webhook = 'https://hooks.slack.com/services/123'; t.set_slack_channel = '#test'; t.save!
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    assert_equal 0, CheckdeskNotifications::Slack::Worker.jobs.size
    with_current_user_and_team(u, t) do
      p = create_project origin: 'http://test.localhost:3333', team: t
      assert_equal 1, CheckdeskNotifications::Slack::Worker.jobs.size
      CheckdeskNotifications::Slack::Worker.drain
      assert_equal 0, CheckdeskNotifications::Slack::Worker.jobs.size
      Rails.unstub(:env)
    end
  end

  test "should notify Pusher when project is created" do
    p = create_project
    assert p.sent_to_pusher
  end

  test "should get permissions" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'owner'
    p = create_project team: t
    perm_keys = ["read Project", "update Project", "destroy Project", "create ProjectMedia", "create ProjectSource", "create Source", "create Media", "create Claim", "create Link"].sort

    # load permissions as owner
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(p.permissions).keys.sort }

    # load as editor
    tu = u.team_users.last; tu.role = 'editor'; tu.save!
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(p.permissions).keys.sort }

    # load as editor
    tu = u.team_users.last; tu.role = 'editor'; tu.save!
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(p.permissions).keys.sort }

    # load as journalist
    tu = u.team_users.last; tu.role = 'journalist'; tu.save!
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(p.permissions).keys.sort }

    # load as contributor
    tu = u.team_users.last; tu.role = 'contributor'; tu.save!
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(p.permissions).keys.sort }

    # load as authenticated
    tu = u.team_users.last; tu.role = 'editor'; tu.save!
    tu.delete
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(p.permissions).keys.sort }
  end

end
