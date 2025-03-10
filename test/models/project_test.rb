require_relative '../test_helper'

class ProjectTest < ActiveSupport::TestCase
  def setup
    require 'sidekiq/testing'
    Sidekiq::Testing.fake!
    Sidekiq::Worker.clear_all
    super
  end

  test "should create project" do
    t = create_team
    assert_difference 'Project.count' do
      create_project team: t
    end
    u = create_user
    t = create_team current_user: u
    assert_difference 'Project.count' do
      p = create_project team: t, current_user: u
    end
  end

  test "should not create project by collaborator" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'collaborator'
    assert_raise RuntimeError do
      with_current_user_and_team(u, t) { create_project team: t }
    end
  end

  ['editor', 'admin'].each do |role|
    test "should update and destroy project by #{role}" do
      u = create_user
      t = create_team
      t2 = create_team
      p2 = create_project team: t2
      create_team_user user: u, team: t, role: role
      with_current_user_and_team(u, t) do
        p = create_project team: t, user: u
        p.title = 'Project A'; p.save!
        assert_equal p.reload.title, 'Project A'
        assert_raise RuntimeError do
          create_project team: t2
        end
        assert_raise RuntimeError do
          p2.title = 'Projcet B'; p2.save
        end
        assert_nothing_raised do
          p.destroy
        end
        assert_raise RuntimeError do
          p2.destroy
        end
      end
    end
  end

  test "collaborator should not create update or destroy project" do
    t = create_team
    u = create_user
    tu = create_team_user team: t, user: u, role: 'collaborator'
    p = create_project team: t
    with_current_user_and_team(u, t) do
      assert_raise RuntimeError do
        create_project team: t
      end
      assert_raise RuntimeError do
        p.title = 'Project A'; p.save!
      end
      assert_raise RuntimeError do
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
    create_team_user team: pt, user: pu, role: 'admin'
    pp = create_project team: pt
    with_current_user_and_team(u, t) { Project.find_if_can(p.id) }
    assert_raise CheckPermissions::AccessDenied do
      with_current_user_and_team(u, pt) { Project.find_if_can(pp.id) }
    end
    with_current_user_and_team(pu, pt) { Project.find_if_can(pp.id) }
    tu = pt.team_users.last
    tu.status = 'requested'; tu.save!
    assert_raise CheckPermissions::AccessDenied do
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
    begin
      ft = create_field_type field_type: 'image_path', label: 'Image Path'
      at = create_annotation_type annotation_type: 'reverse_image', label: 'Reverse Image'
      create_field_instance annotation_type_object: at, name: 'reverse_image_path', label: 'Reverse Image', field_type_object: ft, optional: false
      create_bot name: 'Check Bot'
    rescue
      # Already exists
    end
    t = create_team
    m1 = create_valid_media team: t
    m2 = create_valid_media team: t
    p = create_project team: t
    create_project_media project: p, media: m1
    create_project_media project: p, media: m2
    assert_equal [m1, m2].sort, p.reload.project_medias.map(&:media).sort
  end

  test "should have annotations" do
    pm = create_project_media
    d1 = create_dynamic_annotation annotated: nil
    d2 = create_dynamic_annotation annotated: nil
    d3 = create_dynamic_annotation annotated: nil
    pm.add_annotation(d1)
    pm.add_annotation(d2)
    assert_equal [d1.id, d2.id].sort, pm.reload.annotations('dynamic').map(&:id).sort
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
    assert_nil p.lead_image_callback(file)
  end

  test "should not upload a logo that is not an image" do
    t = create_team
    assert_no_difference 'Project.count' do
      assert_raises MiniMagick::Invalid do
        create_project team: t, lead_image: 'not-an-image.csv'
      end
    end
  end

  test "should not upload a big logo" do
    t = create_team
    assert_no_difference 'Project.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_project team: t, lead_image: 'ruby-big.png'
      end
    end
  end

  test "should not upload a small logo" do
    t = create_team
    assert_no_difference 'Project.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_project team: t, lead_image: 'ruby-small.png'
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
    create_team_user user: u, team: t, role: 'admin'
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
    create_team_user user: u, team: t, role: 'admin'
    p = create_project team: t, user: nil
    assert_nil p.user
    with_current_user_and_team(u, t) do
      p = create_project user: nil, team: t
      assert_equal u, p.user
    end
  end

  test "should have settings" do
    p = create_project
    assert_equal({}, p.settings)
    assert_nil p.setting(:foo)
    p.set_foo = 'bar'
    p.save!
    assert_equal 'bar', p.reload.setting(:foo)

    assert_raise NoMethodError do
      p.something
    end
  end

  test "should notify Slack when project is created if there are settings and user and notifications are enabled" do
    t = create_team slug: 'test'
    t.set_slack_notifications_enabled = 1
    t.set_slack_webhook = 'https://hooks.slack.com/services/123'
    slack_notifications = [{
      "label": random_string,
      "event_type": "any_activity",
      "slack_channel": "#test"
    }]
    t.slack_notifications = slack_notifications.to_json
    t.save!
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    with_current_user_and_team(u, t) do
      p = create_project team: t
      assert p.sent_to_slack
    end
  end

  test "should not notify Slack when project is created if there are no settings" do
    t = create_team slug: 'test'
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    p = create_project current_user: u, context_team: t, team: t
    assert_nil p.sent_to_slack
  end

  test "should not notify Slack when project is created if not enabled" do
    t = create_team slug: 'test'
    t.set_slack_notifications_enabled = 0
    t.set_slack_webhook = 'https://hooks.slack.com/services/123'
    slack_notifications = [{
      "label": random_string,
      "event_type": "any_activity",
      "slack_channel": "#test"
    }]
    t.slack_notifications = slack_notifications.to_json
    t.save!
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    p = create_project context_team: t, team: t, current_user: u
    assert_nil p.sent_to_slack
  end

  test "should notify Pusher when project is created" do
    p = create_project
    assert p.sent_to_pusher
  end

  test "should get permissions" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'admin'
    p = create_project team: t
    perm_keys = ["read Project", "update Project", "destroy Project", "create ProjectMedia", "create Source", "create Media", "create Claim", "create Link"].sort

    # load permissions as owner
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(p.permissions).keys.sort }

    # load as editor
    tu = u.team_users.last; tu.role = 'editor'; tu.save!
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(p.permissions).keys.sort }

    # load as editor
    tu = u.team_users.last; tu.role = 'editor'; tu.save!
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(p.permissions).keys.sort }

    # load as editor
    tu = u.team_users.last; tu.role = 'editor'; tu.save!
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(p.permissions).keys.sort }

    # load as collaborator
    tu = u.team_users.last; tu.role = 'collaborator'; tu.save!
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(p.permissions).keys.sort }

    # load as authenticated
    tu = u.team_users.last; tu.role = 'editor'; tu.save!
    tu.delete
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(p.permissions).keys.sort }
  end

  test "should protect attributes from mass assignment" do
    raw_params = { title: "My project", team: create_team }
    params = ActionController::Parameters.new(raw_params)

    assert_raise ActiveModel::ForbiddenAttributesError do
      Project.create(params)
    end
  end

  test "should have search id" do
    p = create_project
    assert_not_nil p.search_id
  end

  test "should have token" do
    p1 = create_project
    p2 = create_project
    assert p1.token.size > 5
    assert p2.token.size > 5
    assert p1.token != p2.token
  end

  test "should archive project medias when project is archived" do
    Sidekiq::Testing.inline! do
      p = create_project
      pm1 = create_project_media
      pm2 = create_project_media project: p
      pm3 = create_project_media project: p
      p.archived = CheckArchivedFlags::FlagCodes::TRASHED
      p.save!
      assert_equal CheckArchivedFlags::FlagCodes::NONE, pm1.reload.archived
      assert_equal CheckArchivedFlags::FlagCodes::TRASHED, pm2.reload.archived
      assert_equal CheckArchivedFlags::FlagCodes::TRASHED, pm3.reload.archived
    end
  end

  test "should archive project medias in background when project is archived" do
    p = create_project
    pm = create_project_media project: p
    n = Sidekiq::Extensions::DelayedClass.jobs.size
    p = Project.find(p.id)
    p.archived = CheckArchivedFlags::FlagCodes::TRASHED
    p.save!
    assert_equal n + 1, Sidekiq::Extensions::DelayedClass.jobs.size
  end

  test "should not archive project medias in background if project is updated but archived flag does not change" do
    p = create_project
    pm = create_project_media project: p
    n = Sidekiq::Extensions::DelayedClass.jobs.size
    p = Project.find(p.id)
    p.title = random_string
    p.save!
    assert_equal n, Sidekiq::Extensions::DelayedClass.jobs.size
  end

  test "should restore project medias when project is restored" do
    Sidekiq::Testing.inline! do
      p = create_project
      pm1 = create_project_media
      pm2 = create_project_media project: p
      pm3 = create_project_media project: p
      p.archived = CheckArchivedFlags::FlagCodes::TRASHED
      p.save!
      assert_equal CheckArchivedFlags::FlagCodes::NONE, pm1.reload.archived
      assert_equal CheckArchivedFlags::FlagCodes::TRASHED, pm2.reload.archived
      assert_equal CheckArchivedFlags::FlagCodes::TRASHED, pm3.reload.archived
      p = Project.find(p.id)
      p.archived = CheckArchivedFlags::FlagCodes::NONE
      p.save!
      assert_equal CheckArchivedFlags::FlagCodes::NONE, pm1.reload.archived
      assert_equal CheckArchivedFlags::FlagCodes::NONE, pm2.reload.archived
      assert_equal CheckArchivedFlags::FlagCodes::NONE, pm3.reload.archived
    end
  end

  test "should not create project under archived team" do
    t = create_team
    t.archived = CheckArchivedFlags::FlagCodes::TRASHED
    t.save!

    assert_raises ActiveRecord::RecordInvalid do
      create_project team: t
    end
  end

  test "should delete project medias in background when project is deleted" do
    Sidekiq::Testing.fake! do
      u = create_user
      t = create_team
      create_team_user user: u, team: t, role: 'admin'
      p = create_project user: u, team: t
      pm = create_project_media project: p
      n = Sidekiq::Extensions::DelayedClass.jobs.size
      p = Project.find(p.id)
      with_current_user_and_team(u, t) do
        p.destroy_later
      end
      assert_equal n + 1, Sidekiq::Extensions::DelayedClass.jobs.size
    end
  end

  test "should delete project medias when project is deleted" do
    Sidekiq::Testing.inline! do
      u = create_user
      t = create_team
      create_team_user user: u, team: t, role: 'admin'
      p = create_project user: u, team: t
      pm1 = create_project_media
      pm2 = create_project_media project: p
      pm3 = create_project_media project: p
      tag = create_tag annotated: pm3
      RequestStore.store[:disable_es_callbacks] = true
      with_current_user_and_team(u, t) do
        p.destroy_later
      end
      RequestStore.store[:disable_es_callbacks] = false
      assert_not_nil ProjectMedia.where(id: pm1.id).last
      assert_not_nil ProjectMedia.where(id: pm2.id, team_id: t.id).last
      assert_not_nil ProjectMedia.where(id: pm3.id, team_id: t.id).last
      assert_not_nil Tag.where(id: tag.id).last
    end
  end

  test "should not delete project later if doesn't have permission" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'collaborator'
    p = create_project team: t
    with_current_user_and_team(u, t) do
      assert_raises RuntimeError do
        p.destroy_later
      end
    end
  end

  test "should reset current project when project is deleted" do
    p = create_project
    u = create_user
    u.current_project_id = p.id
    u.save!
    assert_not_nil u.reload.current_project_id
    p.destroy
    assert_nil u.reload.current_project_id
  end

  test "should get team" do
    t = create_team
    p = create_project team: t
    assert_equal t, p.team
  end

  test "should notify Slack when project is assigned" do
    t = create_team slug: 'test'
    p = create_project team: t
    t.set_slack_notifications_enabled = 1
    t.set_slack_webhook = 'https://hooks.slack.com/services/123'
    slack_notifications = [{
      "label": random_string,
      "event_type": "any_activity",
      "slack_channel": "#test"
    }]
    t.slack_notifications = slack_notifications.to_json
    t.save!
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    p = Project.find(p.id)
    with_current_user_and_team(u, t) do
      assert !p.sent_to_slack
      p.assigned_to_ids = u.id.to_s
      p.save!
      assert p.sent_to_slack
    end
  end

  test "should propagate assignments" do
    Sidekiq::Testing.inline! do
      create_verification_status_stuff
      stub_configs({ 'default_project_media_workflow' => 'verification_status' }) do
        t = create_team
        p = create_project team: t
        u = create_user
        create_team_user user: u, team: t
        pm1 = create_project_media project: p
        pm2 = create_project_media project: p
        3.times { create_task(annotated: pm1) }
        3.times { create_task(annotated: pm2) }
        a = nil
        assert_difference 'Assignment.count', 9 do
          a = p.assign_user(u.id)
        end
        assert_not_nil a
        assert_difference 'Assignment.count', -9 do
          a.destroy!
        end
      end
    end
  end

  test "should return search object" do
    p = create_project
    assert_kind_of CheckSearch, p.search
  end

  test "should not create duplicate assignment" do
    Sidekiq::Testing.inline! do
      create_verification_status_stuff
      t = create_team
      u = create_user
      p = create_project team: t
      create_team_user user: u, team: t
      pm = create_project_media project: p
      3.times { create_task(annotated: pm) }
      id = pm.last_verification_status_obj.id
      a = Assignment.new(user: u, assigned_type: 'Annotation', assigned_id: id)
      Assignment.import([a])
      a = YAML::dump(a)
      Assignment.propagate_assignments(a, 0, :assign)
      n = Assignment.count
      Assignment.any_instance.stubs(:nil?).returns(true)
      Assignment.propagate_assignments(a, 0, :assign)
      Assignment.any_instance.unstub(:nil?)
      assert_equal n, Assignment.count
    end
  end

  test "should have search team" do
    assert_kind_of CheckSearch, create_project.check_search_team
    assert_kind_of Array, create_project.check_search_team.projects
  end

  test "should have a project group" do
    t = create_team
    p = create_project team: t
    pg = create_project_group team: t
    assert_nil p.project_group
    assert_nothing_raised do
      p.project_group_id = pg.id
      p.save!
    end
    assert_equal pg, p.reload.project_group
    assert_equal [p], pg.reload.projects
  end

  test "should not have a project group in another team" do
    p = create_project
    pg = create_project_group
    assert_raises ActiveRecord::RecordInvalid do
      p.project_group_id = pg.id
      p.save!
    end
  end

  test "should have previous project group" do
    p = create_project
    pg = create_project_group
    p.previous_project_group_id = pg.id
    assert_equal pg, p.project_group_was
  end

  test "should validate unique default folder and should not delete it" do
    t = create_team
    default_folder = t.default_folder
    assert_raises ActiveRecord::RecordInvalid do
      default_folder.is_default = false
      default_folder.save!
    end
    p = create_project team: t
    p.is_default = true
    p.save!
    assert_equal 1, t.projects.where(is_default: true).count
    default_folder = t.default_folder
    assert_raises ActiveRecord::RecordNotDestroyed do
      default_folder.destroy!
    end
  end

  test "should move project medias to destination project when destroy project" do
    RequestStore.store[:skip_cached_field_update] = false
    t = create_team
    u = create_user
    p = create_project team: t
    p2 = create_project team: t
    p3 = create_project team: t
    default_folder = t.default_folder
    create_team_user team: t, user: u, role: 'admin'
    Sidekiq::Testing.inline! do
      with_current_user_and_team(u, t) do
        pm1 = create_project_media project: p
        pm2 = create_project_media project: p
        pm3 = create_project_media project: p2
        pm4 = create_project_media project: p2
        # should move realted items to default project if destination not set
        assert_equal [pm1.id, pm2.id], p.project_media_ids.sort
        assert_equal [pm3.id, pm4.id], p2.project_media_ids.sort
        p.destroy
        assert_equal [pm1.id, pm2.id], default_folder.reload.project_media_ids.sort
        # should move realted items to destination project
        puts "items_destination_project_id ==> #{p3.id}"
        p2.items_destination_project_id = p3.id
        p2.destroy
        assert_equal [pm3.id, pm4.id], p3.reload.project_media_ids.sort
      end
    end
    RequestStore.store[:skip_cached_field_update] = true
  end

  test "should not delete default folder" do
    t = create_team
    t.projects.delete_all
    p = create_project is_default: false, team: t
    assert_difference 'Project.count', -1 do
      assert_nothing_raised do
        p.destroy!
      end
    end
    p = create_project is_default: true, team: t
    assert_no_difference 'Project.count' do
      assert_raises ActiveRecord::RecordNotDestroyed do
        p.destroy!
      end
    end
  end

  test "should be inactive if team is inactive" do
    t = create_team inactive: true
    p = create_project team: t
    assert p.inactive
  end

  test "should get and set current project" do
    p = create_project
    assert_nil Project.current
    Project.current = p
    assert_equal p, Project.current
  end
end
