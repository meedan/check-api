require_relative '../test_helper'

class ProjectTest < ActiveSupport::TestCase
  def setup
    require 'sidekiq/testing'
    Sidekiq::Testing.fake!
    Sidekiq::Worker.clear_all
    super
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
    m1 = create_valid_media
    m2 = create_valid_media
    p = create_project
    create_project_media project: p, media: m1
    create_project_media project: p, media: m2
    assert_equal [m1, m2].sort, p.reload.medias.sort
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
    assert_equal [ps1, ps2].sort, p.project_sources.sort
  end

  test "should have sources" do
    s1 = create_source
    s2 = create_source
    ps1 = create_project_source(source: s1)
    ps2 = create_project_source(source: s2)
    p = create_project
    p.project_sources << ps1
    p.project_sources << ps2
    assert_equal [s1, s2].sort, p.sources.sort
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
    assert_nil p.lead_image_callback(file)
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
    t.set_slack_notifications_enabled = 1; t.set_slack_webhook = 'https://hooks.slack.com/services/123'; t.set_slack_channel = '#test'; t.save!
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    with_current_user_and_team(u, t) do
      p = create_project team: t
      assert p.sent_to_slack
    end
  end

  test "should not notify Slack when project is created if there are no settings" do
    t = create_team slug: 'test'
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    p = create_project current_user: u, context_team: t, team: t
    assert_nil p.sent_to_slack
  end

  test "should not notify Slack when project is created if not enabled" do
    t = create_team slug: 'test'
    t.set_slack_notifications_enabled = 0; t.set_slack_webhook = 'https://hooks.slack.com/services/123'; t.set_slack_channel = '#test'; t.save!
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
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

  test "should protect attributes from mass assignment" do
    raw_params = { title: "My project", team: create_team }
    params = ActionController::Parameters.new(raw_params)

    assert_raise ActiveModel::ForbiddenAttributesError do
      Project.create(params)
    end
  end

  test "should set slack_notifications_enabled" do
    p = create_project
    p.slack_notifications_enabled = true
    p.save
    assert p.get_slack_notifications_enabled
  end

  test "should set slack_channel" do
    p = create_project
    p.slack_channel = 'my-channel'
    p.save
    assert_equal 'my-channel', p.get_slack_channel
  end

  test "should display team on admin label" do
    t = create_team name: 'my-team'
    p = create_project team: t, title: 'my-project'
    assert_equal 'my-team - my-project', p.admin_label
  end

  test "should have a filename without spaces" do
    t = create_team name: 'Team t'
    p = create_project team: t, title: 'Project p'
    assert_match(/team-t_project-p_.*/, p.export_filename(:csv))
  end

  test "should export data for Check" do
    create_verification_status_stuff
    stub_config('default_project_media_workflow', 'verification_status') do
      p = create_project
      pm = create_project_media project: p, media: create_valid_media
      c = create_comment annotated: pm, text: 'Note 1'
      tag = create_tag tag: 'sports', annotated: pm, annotator: create_user
      task = create_task annotator: create_user, annotated: pm
      exported_data = p.export
      assert_equal 1, exported_data.size
      assert_equal p.id, exported_data.first[:project_id]
      assert_equal pm.id, exported_data.first[:report_id]
      assert_equal 'sports', exported_data.first[:tags]
      assert_equal c.text, exported_data.first[:note_content_1]
      assert_equal task.label, exported_data.first[:task_question_1]
    end
  end

  test "should export data for Bridge" do
    create_translation_status_stuff
    stub_config('default_project_media_workflow', 'translation_status') do
      at = create_annotation_type annotation_type: 'translation'
      create_field_instance name: 'translation_text', annotation_type_object: at
      create_field_instance name: 'translation_language', annotation_type_object: at
      create_field_instance name: 'translation_note', annotation_type_object: at
      p = create_project
      pm = create_project_media project: p, media: create_valid_media
      c = create_comment annotated: pm, text: 'Note 1'
      tag = create_tag tag: 'sports', annotated: pm, annotator: create_user
      task = create_task annotator: create_user, annotated: pm
      tr = create_dynamic_annotation annotation_type: 'translation', annotated: pm, set_fields: { translation_text: 'Foo', translation_language: 'en' }.to_json
      exported_data = p.export
      assert_equal 1, exported_data.size
      assert_equal p.id, exported_data.first[:project_id]
      assert_equal pm.id, exported_data.first[:report_id]
      assert_equal 'sports', exported_data.first[:tags]
      assert_equal c.text, exported_data.first[:note_content_1]
      assert_equal task.label, exported_data.first[:task_question_1]
      assert_equal tr.get_field('translation_text').value, exported_data.first[:translation_text_1]
      assert_equal 'pending', exported_data.first[:report_status]
    end
  end

  test "should export data to CSV" do
    create_translation_status_stuff
    create_verification_status_stuff(false)
    at = create_annotation_type annotation_type: 'translation'
    create_field_instance name: 'translation_text', annotation_type_object: at
    create_field_instance name: 'translation_language', annotation_type_object: at
    create_field_instance name: 'translation_note', annotation_type_object: at
    p = create_project
    pm = create_project_media project: p, media: create_valid_media
    c = create_comment annotated: pm, text: 'Note 1'
    tag = create_tag tag: 'sports', annotated: pm, annotator: create_user
    task = create_task annotator: create_user, annotated: pm
    tr = create_dynamic_annotation annotation_type: 'translation', annotated: pm, set_fields: { translation_text: 'Foo', translation_language: 'en' }.to_json
    exported_data = p.export_csv.values.first
    header = "project_id,report_id,report_title,report_url,report_date,media_content,media_url,report_status,report_author,time_delta_to_first_status,time_delta_to_last_status,time_original_media_publishing,type,contributing_users,tags,notes_count,notes_ugc_count,tasks_count,tasks_resolved_count,note_date_1,note_user_1,note_content_1,task_question_1,task_user_1,task_date_1,task_answer_1,task_note_1,translation_text_1,translation_language_1,translation_note_1"
    assert_match(header, exported_data)
  end

  test "should have search id" do
    p = create_project
    assert_not_nil p.search_id
  end

  test "should save valid slack_channel" do
    p = create_project
    value =  "#slack_channel"
    assert_nothing_raised do
      p.set_slack_channel(value)
      p.save!
    end
  end

  test "should not save slack_channel if is not valid" do
    p = create_project
    value = 'invalid_channel'
    assert_raises ActiveRecord::RecordInvalid do
      p.set_slack_channel(value)
      p.save!
    end
  end

  test "should save valid languages" do
    p = create_project
    value = ["en", "ar", "fr"]
    assert_nothing_raised do
      p.languages=(value)
      p.save!
    end
  end

  test "should not save invalid languages" do
    p = create_project
    value = "en"
    assert_raises ActiveRecord::RecordInvalid do
      p.set_languages(value)
      p.save!
    end
  end

  test "should get project languages" do
    p = create_project
    assert_equal [], p.languages
    p.settings = {:languages => ['ar', 'en']}; p.save!
    assert_equal ['ar', 'en'], p.languages
  end

  test "should have token" do
    p1 = create_project
    p2 = create_project
    assert p1.token.size > 5
    assert p2.token.size > 5
    assert p1.token != p2.token
  end

  test "should set Viber token" do
    p = create_project
    p.viber_token = 'test'
    p.save!
    assert_equal 'test', p.get_viber_token
  end

  test "should archive project medias when project is archived" do
    Sidekiq::Testing.inline! do
      p = create_project
      pm1 = create_project_media
      pm2 = create_project_media project: p
      pm3 = create_project_media project: p
      p.archived = true
      p.save!
      assert !pm1.reload.archived
      assert pm2.reload.archived
      assert pm3.reload.archived
    end
  end

  test "should archive project medias in background when project is archived" do
    p = create_project
    pm = create_project_media project: p
    n = Sidekiq::Extensions::DelayedClass.jobs.size
    p = Project.find(p.id)
    p.archived = true
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
      p.archived = true
      p.save!
      assert !pm1.reload.archived
      assert pm2.reload.archived
      assert pm3.reload.archived
      p = Project.find(p.id)
      p.archived = false
      p.save!
      assert !pm1.reload.archived
      assert !pm2.reload.archived
      assert !pm3.reload.archived
    end
  end

  test "should not create project under archived team" do
    t = create_team
    t.archived = true
    t.save!

    assert_raises ActiveRecord::RecordInvalid do
      create_project team: t
    end
  end

  test "should delete project medias in background when project is deleted" do
    Sidekiq::Testing.fake! do
      u = create_user
      t = create_team
      create_team_user user: u, team: t, role: 'owner'
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
      create_team_user user: u, team: t, role: 'owner'
      p = create_project user: u, team: t
      pm1 = create_project_media
      pm2 = create_project_media project: p
      pm3 = create_project_media project: p
      ps1 = create_project_source
      ps2 = create_project_source project: p
      c = create_comment annotated: pm3
      RequestStore.store[:disable_es_callbacks] = true
      with_current_user_and_team(u, t) do
        p.destroy_later
      end
      RequestStore.store[:disable_es_callbacks] = false
      assert_not_nil ProjectMedia.where(id: pm1.id).last
      assert_nil ProjectMedia.where(id: pm2.id).last
      assert_nil ProjectMedia.where(id: pm3.id).last
      assert_nil Comment.where(id: c.id).last
      assert_not_nil ProjectSource.where(id: ps1.id).last
      assert_nil ProjectSource.where(id: ps2.id).last
    end
  end

  test "should not delete project later if doesn't have permission" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'contributor'
    p = create_project team: t
    with_current_user_and_team(u, t) do
      assert_raises RuntimeError do
        p.destroy_later
      end
    end
  end

  test "should not notify Slack when project is created if team is limited" do
    t = create_team slug: 'test'
    t.set_slack_notifications_enabled = 1
    t.set_slack_webhook = 'https://hooks.slack.com/services/123'
    t.set_slack_channel = '#test'
    t.set_limits_slack_integration = false
    t.save!
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    with_current_user_and_team(u, t) do
      p = create_project team: t
      assert !p.sent_to_slack
    end
  end

  test "should not create project if limit was reached" do
    t = create_team
    create_project team: t
    t.set_limits_max_number_of_projects = 5
    t.save!
    t = Team.find(t.id)
    4.times do
      create_project team: t
    end
    assert_raises ActiveRecord::RecordInvalid do
      create_project team: t
    end
  end

  test "should export project to CSV" do
    Sidekiq::Testing.inline! do
      p = create_project
      assert_nothing_raised do
        p.export_to_csv_in_background
      end
    end
  end

  test "should export project images" do
    Team.any_instance.stubs(:get_limits_keep).returns(true)
    stub_configs({ 'pender_url' => 'http://pender', 'pender_url_private' => 'http://pender-private' }) do
      WebMock.stub_request(:get, 'http://pender-private/images/test.png').to_return(body: 'foo')
      ft = create_field_type field_type: 'image_path', label: 'Image Path'
      at = create_annotation_type annotation_type: 'reverse_image', label: 'Reverse Image'
      create_field_instance annotation_type_object: at, name: 'reverse_image_path', label: 'Reverse Image', field_type_object: ft, optional: false
      create_annotation_type_and_fields('Pender Archive', { 'Response' => ['JSON', false] })
      t = create_team
      t.set_limits_keep = true
      t.save!
      TeamBot.delete_all
      tb = create_team_bot identifier: 'keep', settings: [{ name: 'archive_pender_archive_enabled', type: 'boolean' }], approved: true
      tbi = create_team_bot_installation team_bot_id: tb.id, team_id: t.id
      tbi.set_archive_pender_archive_enabled = true
      tbi.save!
      p = create_project team: t
      c = create_claim_media
      pm1 = create_project_media media: c, project: p
      pm1.create_all_archive_annotations
      i = create_uploaded_image
      pm2 = create_project_media media: i, project: p
      pm2.create_all_archive_annotations
      l1 = create_link
      pm3 = create_project_media media: l1, project: p
      pm3.create_all_archive_annotations
      f = DynamicAnnotation::Field.last
      f.value = { screenshot_url: 'http://pender/images/test.png' }.to_json
      f.save!
      l2 = create_link
      pm4 = create_project_media media: l2, project: p
      pm4.create_all_archive_annotations
      assert_equal 2, p.export_images.values.reject{ |x| x.nil? }.size
    end
    Team.any_instance.unstub(:get_limits_keep)
  end

  test "should export images in background" do
    p = create_project
    n = Sidekiq::Extensions::DelayedClass.jobs.size
    p.export_images_in_background
    assert_equal n + 1, Sidekiq::Extensions::DelayedClass.jobs.size
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

  test "should return team tasks" do
    t = create_team
    p = create_project team: t
    create_team_task team_id: t.id, project_ids: [p.id + 1]
    assert p.reload.auto_tasks.empty?
    tt = create_team_task team_id: t.id, project_ids: [p.id]
    assert_equal [tt], p.reload.auto_tasks
  end

  test "should get team" do
    t = create_team
    p = create_project team: t
    assert_equal t.id, p.get_team.first
  end

  test "should notify Slack when project is assigned" do
    t = create_team slug: 'test'
    p = create_project team: t
    t.set_slack_notifications_enabled = 1; t.set_slack_webhook = 'https://hooks.slack.com/services/123'; t.set_slack_channel = '#test'; t.save!
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
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
      stub_config('default_project_media_workflow', 'verification_status') do
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
end
