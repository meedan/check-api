require_relative '../test_helper'

class ProjectMediaTest < ActiveSupport::TestCase
  def setup
    require 'sidekiq/testing'
    Sidekiq::Testing.fake!
    super
    create_team_bot login: 'keep', name: 'Keep'
  end

  test "should create project media" do
    assert_difference 'ProjectMedia.count' do
      create_project_media
    end
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'admin'
    m = create_valid_media
    User.stubs(:current).returns(u)
    Team.stubs(:current).returns(t)
    assert_difference 'ProjectMedia.count' do
      with_current_user_and_team(u, t) do
        pm = create_project_media team: t, media: m
        assert_equal u, pm.user
      end
    end
    # should be unique
    assert_no_difference 'ProjectMedia.count' do
      assert_raises RuntimeError do
        create_project_media team: t, media: m
      end
    end
    # editor should assign any media
    m2 = create_valid_media
    Rails.cache.clear
    tu.update_column(:role, 'editor')
    pm = nil
    assert_difference 'ProjectMedia.count' do
      pm = create_project_media team: t, media: m2
    end
    m3 = create_valid_media user_id: u.id
    assert_difference 'ProjectMedia.count' do
      pm = create_project_media team: t, media: m3
      pm.save!
    end
    User.unstub(:current)
    Team.unstub(:current)
  end

  test "should have a media not not necessarily a project" do
    assert_nothing_raised do
      create_project_media project: nil
    end
    assert_raise ActiveRecord::RecordInvalid do
      create_project_media media: nil
    end
  end

  test "should create media if url or quote set" do
    url = 'http://test.com'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    assert_difference 'ProjectMedia.count', 2 do
      create_project_media media: nil, quote: 'Claim report'
      create_project_media media: nil, url: url
    end
  end

  test "should find media by normalized url" do
    url = 'http://test.com'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
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

  test "should collaborator add a new media" do
    t = create_team
    u = create_user
    tu = create_team_user team: t, user: u, role: 'collaborator'
    with_current_user_and_team(u, t) do
      assert_difference 'ProjectMedia.count' do
        create_project_media team: t, quote: 'Claim report'
      end
    end
  end

  test "should update and destroy project media" do
    u = create_user
    t = create_team
    m = create_valid_media user_id: u.id
    create_team_user team: t, user: u
    pm = create_project_media team: t, media: m, user: u
    with_current_user_and_team(u, t) do
      pm.save!
    end
    u2 = create_user
    tu = create_team_user team: t, user: u2, role: 'editor'
    with_current_user_and_team(u2, t) do
      pm.save!
    end
    assert_nothing_raised do
      with_current_user_and_team(u2, t) do
        pm.destroy!
      end
    end
  end

  test "queries for relationship source" do
    u = create_user
    t = create_team
    pm = create_project_media team: t
    assert_equal pm.relationship_source, pm
  end

  test "checks truthfulness of is_claim?" do
    u = create_user
    t = create_team
    pm = create_project_media team: t
    pm.media.type = "Claim"
    pm.media.save!
    assert pm.is_claim?
  end

  test "checks truthfulness of is_link?" do
    u = create_user
    t = create_team
    pm = create_project_media team: t
    pm.media.type = "Link"
    pm.media.save!
    assert pm.is_link?
  end

  test "checks truthfulness of is_uploaded_image?" do
    u = create_user
    t = create_team
    pm = create_project_media team: t
    pm.media.type = "UploadedImage"
    pm.media.save!
    assert pm.is_uploaded_image?
  end

  test "checks truthfulness of is_image?" do
    u = create_user
    t = create_team
    pm = create_project_media team: t
    pm.media.type = "UploadedImage"
    pm.media.save!
    assert pm.is_image?
  end

  test "checks truthfulness of is_text?" do
    u = create_user
    t = create_team
    pm = create_project_media team: t
    pm.media.type = "Link"
    pm.media.save!
    assert pm.is_text?
  end

  test "checks truthfulness of is_blank?" do
    u = create_user
    t = create_team
    pm = create_project_media team: t
    pm.media.type = "Blank"
    pm.media.save!
    assert pm.is_blank?
  end

  test "checks falsity of is_text?" do
    u = create_user
    t = create_team
    pm = create_project_media team: t
    pm.media.type = "UploadedImage"
    pm.media.save!
    assert !pm.is_text?
  end

  test "checks falsity of is_image?" do
    u = create_user
    t = create_team
    pm = create_project_media team: t
    pm.media_type = "Link"
    assert !pm.is_image?
  end

  test "non members should not read project media in private team" do
    u = create_user
    t = create_team
    pm = create_project_media team: t
    pu = create_user
    pt = create_team private: true
    create_team_user team: pt, user: pu
    pu2 = create_user
    create_team_user team: pt, user: pu2, status: 'requested'
    ppm = create_project_media team: pt
    ProjectMedia.find_if_can(pm.id)
    assert_raise CheckPermissions::AccessDenied do
      with_current_user_and_team(u, pt) do
        ProjectMedia.find_if_can(ppm.id)
      end
    end
    with_current_user_and_team(pu, pt) do
      ProjectMedia.find_if_can(ppm.id)
    end
    assert_raise CheckPermissions::AccessDenied do
      with_current_user_and_team(pu2, pt) do
        ProjectMedia.find_if_can(ppm.id)
      end
    end
  end

  test "should notify Slack when project media is created" do
    t = create_team slug: 'test'
    u = create_user
    tu = create_team_user team: t, user: u, role: 'admin'
    t.set_slack_notifications_enabled = 1; t.set_slack_webhook = 'https://hooks.slack.com/services/123'; t.set_slack_channel = '#test'; t.save!
    with_current_user_and_team(u, t) do
      m = create_valid_media
      pm = create_project_media team: t, media: m
      assert pm.sent_to_slack
      m = create_claim_media
      pm = create_project_media team: t, media: m
      assert pm.sent_to_slack
    end
  end

  test "should not duplicate slack notification for custom slack list settings" do
    Rails.stubs(:env).returns(:production)
    t = create_team slug: 'test'
    t.set_slack_notifications_enabled = 1; t.set_slack_webhook = 'https://hooks.slack.com/services/123'; t.set_slack_channel = '#test'; t.save!
    u = create_user
    p = create_project team: t
    Sidekiq::Testing.fake! do
      with_current_user_and_team(u, t) do
        create_team_user team: t, user: u, role: 'admin'
        SlackNotificationWorker.drain
        assert_equal 0, SlackNotificationWorker.jobs.size
        create_project_media team: t
        assert_equal 1, SlackNotificationWorker.jobs.size
        p.set_slack_events = [{event: 'item_added', slack_channel: '#test'}]
        p.save!
        SlackNotificationWorker.drain
        assert_equal 0, SlackNotificationWorker.jobs.size
        create_project_media project: p.reload
        assert_equal 1, SlackNotificationWorker.jobs.size
        Rails.unstub(:env)
      end
    end
  end

  test "should notify Pusher when project media is created" do
    pm = create_project_media
    assert pm.sent_to_pusher
    t = create_team
    p = create_project team: t
    m = create_claim_media project_id: p.id
    pm = create_project_media project: p, media: m
    assert pm.sent_to_pusher
  end

  test "should notify Pusher when project media is destroyed" do
    pm = create_project_media
    pm.sent_to_pusher = false
    pm.destroy!
    assert pm.sent_to_pusher
  end

  test "should notify Pusher in background" do
    Rails.stubs(:env).returns(:production)
    t = create_team
    p = create_project team:  t
    CheckPusher::Worker.drain
    assert_equal 0, CheckPusher::Worker.jobs.size
    create_project_media project: p
    assert_equal 7, CheckPusher::Worker.jobs.size
    CheckPusher::Worker.drain
    assert_equal 0, CheckPusher::Worker.jobs.size
    Rails.unstub(:env)
  end

  test "should update project media embed data" do
    create_verification_status_stuff
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "test media", "description":"add desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m = create_media(account: create_valid_account, url: url)
    p1 = create_project
    p2 = create_project
    pm1 = create_project_media project: p1, media: m
    pm2 = create_project_media project: p2, media: m
    # fetch data (without overridden)
    data = pm1.media.metadata
    assert_equal 'test media', data['title']
    assert_equal 'add desc', data['description']
    # Update media title and description for pm1
    info = { title: 'Title A', content: 'Desc A' }
    pm1.analysis = info
    info = { title: 'Title AA', content: 'Desc AA' }
    pm1.analysis = info
    # Update media title and description for pm2
    info = { title: 'Title B', content: 'Desc B' }
    pm2.analysis = info
    info = { title: 'Title BB', content: 'Desc BB' }
    pm2.analysis = info
    # fetch data for pm1
    data = pm1.analysis
    assert_equal 'Title AA', data['title']
    assert_equal 'Desc AA', data['content']
    # fetch data for pm2
    data = pm2.analysis
    assert_equal 'Title BB', data['title']
    assert_equal 'Desc BB', data['content']
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
    tu = create_team_user team: t, user: u, role: 'admin'
    p = create_project team: t
    pm = create_project_media project: p, current_user: u
    perm_keys = [
      "read ProjectMedia", "update ProjectMedia", "destroy ProjectMedia", "create Comment",
      "create Tag", "create Task", "create Dynamic", "restore ProjectMedia", "confirm ProjectMedia",
      "embed ProjectMedia", "lock Annotation","update Status", "administer Content", "create Relationship",
      "create Source", "update Source"
    ].sort
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
    # load as editor
    tu.update_column(:role, 'editor')
    assert_equal perm_keys, JSON.parse(pm.permissions).keys.sort
    # load as collaborator
    tu.update_column(:role, 'collaborator')
    assert_equal perm_keys, JSON.parse(pm.permissions).keys.sort
    # load as authenticated
    tu.update_column(:team_id, nil)
    assert_equal perm_keys, JSON.parse(pm.permissions).keys.sort
    User.unstub(:current)
    Team.unstub(:current)
  end

  test "should create embed for uploaded image" do
    ft = create_field_type field_type: 'image_path', label: 'Image Path'
    at = create_annotation_type annotation_type: 'reverse_image', label: 'Reverse Image'
    create_field_instance annotation_type_object: at, name: 'reverse_image_path', label: 'Reverse Image', field_type_object: ft, optional: false
    create_bot name: 'Check Bot'
    create_verification_status_stuff
    pm = ProjectMedia.new
    pm.team_id = create_team.id
    pm.file = File.new(File.join(Rails.root, 'test', 'data', 'rails.png'))
    pm.disable_es_callbacks = true
    pm.media_type = 'UploadedImage'
    pm.save!
    assert_equal 'rails', pm.analysis['title']
  end

  test "should set automatic title for images videos and audios" do
    m = create_uploaded_image file: 'rails.png'
    v = create_uploaded_video file: 'rails.mp4'
    a = create_uploaded_audio file: 'rails.mp3'
    bot = create_team_bot name: 'Smooch', login: 'smooch', set_approved: true
    u = create_user
    team = create_team slug: 'workspace-slug'
    create_team_user team: team, user: bot, role: 'admin'
    create_team_user team: team, user: u, role: 'admin'
    create_verification_status_stuff
    # test with smooch user
    with_current_user_and_team(bot, team) do
      pm = create_project_media team: team, media: m
      count = Media.where(type: 'UploadedImage').joins("INNER JOIN project_medias pm ON medias.id = pm.media_id")
      .where("pm.team_id = ?", team&.id).count
      assert_equal "image-#{team.slug}-#{count}", pm.title
      pm2 = create_project_media team: team, media: v
      count = Media.where(type: 'UploadedVideo').joins("INNER JOIN project_medias pm ON medias.id = pm.media_id")
      .where("pm.team_id = ?", team&.id).count
      assert_equal "video-#{team.slug}-#{count}", pm2.title
      pm3 = create_project_media team: team, media: a
      count = Media.where(type: 'UploadedAudio').joins("INNER JOIN project_medias pm ON medias.id = pm.media_id")
      .where("pm.team_id = ?", team&.id).count
      assert_equal pm3.title, "audio-#{team.slug}-#{count}"
      pm.destroy; pm2.destroy; pm3.destroy
    end
    # test with non smooch user
    with_current_user_and_team(u, team) do
      pm = create_project_media team: team, media: m
      assert_equal pm.title, "rails"
      pm2 = create_project_media team: team, media: v
      assert_equal pm2.title, "rails"
      pm3 = create_project_media team: team, media: a
      assert_equal pm3.title, "rails"
    end
  end

  test "should protect attributes from mass assignment" do
    raw_params = { project: create_project, user: create_user }
    params = ActionController::Parameters.new(raw_params)

    assert_raise ActiveModel::ForbiddenAttributesError do
      ProjectMedia.create(params)
    end
  end

  test "should create auto tasks" do
    t = create_team
    p1 = create_project team: t
    p2 = create_project team: t
    create_team_task team_id: t.id
    create_team_task team_id: t.id, project_ids: [p2.id]
    Sidekiq::Testing.inline! do
      assert_difference 'Task.length', 1 do
        pm1 = create_project_media team: t
      end
      assert_difference 'Task.length', 1 do
        pm1 = create_project_media project: p1
      end
      assert_difference 'Task.length', 2 do
        pm2 = create_project_media project: p2
      end
    end
  end

  test "should collaborator create auto tasks" do
    t = create_team
    create_team_task team_id: t.id
    u = create_user
    tu = create_team_user team: t, user: u, role: 'collaborator'
    Sidekiq::Testing.inline! do
      with_current_user_and_team(u, t) do
        assert_difference 'Task.length' do
          create_project_media team: t
        end
      end
    end
  end

  test "should add or remove team tasks when moving items" do
    t =  create_team
    p = create_project team: t
    p2 = create_project team: t
    tt = create_team_task team_id: t.id, project_ids: []
    tt3 = create_team_task team_id: t.id, project_ids: [p2.id]
    Team.stubs(:current).returns(t)
    Sidekiq::Testing.inline! do
      pm = nil
      assert_difference 'Task.length', 1 do
        pm = create_project_media team: t, project_id: p.id
      end
      assert_difference 'Task.length', 1 do
        pm.project_id = p2.id
        pm.save!
      end
      pm2 = nil
      assert_difference 'Task.length', 2 do
        pm2 = create_project_media team: t, project_id: p2.id
      end
      assert_difference 'Task.length', -1 do
        pm2.project_id = p.id
        pm2.save!
      end
      pm3 = nil
      assert_difference 'Task.length', 1 do
        pm3 = create_project_media team: t
      end
      assert_no_difference 'Task.length' do
        pm3.project_id = p.id
        pm3.save!
      end
      pm4 = nil
      assert_difference 'Task.length', 1 do
        pm4 = create_project_media team: t
      end
      assert_difference 'Task.length', 1 do
        pm4.project_id = p2.id
        pm4.save!
      end
    end
    Team.unstub(:current)
  end

  test "should remove opened team tasks when remove_from project" do
    t =  create_team
    p = create_project team: t
    p2 = create_project team: t
    tt = create_team_task team_id: t.id, project_ids: []
    tt2 = create_team_task team_id: t.id, project_ids: [p2.id]
    tt3 = create_team_task team_id: t.id, project_ids: [p.id, p2.id]
    Team.stubs(:current).returns(t)
    Sidekiq::Testing.inline! do
      pm = nil
      assert_difference 'Task.length', 3 do
        pm = create_project_media team: t, project_id: p2.id
      end
      assert_difference 'Task.length', -2 do
        pm.project_id = nil
        pm.save!
      end
      # should keep completed tasks (task with answer)
      assert_difference 'Task.length', 3 do
        pm = create_project_media team: t, project_id: p2.id
      end
      pm_tt2 = pm.annotations('task').select{|t| t.team_task_id == tt2.id}.last
      at = create_annotation_type annotation_type: 'task_response_free_text', label: 'Task'
      ft1 = create_field_type field_type: 'text_field', label: 'Text Field'
      fi1 = create_field_instance annotation_type_object: at, name: 'response_task', label: 'Response', field_type_object: ft1
      pm_tt2.response = { annotation_type: 'task_response_free_text', set_fields: { response_task: 'Foo' }.to_json }.to_json
      pm_tt2.save!
      assert_difference 'Task.length', -1 do
        pm.project_id = nil
        pm.save!
      end
    end
    Team.unstub(:current)
  end

  test "should have versions" do
    t = create_team
    m = create_valid_media team: t
    u = create_user
    create_team_user user: u, team: t, role: 'admin'
    pm = nil
    User.current = u
    assert_difference 'PaperTrail::Version.count', 1 do
      pm = create_project_media team: t, media: m, user: u, skip_autocreate_source: false
    end
    assert_equal 1, pm.versions.count
    User.current = nil
  end

  test "should get log" do
    create_verification_status_stuff
    create_task_status_stuff(false)
    m = create_valid_media
    u = create_user
    t = create_team
    p = create_project team: t
    p2 = create_project team: t
    create_team_user user: u, team: t, role: 'admin'
    at = create_annotation_type annotation_type: 'response'
    ft2 = DynamicAnnotation::FieldType.where(field_type: 'text').last || create_field_type(field_type: 'text')
    create_field_instance annotation_type_object: at, field_type_object: ft2, name: 'response'
    create_field_instance annotation_type_object: at, field_type_object: ft2, name: 'note'

    with_current_user_and_team(u, t) do
      pm = create_project_media project: p, media: m, user: u
      c = create_comment annotated: pm
      tg = create_tag annotated: pm
      f = create_flag annotated: pm
      s = pm.annotations.where(annotation_type: 'verification_status').last.load
      s.status = 'In Progress'; s.save!
      info = { title: 'Foo' }; pm.analysis = info; pm.save!
      info = { title: 'Bar' }; pm.analysis = info; pm.save!
      t = create_task annotated: pm, annotator: u
      t = Task.find(t.id); t.response = { annotation_type: 'response', set_fields: { response: 'Test', note: 'Test' }.to_json }.to_json; t.save!
      t = Task.find(t.id); t.label = 'Test?'; t.save!
      r = DynamicAnnotation::Field.where(field_name: 'response').last; r.value = 'Test 2'; r.save!
      r = DynamicAnnotation::Field.where(field_name: 'note').last; r.value = 'Test 2'; r.save!

      assert_equal [
        "create_comment", "create_dynamic", "create_dynamic", "create_dynamic", "create_dynamicannotationfield",
        "create_dynamicannotationfield", "create_dynamicannotationfield", "create_dynamicannotationfield",
        "create_dynamicannotationfield", "create_dynamicannotationfield", "create_dynamicannotationfield",
        "create_dynamicannotationfield", "create_dynamicannotationfield", "create_tag", "create_task", "update_dynamicannotationfield",
        "update_dynamicannotationfield", "update_dynamicannotationfield", "update_dynamicannotationfield", "update_dynamicannotationfield", "update_task"
      ].sort, pm.get_versions_log.map(&:event_type).sort
      assert_equal 12, pm.get_versions_log_count
      c.destroy
      assert_equal 12, pm.get_versions_log_count
      tg.destroy
      assert_equal 12, pm.get_versions_log_count
      f.destroy
      assert_equal 12, pm.get_versions_log_count
    end
  end

  test "should get previous project and previous project search object" do
    p1 = create_project
    p2 = create_project
    pm = create_project_media project: p1
    assert_nil pm.project_was
    pm.previous_project_id = p1.id
    pm.save!
    assert_equal p1, pm.project_was
    assert_kind_of CheckSearch, pm.check_search_project_was
  end

  test "should refresh Pender data" do
    create_verification_status_stuff
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url = random_url
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: '{"type":"media","data":{"url":"' + url + '","type":"item","foo":"1"}}')
    WebMock.stub_request(:get, pender_url).with({ query: { url: url, refresh: '1' } }).to_return(body: '{"type":"media","data":{"url":"' + url + '","type":"item","foo":"2"}}')
    m = create_media url: url
    pm = create_project_media media: m
    t1 = pm.updated_at.to_i
    em1 = pm.media.metadata_annotation
    assert_not_nil em1
    em1_data = JSON.parse(em1.get_field_value('metadata_value'))
    assert_equal '1', em1_data['foo']
    assert_equal 1, em1_data['refreshes_count']
    sleep 2
    pm = ProjectMedia.find(pm.id)
    pm.refresh_media = true
    pm.save!
    t2 = pm.reload.updated_at.to_i
    assert t2 > t1
    em2 = pm.media.metadata_annotation
    assert_not_nil em2
    em2_data = JSON.parse(em2.get_field_value('metadata_value'))
    assert_equal '2', em2_data['foo']
    assert_equal 2, em2_data['refreshes_count']
    assert_equal em1, em2
  end

  test "should create or reset archive response when refresh media" do
    create_annotation_type_and_fields('Pender Archive', { 'Response' => ['JSON', false] })
    t = create_team
    t.set_limits_keep = true
    t.save!
    l = create_link team: t
    tb = BotUser.where(name: 'Keep').last
    tb.set_settings = [{ name: 'archive_pender_archive_enabled', type: 'boolean' }]
    tb.set_approved = true
    tb.save!
    tbi = create_team_bot_installation user_id: tb.id, team_id: t.id
    tbi.set_archive_pender_archive_enabled = true
    tbi.save!
    pm = create_project_media media: l, team: t
    assert_difference 'Dynamic.where(annotation_type: "archiver").count' do
      assert_difference 'DynamicAnnotation::Field.where(annotation_type: "archiver", field_name: "pender_archive_response").count' do
        pm.refresh_media = true
        pm.skip_check_ability = true
        pm.save!
      end
    end
    a = pm.get_annotations('archiver').last.load
    f = a.get_field('pender_archive_response')
    f.value = '{"foo":"bar"}'
    f.save!
    v = a.reload.get_field('pender_archive_response').reload.value
    assert_not_equal "{}", v

    assert_no_difference 'Dynamic.where(annotation_type: "archiver").count' do
      assert_no_difference 'DynamicAnnotation::Field.where(annotation_type: "archiver", field_name: "pender_archive_response").count' do
        pm.refresh_media = true
        pm.skip_check_ability = true
        pm.save!
      end
    end

    v = a.reload.get_field('pender_archive_response').reload.value
    assert_equal "{}", v
  end

  test "should get user id for migration" do
    pm = ProjectMedia.new
    assert_nil pm.send(:user_id_callback, 'test@test.com')
    u = create_user(email: 'test@test.com')
    assert_equal u.id, pm.send(:user_id_callback, 'test@test.com')
  end

  test "should get project id for migration" do
    p = create_project
    mapping = Hash.new
    pm = ProjectMedia.new
    assert_nil pm.send(:project_id_callback, 1, mapping)
    mapping[1] = p.id
    assert_equal p.id, pm.send(:project_id_callback, 1, mapping)
  end

  test "should set annotation" do
    ft = DynamicAnnotation::FieldType.where(field_type: 'text').last || create_field_type(field_type: 'text', label: 'Text')
    lt = create_field_type(field_type: 'language', label: 'Language')
    at = create_annotation_type annotation_type: 'translation', label: 'Translation'
    create_field_instance annotation_type_object: at, name: 'translation_text', label: 'Translation Text', field_type_object: ft, optional: false
    create_field_instance annotation_type_object: at, name: 'translation_note', label: 'Translation Note', field_type_object: ft, optional: true
    create_field_instance annotation_type_object: at, name: 'translation_language', label: 'Translation Language', field_type_object: lt, optional: false
    assert_equal 0, Annotation.where(annotation_type: 'translation').count
    create_project_media set_annotation: { annotation_type: 'translation', set_fields: { 'translation_text' => 'Foo', 'translation_note' => 'Bar', 'translation_language' => 'pt' }.to_json }.to_json
    assert_equal 1, Annotation.where(annotation_type: 'translation').count
  end

  test "should have reference to search team object" do
    pm = create_project_media
    assert_kind_of CheckSearch, pm.check_search_team
  end

  test "should get dynamic annotation by type" do
    create_annotation_type annotation_type: 'foo'
    create_annotation_type annotation_type: 'bar'
    pm = create_project_media
    d1 = create_dynamic_annotation annotation_type: 'foo', annotated: pm
    d2 = create_dynamic_annotation annotation_type: 'bar', annotated: pm
    assert_equal d1, pm.get_dynamic_annotation('foo')
    assert_equal d2, pm.get_dynamic_annotation('bar')
  end

  test "should get report type" do
    c = create_claim_media
    l = create_link

    m = create_project_media media: c
    assert_equal 'claim', m.report_type
    m = create_project_media media: l
    assert_equal 'link', m.report_type
  end

  test "should delete project media" do
    t = create_team
    u = create_user
    u2 = create_user
    tu = create_team_user team: t, user: u, role: 'admin'
    tu = create_team_user team: t, user: u2
    pm = create_project_media team: t, quote: 'Claim', user: u2
    at = create_annotation_type annotation_type: 'test'
    ft = create_field_type
    fi = create_field_instance name: 'test', field_type_object: ft, annotation_type_object: at
    a = create_dynamic_annotation annotator: u2, annotated: pm, annotation_type: 'test', set_fields: { test: 'Test' }.to_json
    RequestStore.store[:disable_es_callbacks] = true
    with_current_user_and_team(u, t) do
      pm.disable_es_callbacks = true
      pm.destroy
    end
    RequestStore.store[:disable_es_callbacks] = false
  end

  test "should have Pender embeddable URL" do
    RequestStore[:request] = nil
    t = create_team
    pm = create_project_media team: t
    stub_configs({ 'pender_url' => 'https://pender.fake' }) do
      assert_equal CheckConfig.get('pender_url') + '/api/medias.html?url=' + pm.full_url.to_s, pm.embed_url(false)
    end
    stub_configs({ 'pender_url' => 'https://pender.fake' }) do
      assert_match /#{CheckConfig.get('short_url_host')}/, pm.embed_url
    end
  end

  test "should have oEmbed endpoint" do
    create_annotation_type_and_fields('Embed Code', { 'Copied' => ['Boolean', false] })
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "test media", "description":"add desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m = create_media(account: create_valid_account, url: url)
    pm = create_project_media media: m
    assert_equal 'test media', pm.as_oembed[:title]
  end

  test "should have oEmbed URL" do
    RequestStore[:request] = nil
    t = create_team private: false
    p = create_project team: t
    pm = create_project_media project: p
    stub_configs({ 'checkdesk_base_url' => 'https://checkmedia.org' }) do
      assert_equal "https://checkmedia.org/api/project_medias/#{pm.id}/oembed", pm.oembed_url
    end

    t = create_team private: true
    p = create_project team: t
    pm = create_project_media project: p
    stub_configs({ 'checkdesk_base_url' => 'https://checkmedia.org' }) do
      assert_equal "https://checkmedia.org/api/project_medias/#{pm.id}/oembed", pm.oembed_url
    end
  end

  test "should get author name for oEmbed" do
    u = create_user name: 'Foo Bar'
    pm = create_project_media user: u
    assert_equal 'Foo Bar', pm.author_name
    pm.user = nil
    assert_equal '', pm.author_name
  end

  test "should get author URL for oEmbed" do
    url = 'http://twitter.com/test'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"profile"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    u = create_omniauth_user url: url, provider: 'twitter'
    pm = create_project_media user: u
    assert_equal url, pm.author_url
    pm.user = create_user
    assert_equal '', pm.author_url
    pm.user = nil
    assert_equal '', pm.author_url
  end

  test "should get author picture for oEmbed" do
    u = create_user
    pm = create_project_media user: u
    assert_match /^http/, pm.author_picture
  end

  test "should get author username for oEmbed" do
    u = create_user login: 'test'
    pm = create_project_media user: u
    assert_equal 'test', pm.author_username
    pm.user = nil
    assert_equal '', pm.author_username
  end

  test "should get author role for oEmbed" do
    t = create_team
    u = create_user
    create_team_user user: u, team: t, role: 'collaborator'
    pm = create_project_media team: t, user: u
    assert_equal 'collaborator', pm.author_role
    pm.user = create_user
    assert_equal 'none', pm.author_role
    pm.user = nil
    assert_equal 'none', pm.author_role
  end

  test "should get source URL for external link for oEmbed" do
    url = 'http://twitter.com/test/123456'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l = create_link url: url
    pm = create_project_media media: l
    assert_equal url, pm.source_url
    c = create_claim_media
    pm = create_project_media media: c
    assert_match CheckConfig.get('checkdesk_client'), pm.source_url
  end

  test "should get completed tasks for oEmbed" do
    at = create_annotation_type annotation_type: 'task_response'
    create_field_instance annotation_type_object: at, name: 'response'
    pm = create_project_media
    assert_equal [], pm.completed_tasks
    assert_equal 0, pm.completed_tasks_count
    t1 = create_task annotated: pm
    t1.response = { annotation_type: 'task_response', set_fields: { response: 'Test' }.to_json }.to_json
    t1.save!
    t2 = create_task annotated: pm
    assert_equal [t1], pm.completed_tasks
    assert_equal [t2], pm.open_tasks
    assert_equal 1, pm.completed_tasks_count
  end

  test "should get comments for oEmbed" do
    pm = create_project_media
    assert_equal [], pm.comments
    assert_equal 0, pm.comments_count
    c = create_comment annotated: pm
    assert_equal [c], pm.comments
    assert_equal 1, pm.comments_count
  end

  test "should get provider for oEmbed" do
    url = 'http://twitter.com/test/123456'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l = create_link url: url
    pm = create_project_media media: l
    assert_equal 'Twitter', pm.provider
    c = create_claim_media
    pm = create_project_media media: c
    assert_equal 'Check', pm.provider
  end

  test "should get published time for oEmbed" do
    create_task_status_stuff
    url = 'http://twitter.com/test/123456'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item","published_at":"1989-01-25 08:30:00"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l = create_link url: url
    pm = create_project_media media: l
    assert_equal '25/01/1989', pm.published_at.strftime('%d/%m/%Y')
    c = create_claim_media
    pm = create_project_media media: c
    assert_nil pm.published_at
  end

  test "should get source author for oEmbed" do
    u = create_user name: 'Foo'
    url = 'http://twitter.com/test/123456'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item","author_name":"Bar"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l = create_link url: url
    pm = create_project_media media: l, user: u
    assert_equal 'Bar', pm.source_author[:author_name]
    c = create_claim_media
    pm = create_project_media media: c, user: u
    assert_equal 'Foo', pm.source_author[:author_name]
  end

  test "should render oEmbed HTML" do
    Sidekiq::Testing.inline! do
      pm = create_project_media
      PenderClient::Request.stubs(:get_medias)
      publish_report(pm, {}, nil, {
        use_visual_card: false,
        use_text_message: true,
        use_disclaimer: false,
        disclaimer: '',
        text: '*This* _is_ a ~test~!'
      })
      PenderClient::Request.unstub(:get_medias)
      expected = File.read(File.join(Rails.root, 'test', 'data', "oembed-#{pm.default_project_media_status_type}.html"))
        .gsub(/.*<body/m, '<body')
        .gsub('https?://[^:]*:3000', CheckConfig.get('checkdesk_base_url'))
      actual = ProjectMedia.find(pm.id).html.gsub(/.*<body/m, '<body')
      assert_equal expected, actual
    end
  end

  test "should have metadata for oEmbed" do
    pm = create_project_media
    assert_kind_of String, pm.oembed_metadata
  end

  test "should clear caches when media is updated" do
    create_annotation_type_and_fields('Embed Code', { 'Copied' => ['Boolean', false] })
    pm = create_project_media
    create_dynamic_annotation annotation_type: 'embed_code', annotated: pm
    u = create_user
    ProjectMedia.any_instance.unstub(:clear_caches)
    CcDeville.expects(:clear_cache_for_url).returns(nil).times(52)
    PenderClient::Request.expects(:get_medias).returns(nil).times(16)

    Sidekiq::Testing.inline! do
      create_comment annotated: pm, user: u
      create_task annotated: pm, user: u
    end

    CcDeville.unstub(:clear_cache_for_url)
    PenderClient::Request.unstub(:get_medias)
  end

  test "should respond to auto-tasks on creation" do
    at = create_annotation_type annotation_type: 'task_response_free_text', label: 'Task'
    ft1 = create_field_type field_type: 'text_field', label: 'Text Field'
    fi1 = create_field_instance annotation_type_object: at, name: 'response_free_text', label: 'Response', field_type_object: ft1
    fi2 = create_field_instance annotation_type_object: at, name: 'note_free_text', label: 'Note', field_type_object: ft1

    t = create_team
    p = create_project team: t
    create_team_task team_id: t.id, label: 'When?'
    Sidekiq::Testing.inline! do
      assert_difference 'Task.length', 1 do
        pm = create_project_media project: p, set_tasks_responses: { 'when' => 'Yesterday' }
        task = pm.annotations('task').last
        assert_equal 'Yesterday', task.first_response
      end
    end
  end

  test "should auto-response for Krzana report" do
    at = create_annotation_type annotation_type: 'task_response_geolocation', label: 'Task Response Geolocation'
    geotype = create_field_type field_type: 'geojson', label: 'GeoJSON'
    create_field_instance annotation_type_object: at, name: 'response_geolocation', field_type_object: geotype

    at = create_annotation_type annotation_type: 'task_response_datetime', label: 'Task Response Date Time'
    datetime = create_field_type field_type: 'datetime', label: 'Date Time'
    create_field_instance annotation_type_object: at, name: 'response_datetime', field_type_object: datetime

    at = create_annotation_type annotation_type: 'task_response_free_text', label: 'Task'
    ft1 = create_field_type field_type: 'text_field', label: 'Text Field'
    fi2 = create_field_instance annotation_type_object: at, name: 'response_free_text', label: 'Note', field_type_object: ft1

    t = create_team
    p = create_project team: t
    p2 = create_project team: t
    p3 = create_project team: t
    create_team_task team_id: t.id, label: 'who?', task_type: 'free_text', mapping: { "type" => "free_text", "match" => "$.mentions[?(@['@type'] == 'Person')].name", "prefix" => "Suggested by Krzana: "}, project_ids: [p.id]
    create_team_task team_id: t.id, label: 'where?', task_type: 'geolocation', mapping: { "type" => "geolocation", "match" => "$.mentions[?(@['@type'] == 'Place')]", "prefix" => ""}, project_ids: [p2.id]
    create_team_task team_id: t.id, label: 'when?', type: 'datetime', mapping: { "type" => "datetime", "match" => "dateCreated", "prefix" => ""}, project_ids: [p3.id]

    Sidekiq::Testing.inline! do
      pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
      # test empty json+ld
      url = 'http://test1.com'
      raw = {"json+ld": {}}
      response = {'type':'media','data': {'url': url, 'type': 'item', 'raw': raw}}.to_json
      WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
      pm = create_project_media project: p, url: url
      t = Task.where(annotation_type: 'task', annotated_id: pm.id).last
      assert_nil t.first_response

      # test with non exist value
      url1 = 'http://test11.com'
      raw = { "json+ld": { "mentions": [ { "@type": "Person" } ] } }
      response = {'type':'media','data': {'url': url1, 'type': 'item', 'raw': raw}}.to_json
      WebMock.stub_request(:get, pender_url).with({ query: { url: url1 } }).to_return(body: response)
      pm1 = create_project_media project: p, url: url1
      t = Task.where(annotation_type: 'task', annotated_id: pm1.id).last
      assert_nil t.first_response

      # test with empty value
      url12 = 'http://test12.com'
      raw = { "json+ld": { "mentions": [ { "@type": "Person", "name": "" } ] } }
      response = {'type':'media','data': {'url': url12, 'type': 'item', 'raw': raw}}.to_json
      WebMock.stub_request(:get, pender_url).with({ query: { url: url12 } }).to_return(body: response)
      pm12 = create_project_media project: p, url: url12
      t = Task.where(annotation_type: 'task', annotated_id: pm12.id).last
      assert_nil t.first_response

      # test with single selection
      url2 = 'http://test2.com'
      raw = { "json+ld": { "mentions": [ { "@type": "Person", "name": "first_name" } ] } }
      response = {'type':'media','data': {'url': url2, 'type': 'item', 'raw': raw}}.to_json
      WebMock.stub_request(:get, pender_url).with({ query: { url: url2 } }).to_return(body: response)
      pm2 = create_project_media project: p, url: url2
      t = Task.where(annotation_type: 'task', annotated_id: pm2.id).last
      assert_equal "Suggested by Krzana: first_name", t.first_response

      # test multiple selection (should get first one)
      url3 = 'http://test3.com'
      raw = { "json+ld": { "mentions": [ { "@type": "Person", "name": "first_name" }, { "@type": "Person", "name": "last_name" } ] } }
      response = {'type':'media','data': {'url': url3, 'type': 'item', 'raw': raw}}.to_json
      WebMock.stub_request(:get, pender_url).with({ query: { url: url3 } }).to_return(body: response)
      pm3 = create_project_media project: p, url: url3
      t = Task.where(annotation_type: 'task', annotated_id: pm3.id).last
      assert_equal "Suggested by Krzana: first_name", t.first_response

      # test geolocation mapping
      url4 = 'http://test4.com'
      raw = { "json+ld": {
        "mentions": [ { "name": "Delimara Powerplant", "@type": "Place", "geo": { "latitude": 35.83020073454, "longitude": 14.55602645874 } } ]
      } }
      response = {'type':'media','data': {'url': url4, 'type': 'item', 'raw': raw}}.to_json
      WebMock.stub_request(:get, pender_url).with({ query: { url: url4 } }).to_return(body: response)
      pm4 = create_project_media project: p2, url: url4
      t = Task.where(annotation_type: 'task', annotated_id: pm4.id).last
      # assert_not_nil t.first_response

      # test datetime mapping
      url5 = 'http://test5.com'
      raw = { "json+ld": { "dateCreated": "2017-08-30T14:22:28+00:00" } }
      response = {'type':'media','data': {'url': url5, 'type': 'item', 'raw': raw}}.to_json
      WebMock.stub_request(:get, pender_url).with({ query: { url: url5 } }).to_return(body: response)
      pm5 = create_project_media project: p3, url: url5
      t = Task.where(annotation_type: 'task', annotated_id: pm5.id).last
      assert_not_nil t.first_response
    end
  end

  test "should expose conflict error from Pender" do
    url = 'http://test.com'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"error","data":{"message":"Conflict","code":9}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response, status: 409)
    WebMock.stub_request(:get, pender_url).with({ query: { url: url, refresh: '1' } }).to_return(body: response, status: 409)
    t = create_team
    pm = ProjectMedia.new
    pm.team = t
    pm.url = url
    pm.media_type = 'Link'
    assert !pm.valid?
    assert pm.errors.messages.values.flatten.include? I18n.t('errors.messages.pender_conflict')
  end

  test "should not create project media under archived project" do
    p = create_project archived: 1
    assert_raises ActiveRecord::RecordInvalid do
      create_project_media project_id: p.id
    end
  end

  test "should archive" do
    pm = create_project_media
    assert_equal pm.archived, 0
    pm.archived = 1
    pm.save!
    assert_equal pm.reload.archived, 1
  end

  test "should create annotation when is embedded for the first time" do
    create_annotation_type_and_fields('Embed Code', { 'Copied' => ['Boolean', false] })
    pm = create_project_media
    assert_difference 'PaperTrail::Version.count', 2 do
      pm.as_oembed
    end
    assert_no_difference 'PaperTrail::Version.count' do
      pm.as_oembed
    end
  end

  test "should not crash if mapping value is invalid" do
    assert_nothing_raised do
      pm = ProjectMedia.new
      assert_nil pm.send(:mapping_value, 'foo', 'bar')
    end
  end

  test "should not crash if another user tries to update media" do
    u1 = create_user
    u2 = create_user
    t = create_team
    create_team_user team: t, user: u1, role: 'admin'
    create_team_user team: t, user: u2, role: 'admin'
    pm = nil

    with_current_user_and_team(u1, t) do
      pm = create_project_media team: t, user: u1
      pm = ProjectMedia.find(pm.id)
      info = { title: 'Title' }
      pm.analysis = info
      pm.save!
    end

    with_current_user_and_team(u2, t) do
      pm = ProjectMedia.find(pm.id)
      info = { title: 'Title' }
      pm.analysis = info
      pm.save!
    end
  end

  test "should get claim description only if it has been set" do
    RequestStore.store[:skip_cached_field_update] = false
    create_verification_status_stuff
    c = create_claim_media quote: 'Test'
    pm = create_project_media media: c
    assert_nil pm.reload.description
    info = { content: 'Test 2' }
    pm.analysis = info
    pm.save!
    assert_equal 'Test 2', pm.reload.description
  end

  test "should create pender_archive annotation for link" do
    create_annotation_type_and_fields('Pender Archive', { 'Response' => ['JSON', false] })
    l = create_link
    t = create_team
    t.set_limits_keep = true
    t.save!
    BotUser.delete_all
    tb = create_team_bot login: 'keep', set_settings: [{ name: 'archive_pender_archive_enabled', type: 'boolean' }], set_approved: true
    tbi = create_team_bot_installation user_id: tb.id, team_id: t.id
    tbi.set_archive_pender_archive_enabled = true
    tbi.save!
    p = create_project team: t
    pm = create_project_media media: l, team: t, project_id: p.id
    assert_difference 'Dynamic.where(annotation_type: "archiver").count' do
      assert_difference 'DynamicAnnotation::Field.where(annotation_type: "archiver", field_name: "pender_archive_response").count' do
        pm.create_all_archive_annotations
      end
    end
  end

  test "should not create pender_archive annotation when media is not a link" do
    create_annotation_type_and_fields('Pender Archive', { 'Response' => ['JSON', false] })
    c = create_claim_media
    t = create_team
    t.set_limits_keep = true
    t.save!
    BotUser.delete_all
    tb = create_team_bot login: 'keep', set_settings: [{ name: 'archive_pender_archive_enabled', type: 'boolean' }], set_approved: true
    tbi = create_team_bot_installation user_id: tb.id, team_id: t.id
    tbi.set_archive_pender_archive_enabled = true
    tbi.save!
    p = create_project team: t
    pm = create_project_media media: c, project: p
    assert_no_difference 'Dynamic.where(annotation_type: "archiver").count' do
      assert_no_difference 'DynamicAnnotation::Field.where(annotation_type: "archiver", field_name: "pender_archive_response").count' do
        pm.create_all_archive_annotations
      end
    end
  end

  test "should not create pender_archive annotation when there is no annotation type" do
    l = create_link
    t = create_team
    t.set_limits_keep = true
    t.save!
    p = create_project team: t
    pm = create_project_media media: l, project: p
    assert_no_difference 'Dynamic.where(annotation_type: "archiver").count' do
      assert_no_difference 'DynamicAnnotation::Field.where(annotation_type: "archiver", field_name: "pender_archive_response").count' do
        pm.create_all_archive_annotations
      end
    end
  end

  test "should create pender_archive annotation using information from pender_embed" do
    Link.any_instance.stubs(:pender_embed).returns(OpenStruct.new({ data: { embed: { screenshot_taken: 1, 'archives' => {} }.to_json }.with_indifferent_access }))
    Media.any_instance.stubs(:pender_embed).returns(OpenStruct.new({ data: { embed: { screenshot_taken: 1, 'archives' => {} }.to_json }.with_indifferent_access }))
    create_annotation_type_and_fields('Pender Archive', { 'Response' => ['JSON', false] })
    l = create_link
    t = create_team
    t.set_limits_keep = true
    t.save!
    BotUser.delete_all
    tb = create_team_bot login: 'keep', set_settings: [{ name: 'archive_pender_archive_enabled', type: 'boolean' }], set_approved: true
    tbi = create_team_bot_installation user_id: tb.id, team_id: t.id
    tbi.set_archive_pender_archive_enabled = true
    tbi.save!
    pm = create_project_media media: l, team: t
    assert_difference 'Dynamic.where(annotation_type: "archiver").count' do
      assert_difference 'DynamicAnnotation::Field.where(annotation_type: "archiver", field_name: "pender_archive_response").count' do
        pm.create_all_archive_annotations
      end
    end
    Link.any_instance.unstub(:pender_embed)
    Media.any_instance.unstub(:pender_embed)
  end

  test "should create pender_archive annotation using information from pender_data" do
    create_annotation_type_and_fields('Pender Archive', { 'Response' => ['JSON', false] })
    l = create_link
    t = create_team
    t.set_limits_keep = true
    t.save!
    BotUser.delete_all
    tb = create_team_bot login: 'keep', set_settings: [{ name: 'archive_pender_archive_enabled', type: 'boolean' }], set_approved: true
    tbi = create_team_bot_installation user_id: tb.id, team_id: t.id
    tbi.set_archive_pender_archive_enabled = true
    tbi.save!
    Link.any_instance.stubs(:pender_data).returns({ screenshot_taken: 1, 'archives' => {} })
    Link.any_instance.stubs(:pender_embed).raises(RuntimeError)
    pm = create_project_media media: l, team: t
    assert_difference 'Dynamic.where(annotation_type: "archiver").count' do
      assert_difference 'DynamicAnnotation::Field.where(annotation_type: "archiver", field_name: "pender_archive_response").count' do
        pm.create_all_archive_annotations
      end
    end
    Link.any_instance.unstub(:pender_data)
    Link.any_instance.unstub(:pender_embed)
  end

  test "should update media account when change author_url" do
    setup_elasticsearch
    u = create_user is_admin: true
    t = create_team
    create_team_user user: u, team: t
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url = 'http://www.facebook.com/meedan/posts/123456'
    author_url = 'http://facebook.com/123456'
    author_normal_url = 'http://www.facebook.com/meedan'
    author2_url = 'http://facebook.com/789123'
    author2_normal_url = 'http://www.facebook.com/meedan2'

    data = { url: url, author_url: author_url, type: 'item' }
    response = '{"type":"media","data":' + data.to_json + '}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)

    data = { url: url, author_url: author2_url, type: 'item' }
    response = '{"type":"media","data":' + data.to_json + '}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url, refresh: '1' } }).to_return(body: response)

    data = { url: author_normal_url, provider: 'facebook', picture: 'http://fb/p.png', title: 'Foo', description: 'Bar', type: 'profile' }
    response = '{"type":"media","data":' + data.to_json + '}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: author_url } }).to_return(body: response)

    data = { url: author2_normal_url, provider: 'facebook', picture: 'http://fb/p.png', title: 'NewFoo', description: 'NewBar', type: 'profile' }
    response = '{"type":"media","data":' + data.to_json + '}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: author2_url } }).to_return(body: response)


    m = create_media team: t, url: url, account: nil, account_id: nil
    a = m.account
    p = create_project team: t
    Sidekiq::Testing.inline! do
      pm = create_project_media media: m, project: p, disable_es_callbacks: false
      sleep 2
      pm = ProjectMedia.find(pm.id)
      with_current_user_and_team(u, t) do
        pm.refresh_media = true
        sleep 2
      end
      new_account = m.reload.account
      assert_not_equal a, new_account
      assert_nil Account.where(id: a.id).last
      result = $repository.find(get_es_id(pm))
      assert_equal 1, result['accounts'].size
      assert_equal result['accounts'].first['id'], new_account.id
    end
  end

  test "should update elasticsearch parent_id field" do
    setup_elasticsearch
    t = create_team
    s1 = create_project_media team: t, disable_es_callbacks: false
    s2 = create_project_media team: t, disable_es_callbacks: false
    s3 = create_project_media team: t, disable_es_callbacks: false
    t1 = create_project_media team: t, disable_es_callbacks: false
    t2 = create_project_media team: t, disable_es_callbacks: false
    t3 = create_project_media team: t, disable_es_callbacks: false
    create_relationship source_id: s1.id, target_id: t1.id
    create_relationship source_id: s2.id, target_id: t2.id, relationship_type: Relationship.confirmed_type, disable_es_callbacks: false
    create_relationship source_id: s3.id, target_id: t3.id, relationship_type: Relationship.suggested_type, disable_es_callbacks: false
    sleep 2
    t1_es = $repository.find(get_es_id(t1))
    assert_equal t1.id, t1_es['parent_id']
    t2_es = $repository.find(get_es_id(t2))
    assert_equal s2.id, t2_es['parent_id']
    t3_es = $repository.find(get_es_id(t3))
    assert_equal s3.id, t3_es['parent_id']
  end

  test "should validate media source" do
    t = create_team
    t2 = create_team
    s = create_source team: t
    s2 = create_source team: t2
    pm = nil
    assert_difference 'ProjectMedia.count', 2 do
      create_project_media team: t
      pm = create_project_media team: t, source_id: s.id
    end
    assert_raises ActiveRecord::RecordInvalid do
      pm.source_id = s2.id
      pm.save!
    end
    assert_raises ActiveRecord::RecordInvalid do
      create_project_media team: t, source_id: s2.id, skip_autocreate_source: false
    end
  end

  test "should assign media source using account" do
    u = create_user
    t = create_team
    t2 = create_team
    create_team_user team: t, user: u, role: 'admin'
    create_team_user team: t2, user: u, role: 'admin'
    m = nil
    s = nil
    with_current_user_and_team(u, t) do
      m = create_valid_media
      s = m.account.sources.first
      assert_equal t.id, s.team_id
      pm = create_project_media media: m, team: t, skip_autocreate_source: false
      assert_equal s.id, pm.source_id
    end
    pm = create_project_media media: m, team: t2, skip_autocreate_source: false
    s2 = pm.source
    assert_not_nil pm.source_id
    assert_not_equal s.id, s2.id
    assert_equal t2.id, s2.team_id
    assert_equal m.account, s2.accounts.first
  end

  test "should create media when normalized URL exists" do
    ft = create_field_type field_type: 'image_path', label: 'Image Path'
    at = create_annotation_type annotation_type: 'reverse_image', label: 'Reverse Image'
    create_field_instance annotation_type_object: at, name: 'reverse_image_path', label: 'Reverse Image', field_type_object: ft, optional: false
    create_bot name: 'Check Bot'

    url = 'https://www.facebook.com/Ma3komMona/videos/695409680623722'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    t = create_team
    l = create_link team: t, url: url
    pm = create_project_media media: l

    url = 'https://www.facebook.com/Ma3komMona/videos/vb.268809099950451/695409680623722/?type=3&theater'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"https://www.facebook.com/Ma3komMona/videos/695409680623722","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    assert_difference 'ProjectMedia.count' do
      pm = ProjectMedia.new
      pm.url = url
      pm.media_type = 'Link'
      pm.team = t
      pm.save!
    end
  end


  test "should complete media if there are pending tasks" do
    create_verification_status_stuff
    pm = create_project_media
    s = pm.last_verification_status_obj
    create_task annotated: pm, required: true
    assert_equal 'undetermined', s.reload.get_field('verification_status_status').status
    assert_nothing_raised do
      s.status = 'verified'
      s.save!
    end
  end

  test "should get account from author URL" do
    s = create_source
    pm = create_project_media
    assert_nothing_raised do
      pm.send :account_from_author_url, @url, s
    end
  end

  test "should not move media to active status if status is locked" do
    create_verification_status_stuff
    pm = create_project_media
    assert_equal 'undetermined', pm.last_verification_status
    s = pm.last_verification_status_obj
    s.locked = true
    s.save!
    create_task annotated: pm, disable_update_status: false
    assert_equal 'undetermined', pm.reload.last_verification_status
  end

  test "should have status permission" do
    u = create_user
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p
    with_current_user_and_team(u, t) do
      permissions = JSON.parse(pm.permissions)
      assert permissions.has_key?('update Status')
    end
  end

  test "should not crash if media does not have status" do
    pm = create_project_media
    Annotation.delete_all
    assert_nothing_raised do
      assert_nil pm.last_verification_status_obj
    end
  end

  test "should have relationships and parent and children reports" do
    p = create_project
    s1 = create_project_media project: p
    s2 = create_project_media project: p
    t1 = create_project_media project: p
    t2 = create_project_media project: p
    create_project_media project: p
    create_relationship source_id: s1.id, target_id: t1.id
    create_relationship source_id: s2.id, target_id: t2.id
    assert_equal [t1], s1.targets
    assert_equal [t2], s2.targets
    assert_equal [s1], t1.sources
    assert_equal [s2], t2.sources
  end

  test "should return related" do
    pm = create_project_media
    pm2 = create_project_media
    assert_nil pm.related_to
    pm.related_to_id = pm2.id
    assert_equal pm2, pm.related_to
  end

  test "should include extra attributes in serialized object" do
    pm = create_project_media
    pm.related_to_id = 1
    dump = YAML::dump(pm)
    assert_match /related_to_id/, dump
  end

  test "should skip screenshot archiver" do
    create_annotation_type_and_fields('Pender Archive', { 'Response' => ['JSON', false] })
    l = create_link
    t = create_team
    t.save!
    BotUser.delete_all
    tb = create_team_bot login: 'keep', set_settings: [{ name: 'archive_pender_archive_enabled', type: 'boolean' }], set_approved: true
    tbi = create_team_bot_installation user_id: tb.id, team_id: t.id
    tbi.set_archive_pender_archive_enabled = false
    tbi.save!
    pm = create_project_media project: create_project(team: t), media: l
    assert pm.should_skip_create_archive_annotation?('pender_archive')
  end

  test "should destroy project media when associated_id on version is not valid" do
    m = create_valid_media
    t = create_team
    p = create_project team: t
    u = create_user
    create_team_user user: u, team: t, role: 'admin'
    pm = nil
    with_current_user_and_team(u, t) do
      pm = create_project_media project: p, media: m, user: u
      pm.archived = 1;pm.save
      assert_equal 2, pm.versions.count
    end
    version = pm.versions.last
    version.update_attribute('associated_id', 100)

    assert_nothing_raised do
      pm.destroy
    end
  end

  # https://errbit.test.meedan.com/apps/581a76278583c6341d000b72/problems/5ca644ecf023ba001260e71d
  # https://errbit.test.meedan.com/apps/581a76278583c6341d000b72/problems/5ca4faa1f023ba001260dbae
  test "should create claim with Indian characters" do
    str1 = "_Buy Redmi Note 5 Pro Mobile at *2999 Rs* (95�\u0000off) in Flash Sale._\r\n\r\n*Grab this offer now, Deal valid only for First 1,000 Customers. Visit here to Buy-* http://sndeals.win/"
    str2 = "*प्रधानमंत्री छात्रवृति योजना 2019*\n\n*Scholarship Form for 10th or 12th Open Now*\n\n*Scholarship Amount*\n1.50-60�\u0000- Rs. 5000/-\n2.60-80�\u0000- Rs. 10000/-\n3.Above 80�\u0000- Rs. 25000/-\n\n*सभी 10th और 12th के बच्चो व उनके अभिभावकों को ये SMS भेजे ताकि सभी बच्चे इस योजना का लाभ ले सके*\n\n*Click Here for Apply:*\nhttps://bit.ly/2l71tWl"
    [str1, str2].each do |str|
      assert_difference 'ProjectMedia.count' do
        m = create_claim_media quote: str
        create_project_media media: m
      end
    end
  end

  test "should not create project media with unsafe URL" do
    WebMock.disable_net_connect! allow: [CheckConfig.get('storage_endpoint')]
    url = 'http://unsafe.com/'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"error","data":{"code":12}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    WebMock.stub_request(:get, pender_url).with({ query: { url: url, refresh: '1' } }).to_return(body: response)
    assert_raises ActiveRecord::RecordInvalid do
      pm = create_project_media media: nil, url: url
      assert_equal 12, pm.media.pender_error_code
    end
  end

  test "should get metadata" do
    create_verification_status_stuff
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url = 'https://twitter.com/test/statuses/123456'
    response = { 'type' => 'media', 'data' => { 'url' => url, 'type' => 'item', 'title' => 'Media Title', 'description' => 'Media Description' } }.to_json
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l = create_link url: url
    pm = create_project_media media: l
    assert_equal 'Media Title', l.metadata['title']
    assert_equal 'Media Description', l.metadata['description']
    assert_equal 'Media Title', pm.media.metadata['title']
    assert_equal 'Media Description', pm.media.metadata['description']
    pm.analysis = { title: 'Project Media Title', content: 'Project Media Description' }
    pm.save!
    l = Media.find(l.id)
    pm = ProjectMedia.find(pm.id)
    assert_equal 'Media Title', l.metadata['title']
    assert_equal 'Media Description', l.metadata['description']
    assert_equal 'Project Media Title', pm.analysis['title']
    assert_equal 'Project Media Description', pm.analysis['content']
  end

  test "should cache and sort by demand" do
    setup_elasticsearch
    RequestStore.store[:skip_cached_field_update] = false
    team = create_team
    p = create_project team: team
    create_annotation_type_and_fields('Smooch', { 'Data' => ['JSON', false] })
    pm = create_project_media team: team, project_id: p.id, disable_es_callbacks: false
    ms_pm = get_es_id(pm)
    assert_queries(0, '=') { assert_equal(0, pm.demand) }
    create_dynamic_annotation annotation_type: 'smooch', annotated: pm
    assert_queries(0, '=') { assert_equal(1, pm.demand) }
    pm2 = create_project_media team: team, project_id: p.id, disable_es_callbacks: false
    ms_pm2 = get_es_id(pm2)
    assert_queries(0, '=') { assert_equal(0, pm2.demand) }
    2.times { create_dynamic_annotation(annotation_type: 'smooch', annotated: pm2) }
    assert_queries(0, '=') { assert_equal(2, pm2.demand) }
    # test sorting
    result = $repository.find(ms_pm)
    assert_equal result['demand'], 1
    result = $repository.find(ms_pm2)
    assert_equal result['demand'], 2
    result = CheckSearch.new({projects: [p.id], sort: 'demand'}.to_json)
    assert_equal [pm2.id, pm.id], result.medias.map(&:id)
    result = CheckSearch.new({projects: [p.id], sort: 'demand', sort_type: 'asc'}.to_json)
    assert_equal [pm.id, pm2.id], result.medias.map(&:id)
    r = create_relationship source_id: pm.id, target_id: pm2.id, relationship_type: Relationship.confirmed_type
    assert_equal 1, pm.reload.requests_count
    assert_equal 2, pm2.reload.requests_count
    assert_queries(0, '=') { assert_equal(3, pm.demand) }
    assert_queries(0, '=') { assert_equal(3, pm2.demand) }
    pm3 = create_project_media team: team, project_id: p.id
    ms_pm3 = get_es_id(pm3)
    assert_queries(0, '=') { assert_equal(0, pm3.demand) }
    2.times { create_dynamic_annotation(annotation_type: 'smooch', annotated: pm3) }
    assert_queries(0, '=') { assert_equal(2, pm3.demand) }
    create_relationship source_id: pm.id, target_id: pm3.id, relationship_type: Relationship.confirmed_type
    assert_queries(0, '=') { assert_equal(5, pm.demand) }
    assert_queries(0, '=') { assert_equal(5, pm2.demand) }
    assert_queries(0, '=') { assert_equal(5, pm3.demand) }
    create_dynamic_annotation annotation_type: 'smooch', annotated: pm3
    assert_queries(0, '=') { assert_equal(6, pm.demand) }
    assert_queries(0, '=') { assert_equal(6, pm2.demand) }
    assert_queries(0, '=') { assert_equal(6, pm3.demand) }
    r.destroy!
    assert_queries(0, '=') { assert_equal(4, pm.demand) }
    assert_queries(0, '=') { assert_equal(2, pm2.demand) }
    assert_queries(0, '=') { assert_equal(4, pm3.demand) }
    assert_queries(0, '>') { assert_equal(4, pm.demand(true)) }
    assert_queries(0, '>') { assert_equal(2, pm2.demand(true)) }
    assert_queries(0, '>') { assert_equal(4, pm3.demand(true)) }
  end

  test "should cache number of linked items" do
    RequestStore.store[:skip_cached_field_update] = false
    t = create_team
    pm = create_project_media team: t
    assert_queries(0, '=') { assert_equal(0, pm.linked_items_count) }
    pm2 = create_project_media team: t
    assert_queries(0, '=') { assert_equal(0, pm2.linked_items_count) }
    create_relationship source_id: pm.id, target_id: pm2.id, relationship_type: Relationship.confirmed_type
    assert_queries(0, '=') { assert_equal(1, pm.linked_items_count) }
    assert_queries(0, '=') { assert_equal(0, pm2.linked_items_count) }
    pm3 = create_project_media team: t
    assert_queries(0, '=') { assert_equal(0, pm3.linked_items_count) }
    r = create_relationship source_id: pm.id, target_id: pm3.id, relationship_type: Relationship.confirmed_type
    assert_queries(0, '=') { assert_equal(2, pm.linked_items_count) }
    assert_queries(0, '=') { assert_equal(0, pm2.linked_items_count) }
    assert_queries(0, '=') { assert_equal(0, pm3.linked_items_count) }
    r.destroy!
    assert_queries(0, '=') { assert_equal(1, pm.linked_items_count) }
    assert_queries(0, '=') { assert_equal(0, pm2.linked_items_count) }
    assert_queries(0, '=') { assert_equal(0, pm3.linked_items_count) }
    assert_queries(0, '>') { assert_equal(1, pm.linked_items_count(true)) }
  end

  test "should cache number of requests" do
    RequestStore.store[:skip_cached_field_update] = false
    create_annotation_type_and_fields('Smooch', { 'Data' => ['JSON', false] })
    pm = create_project_media
    assert_queries(0, '=') { assert_equal(0, pm.requests_count) }
    create_dynamic_annotation annotation_type: 'smooch', annotated: pm
    assert_queries(0, '=') { assert_equal(1, pm.requests_count) }
    create_dynamic_annotation annotation_type: 'smooch', annotated: pm
    assert_queries(0, '=') { assert_equal(2, pm.requests_count) }
    assert_queries(0, '>') { assert_equal(2, pm.requests_count(true)) }
  end

  test "should cache last seen" do
    RequestStore.store[:skip_cached_field_update] = false
    team = create_team
    create_annotation_type_and_fields('Smooch', { 'Data' => ['JSON', false] })
    pm = create_project_media team: team
    assert_queries(0, '=') { pm.last_seen }
    assert_equal pm.created_at.to_i, pm.last_seen
    assert_queries(0, '>') do
      assert_equal pm.created_at.to_i, pm.last_seen(true)
    end
    sleep 1
    t = t0 = create_dynamic_annotation(annotation_type: 'smooch', annotated: pm).created_at.to_i
    assert_queries(0, '=') { assert_equal(t, pm.last_seen) }
    sleep 1
    pm2 = create_project_media team: team
    r = create_relationship source_id: pm.id, target_id: pm2.id, relationship_type: Relationship.confirmed_type
    t = pm2.created_at.to_i
    assert_queries(0, '=') { assert_equal(t, pm.last_seen) }
    sleep 1
    t = create_dynamic_annotation(annotation_type: 'smooch', annotated: pm2).created_at.to_i
    assert_queries(0, '=') { assert_equal(t, pm.last_seen) }
    r.destroy!
    assert_queries(0, '=') { assert_equal(t0, pm.last_seen) }
    assert_queries(0, '>') { assert_equal(t0, pm.last_seen(true)) }
  end

  test "should cache status" do
    RequestStore.store[:skip_cached_field_update] = false
    create_verification_status_stuff(false)
    pm = create_project_media
    assert pm.respond_to?(:status)
    assert_queries 0, '=' do
      assert_equal 'undetermined', pm.status
    end
    s = pm.last_verification_status_obj
    s.status = 'verified'
    s.save!
    assert_queries 0, '=' do
      assert_equal 'verified', pm.status
    end
    assert_queries(0, '>') do
      assert_equal 'verified', pm.status(true)
    end
  end

  test "should cache title" do
    create_verification_status_stuff
    RequestStore.store[:skip_cached_field_update] = false
    pm = create_project_media
    pm.analysis = { title: 'Title 1' }
    pm.save!
    assert pm.respond_to?(:title)
    assert_queries 0, '=' do
      assert_equal 'Title 1', pm.title
    end
    pm = create_project_media
    pm.analysis = { title: 'Title 2' }
    pm.save!
    assert_queries 0, '=' do
      assert_equal 'Title 2', pm.title
    end
    assert_queries(0, '>') do
      assert_equal 'Title 2', pm.title(true)
    end
  end

  test "should cache description" do
    create_verification_status_stuff
    RequestStore.store[:skip_cached_field_update] = false
    pm = create_project_media
    pm.analysis = { content: 'Description 1' }
    pm.save!
    assert pm.respond_to?(:description)
    assert_queries 0, '=' do
      assert_equal 'Description 1', pm.description
    end
    pm = create_project_media
    pm.analysis = { content: 'Description 2' }
    pm.save!
    assert_queries 0, '=' do
      assert_equal 'Description 2', pm.description
    end
    assert_queries(0, '>') do
      assert_equal 'Description 2', pm.description(true)
    end
  end

  test "should index sortable fields" do
    RequestStore.store[:skip_cached_field_update] = false
    # sortable fields are [linked_items_count, last_seen and share_count]
    setup_elasticsearch
    create_annotation_type_and_fields('Smooch', { 'Data' => ['JSON', false] })
    team = create_team
    p = create_project team: team
    pm = create_project_media team: team, project_id: p.id, disable_es_callbacks: false
    sleep 3
    result = $repository.find(get_es_id(pm))
    assert_equal 0, result['linked_items_count']
    assert_equal pm.created_at.to_i, result['last_seen']
    t = t0 = create_dynamic_annotation(annotation_type: 'smooch', annotated: pm).created_at.to_i
    result = $repository.find(get_es_id(pm))
    assert_equal t, result['last_seen']

    pm2 = create_project_media team: team, project_id: p.id, disable_es_callbacks: false
    sleep 3
    r = create_relationship source_id: pm.id, target_id: pm2.id, relationship_type: Relationship.confirmed_type
    t = pm2.created_at.to_i
    result = $repository.find(get_es_id(pm))
    result2 = $repository.find(get_es_id(pm2))
    assert_equal 1, result['linked_items_count']
    assert_equal 0, result2['linked_items_count']
    assert_equal t, result['last_seen']

    t = create_dynamic_annotation(annotation_type: 'smooch', annotated: pm2).created_at.to_i
    result = $repository.find(get_es_id(pm))
    assert_equal t, result['last_seen']

    r.destroy!
    result = $repository.find(get_es_id(pm))
    assert_equal t0, result['last_seen']
    result = $repository.find(get_es_id(pm))
    result2 = $repository.find(get_es_id(pm2))
    assert_equal 0, result['linked_items_count']
    assert_equal 0, result2['linked_items_count']
  end

  test "should get team" do
    t = create_team
    pm = create_project_media team: t
    assert_equal t, pm.reload.team
    t2 = create_team
    pm.team = t2
    assert_equal t2, pm.team
    assert_equal t, ProjectMedia.find(pm.id).team
  end

  test "should query media" do
    setup_elasticsearch
    t = create_team
    p = create_project team: t
    p1 = create_project team: t
    p2 = create_project team: t
    pm = create_project_media team: t, project_id: p.id, disable_es_callbacks: false
    create_project_media team: t, project_id: p1.id, disable_es_callbacks: false
    create_project_media team: t, archived: 1, project_id: p.id, disable_es_callbacks: false
    pm = create_project_media team: t, project_id: p1.id, disable_es_callbacks: false
    create_relationship source_id: pm.id, target_id: create_project_media(team: t, project_id: p.id, disable_es_callbacks: false).id, relationship_type: Relationship.confirmed_type
    sleep 2
    assert_equal 4, CheckSearch.new({ team_id: t.id }.to_json).medias.size
    assert_equal 2, CheckSearch.new({ team_id: t.id, projects: [p1.id] }.to_json).medias.size
    assert_equal 0, CheckSearch.new({ team_id: t.id, projects: [p2.id] }.to_json).medias.size
    assert_equal 1, CheckSearch.new({ team_id: t.id, projects: [p1.id], eslimit: 1 }.to_json).medias.size
  end

  test "should handle indexing conflicts" do
    require File.join(Rails.root, 'lib', 'middleware_sidekiq_server_retry')
    Sidekiq::Testing.server_middleware do |chain|
      chain.add ::Middleware::Sidekiq::Server::Retry
    end

    class ElasticSearchTestWorker
      include Sidekiq::Worker
      attr_accessor :retry_count
      sidekiq_options retry: 5

      sidekiq_retries_exhausted do |_msg, e|
        raise e
      end

      def perform(id)
        begin
          client = $repository.client
          client.update index: CheckElasticSearchModel.get_index_alias, id: id, retry_on_conflict: 0, body: { doc: { updated_at: Time.now + rand(50).to_i } }
        rescue Exception => e
          retry_count = retry_count.to_i + 1
          if retry_count < 5
            perform(id)
          else
            raise e
          end
        end
      end
    end

    setup_elasticsearch

    threads = []
    pm = create_project_media media: nil, quote: 'test', disable_es_callbacks: false
    id = get_es_id(pm)
    15.times do |i|
      threads << Thread.start do
        Sidekiq::Testing.inline! do
          ElasticSearchTestWorker.perform_async(id)
        end
      end
    end
    threads.map(&:join)
  end

  test "should localize status" do
    I18n.locale = :pt
    pm = create_project_media
    assert_equal 'Não Iniciado', pm.status_i18n(nil, { locale: 'pt' })
    create_verification_status_stuff(false)
    t = create_team slug: 'test'
    value = {
      label: 'Field label',
      active: 'test',
      default: 'undetermined',
      statuses: [
        { id: 'undetermined', locales: { en: { label: 'Undetermined', description: '' } }, style: { color: 'blue' } },
        { id: 'test', locales: { en: { label: 'Test', description: '' }, pt: { label: 'Teste', description: '' } }, style: { color: 'red' } }
      ]
    }
    t.set_media_verification_statuses(value)
    t.save!
    p = create_project team: t
    pm = create_project_media project: p
    assert_equal 'Undetermined', pm.status_i18n(nil, { locale: 'pt' })
    I18n.stubs(:exists?).with('custom_message_status_test_test').returns(true)
    I18n.stubs(:t).returns('')
    I18n.stubs(:t).with(:custom_message_status_test_test, { locale: 'pt' }).returns('Teste')
    assert_equal 'Teste', pm.status_i18n('test', { locale: 'pt' })
    I18n.unstub(:t)
    I18n.unstub(:exists?)
    I18n.locale = :en
  end

  test "should not throw exception for trashed item if request does not come from a client" do
    pm = create_project_media project: p
    pm.archived = 1
    pm.save!
    User.current = nil
    assert_nothing_raised do
      create_comment annotated: pm
    end
    u = create_user(is_admin: true)
    User.current = u
    assert_raises ActiveRecord::RecordInvalid do
      create_comment annotated: pm
    end
    User.current = nil
  end

  test "should set initial custom status of orphan item" do
    create_verification_status_stuff(false)
    t = create_team
    value = {
      label: 'Status',
      default: 'stop',
      active: 'done',
      statuses: [
        { id: 'stop', label: 'Stopped', completed: '', description: 'Not started yet', style: { backgroundColor: '#a00' } },
        { id: 'done', label: 'Done!', completed: '', description: 'Nothing left to be done here', style: { backgroundColor: '#fc3' } }
      ]
    }
    t.send :set_media_verification_statuses, value
    t.save!
    pm = create_project_media project: nil, team: t
    assert_equal 'stop', pm.last_status
  end

  test "should change custom status of orphan item" do
    create_verification_status_stuff(false)
    t = create_team
    value = {
      label: 'Status',
      default: 'stop',
      active: 'done',
      statuses: [
        { id: 'stop', label: 'Stopped', completed: '', description: 'Not started yet', style: { backgroundColor: '#a00' } },
        { id: 'done', label: 'Done!', completed: '', description: 'Nothing left to be done here', style: { backgroundColor: '#fc3' } }
      ]
    }
    t.send :set_media_verification_statuses, value
    t.save!
    pm = create_project_media project: nil, team: t
    assert_nothing_raised do
      s = pm.last_status_obj
      s.status = 'done'
      s.save!
    end
  end

  test "should clear caches when report is updated" do
    ProjectMedia.any_instance.unstub(:clear_caches)
    Sidekiq::Testing.inline! do
      CcDeville.stubs(:clear_cache_for_url).times(6)
      pm = create_project_media
      pm.skip_clear_cache = false
      RequestStore.store[:skip_clear_cache] = false
      PenderClient::Request.stubs(:get_medias)
      publish_report(pm)
    end
    CcDeville.unstub(:clear_cache_for_url)
    PenderClient::Request.unstub(:get_medias)
    ProjectMedia.any_instance.stubs(:clear_caches)
  end

  test "should generate short URL when getting embed URL for the first time" do
    pm = create_project_media
    assert_difference 'Shortener::ShortenedUrl.count' do
      assert_match /^http/, pm.embed_url
    end
    assert_no_difference 'Shortener::ShortenedUrl.count' do
      assert_match /^http/, pm.embed_url
    end
  end

  test "should validate duplicate based on team" do
    t = create_team
    p = create_project team: t
    t2 = create_team
    p2 = create_project team: t2
    # Create media in different team with no list
    m = create_valid_media
    create_project_media team: t, media: m
    assert_nothing_raised RuntimeError do
      create_project_media team: t2, url: m.url
    end
    # Try to add same item to list
    assert_raises RuntimeError do
      create_project_media team: t, url: m.url
    end
    # Create item in a list then try to add it via all items(with no list)
    m2 = create_valid_media
    create_project_media team:t, project_id: p.id, media: m2
    assert_raises RuntimeError do
      create_project_media team: t, url: m2.url
    end
    # Add same item to list in different team
    assert_nothing_raised RuntimeError do
      create_project_media team: t2, url: m2.url
    end
    # create item in a list then try to add it to all items in different team
    m3 = create_valid_media
    create_project_media team: t, project_id: p.id, media: m3
    assert_nothing_raised RuntimeError do
      create_project_media team: t2, url: m3.url
    end
  end

  test "should restore and confirm item if not super admin" do
    setup_elasticsearch
    t = create_team
    p = create_project team: t
    p3 = create_project team: t
    u = create_user
    create_team_user user: u, team: t, role: 'admin', is_admin: false
    Sidekiq::Testing.inline! do
      # test restore
      pm = create_project_media project: p, disable_es_callbacks: false
      sleep 1
      result = $repository.find(get_es_id(pm))['project_id']
      assert_equal p.id, result
      pm.archived = CheckArchivedFlags::FlagCodes::TRASHED
      pm.save!
      pm = pm.reload
      assert_equal CheckArchivedFlags::FlagCodes::TRASHED, pm.archived
      with_current_user_and_team(u, t) do
        pm.archived = CheckArchivedFlags::FlagCodes::NONE
        pm.disable_es_callbacks = false
        pm.project_id = p3.id
        pm.save!
      end
      pm = pm.reload
      assert_equal CheckArchivedFlags::FlagCodes::NONE, pm.archived
      assert_equal p3.id, pm.project_id
      sleep 1
      result = $repository.find(get_es_id(pm))['project_id']
      assert_equal p3.id, result
      # test confirm
      pm = create_project_media project: p, disable_es_callbacks: false
      sleep 1
      assert_equal p.id, pm.project_id
      result = $repository.find(get_es_id(pm))['project_id']
      assert_equal p.id, result
      pm.archived = CheckArchivedFlags::FlagCodes::UNCONFIRMED
      pm.save!
      pm = pm.reload
      assert_equal CheckArchivedFlags::FlagCodes::UNCONFIRMED, pm.archived
      with_current_user_and_team(u, t) do
        pm.archived = CheckArchivedFlags::FlagCodes::NONE
        pm.disable_es_callbacks = false
        pm.project_id = p3.id
        pm.save!
      end
      pm = pm.reload
      assert_equal CheckArchivedFlags::FlagCodes::NONE, pm.archived
      assert_equal p3.id, pm.project_id
      sleep 1
      result = $repository.find(get_es_id(pm))['project_id']
      assert_equal p3.id, result
    end
  end

  test "should set media type for links" do
    l = create_link
    pm = create_project_media url: l.url
    pm.send :set_media_type
    assert_equal 'Link', pm.media_type
  end

  test "should create link and account using team pender key" do
    t = create_team
    p = create_project(team: t)
    Team.stubs(:current).returns(t)

    url1 = random_url
    author_url1 = random_url
    PenderClient::Request.stubs(:get_medias).with(CheckConfig.get('pender_url_private'), { url: url1 }, CheckConfig.get('pender_key')).returns({"type" => "media","data" => {"url" => url1, "type" => "item", "title" => "Default token", "author_url" => author_url1}})
    PenderClient::Request.stubs(:get_medias).with(CheckConfig.get('pender_url_private'), { url: author_url1 }, CheckConfig.get('pender_key')).returns({"type" => "media","data" => {"url" => author_url1, "type" => "profile", "title" => "Default token", "author_name" => 'Author with default token'}})

    url2 = random_url
    author_url2 = random_url
    PenderClient::Request.stubs(:get_medias).with(CheckConfig.get('pender_url_private'), { url: url2 }, 'specific_token').returns({"type" => "media","data" => {"url" => url2, "type" => "item", "title" => "Specific token", "author_url" => author_url2}})
    PenderClient::Request.stubs(:get_medias).with(CheckConfig.get('pender_url_private'), { url: author_url2 }, 'specific_token').returns({"type" => "media","data" => {"url" => author_url2, "type" => "profile", "title" => "Specific token", "author_name" => 'Author with specific token'}})

    pm = ProjectMedia.create url: url1
    assert_equal 'Default token', ProjectMedia.find(pm.id).media.metadata['title']
    assert_equal 'Author with default token', ProjectMedia.find(pm.id).media.account.metadata['author_name']

    t.set_pender_key = 'specific_token'; t.save!

    pm = ProjectMedia.create! url: url2
    assert_equal 'Specific token', ProjectMedia.find(pm.id).media.metadata['title']
    assert_equal 'Author with specific token', ProjectMedia.find(pm.id).media.account.metadata['author_name']

    Team.unstub(:current)
    PenderClient::Request.unstub(:get_medias)
  end

  test "should refresh using team pender key" do
    t = create_team
    l = create_link
    Team.stubs(:current).returns(t)
    pm = create_project_media media: l, project: create_project(team: t)

    author_url1 = random_url
    PenderClient::Request.stubs(:get_medias).with(CheckConfig.get('pender_url_private'), { url: l.url, refresh: '1' }, CheckConfig.get('pender_key')).returns({"type" => "media","data" => {"url" => l.url, "type" => "item", "title" => "Default token", "author_url" => author_url1}})
    PenderClient::Request.stubs(:get_medias).with(CheckConfig.get('pender_url_private'), { url: author_url1 }, CheckConfig.get('pender_key')).returns({"type" => "media","data" => {"url" => author_url1, "type" => "profile", "title" => "Default token", "author_name" => 'Author with default token'}})

    PenderClient::Request.stubs(:get_medias).with(CheckConfig.get('pender_url_private'), { url: l.url, refresh: '1' }, 'specific_token').returns({"type" => "media","data" => {"url" => l.url, "type" => "item", "title" => "Specific token", "author_url" => author_url1}})
    PenderClient::Request.stubs(:get_medias).with(CheckConfig.get('pender_url_private'), { url: author_url1 }, 'specific_token').returns({"type" => "media","data" => {"url" => author_url1, "type" => "profile", "title" => "Author with specific token", "author_name" => 'Author with specific token'}})

    assert pm.media.metadata['title'].blank?

    pm.refresh_media = true
    pm.save!
    assert_equal 'Default token', ProjectMedia.find(pm.id).media.metadata['title']

    t.set_pender_key = 'specific_token'; t.save!
    pm = ProjectMedia.find(pm.id)
    pm.refresh_media = true; pm.save!
    assert_equal 'Specific token', ProjectMedia.find(pm.id).media.metadata['title']

    Team.unstub(:current)
    PenderClient::Request.unstub(:get_medias)
  end

  test "should not replace one project media by another if not from the same team" do
    old = create_project_media team: create_team, media: Blank.create!
    new = create_project_media team: create_team
    assert_raises RuntimeError do
      old.replace_by(new)
    end
  end

  test "should not replace one project media by another if media is not blank" do
    t = create_team
    old = create_project_media team: t
    new = create_project_media team: t
    assert_raises RuntimeError do
      old.replace_by(new)
    end
  end

  test "should replace a blank project media by another project media" do
    create_verification_status_stuff
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    with_current_user_and_team(u, t) do
      old = create_project_media team: t, media: Blank.create!
      old_r = publish_report(old)
      old_s = old.last_status_obj
      new = create_project_media team: t
      new_r = publish_report(new)
      new_s = new.last_status_obj
      old.replace_by(new)
      assert_nil ProjectMedia.find_by_id(old.id)
      assert_nil Annotation.find_by_id(new_s.id)
      assert_nil Annotation.find_by_id(new_r.id)
      assert_equal old_r, new.get_dynamic_annotation('report_design')
      assert_equal old_s, new.get_dynamic_annotation('verification_status')
    end
  end

  test "should create metrics annotation after create a project media" do
    create_annotation_type_and_fields('Metrics', { 'Data' => ['JSON', false] })
    url = 'https://twitter.com/meedan/status/1321600654750613505'
    response = {"type" => "media","data" => {"url" => url, "type" => "item", "metrics" => {"facebook"=> {"reaction_count" => 2, "comment_count" => 5, "share_count" => 10, "comment_plugin_count" => 0 }}}}

    PenderClient::Request.stubs(:get_medias).with(CheckConfig.get('pender_url_private'), { url: url }, CheckConfig.get('pender_key')).returns(response)
    pm = create_project_media media: nil, url: url
    assert_equal response['data']['metrics'], JSON.parse(pm.get_annotations('metrics').last.load.get_field_value('metrics_data'))
    PenderClient::Request.unstub(:get_medias)
  end

  test "should cache metadata value" do
    at = create_annotation_type annotation_type: 'task_response'
    create_field_instance annotation_type_object: at, name: 'response_test'
    t = create_team
    tt = create_team_task fieldset: 'metadata', team_id: t.id
    pm = create_project_media team: t
    m = pm.get_annotations('task').last.load
    value = random_string
    m.response = { annotation_type: 'task_response', set_fields: { response_test: value }.to_json }.to_json
    m.save!
    assert_queries(0, '=') do
      assert_equal value, pm.send("task_value_#{tt.id}")
    end
    assert_not_nil Rails.cache.read("project_media:task_value:#{pm.id}:#{tt.id}")
    assert_not_nil pm.reload.task_value(tt.id)
    d = m.reload.first_response_obj
    d.destroy!
    assert_nil Rails.cache.read("project_media:task_value:#{pm.id}:#{tt.id}")
    assert_nil pm.reload.task_value(tt.id)
  end

  test "should return item columns values" do
    create_verification_status_stuff
    RequestStore.store[:skip_cached_field_update] = false
    at = create_annotation_type annotation_type: 'task_response'
    create_field_instance annotation_type_object: at, name: 'response_test'
    t = create_team
    tt1 = create_team_task fieldset: 'metadata', team_id: t.id
    tt2 = create_team_task fieldset: 'metadata', team_id: t.id
    t.list_columns = ["task_value_#{tt1.id}", "task_value_#{tt2.id}"]
    t.save!
    pm = create_project_media team: t.reload
    m = pm.get_annotations('task').map(&:load).select{ |t| t.team_task_id == tt1.id }.last
    m.response = { annotation_type: 'task_response', set_fields: { response_test: 'Foo Value' }.to_json }.to_json
    m.save!
    m = pm.get_annotations('task').map(&:load).select{ |t| t.team_task_id == tt2.id }.last
    m.response = { annotation_type: 'task_response', set_fields: { response_test: 'Bar Value' }.to_json }.to_json
    m.save!
    pm.team
    # The only SQL query should be to get the team tasks
    assert_queries(1, '=') do
      values = pm.list_columns_values
      assert_equal 2, values.size
      assert_equal 'Foo Value', values["task_value_#{tt1.id}"]
      assert_equal 'Bar Value', values["task_value_#{tt2.id}"]
    end
    pm2 = create_project_media
    pm2.team
    pm2.media
    # The only SQL query should be to get the team tasks
    assert_queries(1, '=') do
      assert_equal 8, pm2.list_columns_values.keys.size
    end
  end

  test "should return error if method does not exist" do
    pm = create_project_media
    assert_raises NoMethodError do
      pm.send(random_string)
    end
  end

  test "should cache published value" do
    RequestStore.store[:skip_cached_field_update] = false
    create_verification_status_stuff
    pm = create_project_media
    assert_queries(0, '=') { assert_equal 'unpublished', pm.report_status }
    r = publish_report(pm)
    pm = ProjectMedia.find(pm.id)
    assert_queries(0, '=') { assert_equal 'published', pm.report_status }
    r = Dynamic.find(r.id)
    r.set_fields = { state: 'paused' }.to_json
    r.action = 'pause'
    r.save!
    pm = ProjectMedia.find(pm.id)
    assert_queries(0, '=') { assert_equal 'paused', pm.report_status }
    Rails.cache.clear
    assert_queries(0, '>') { assert_equal 'paused', pm.report_status }
  end

  test "should cache tags list" do
    RequestStore.store[:skip_cached_field_update] = false
    pm = create_project_media
    assert_queries(0, '=') { assert_equal '', pm.tags_as_sentence }
    t = create_tag tag: 'foo', annotated: pm
    pm = ProjectMedia.find(pm.id)
    assert_queries(0, '=') { assert_equal 'foo', pm.tags_as_sentence }
    create_tag tag: 'bar', annotated: pm
    pm = ProjectMedia.find(pm.id)
    assert_queries(0, '=') { assert_equal 'foo, bar', pm.tags_as_sentence }
    t.destroy!
    pm = ProjectMedia.find(pm.id)
    assert_queries(0, '=') { assert_equal 'bar', pm.tags_as_sentence }
    Rails.cache.clear
    assert_queries(0, '>') { assert_equal 'bar', pm.tags_as_sentence }
  end

  test "should cache media published at" do
    RequestStore.store[:skip_cached_field_update] = false
    url = 'http://twitter.com/test/123456'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item","published_at":"1989-01-25 08:30:00"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    pm = create_project_media media: nil, url: url
    assert_queries(0, '=') { assert_equal 601720200, pm.media_published_at }
    response = '{"type":"media","data":{"url":"' + url + '","type":"item","published_at":"1989-01-25 08:31:00"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url, refresh: '1' } }).to_return(body: response)
    pm = ProjectMedia.find(pm.id)
    pm.refresh_media = true
    pm.save!
    pm = ProjectMedia.find(pm.id)
    assert_queries(0, '=') { assert_equal 601720260, pm.media_published_at }
  end

  test "should cache number of related items" do
    RequestStore.store[:skip_cached_field_update] = false
    t = create_team
    pm1 = create_project_media team: t
    pm2 = create_project_media team: t
    assert_queries(0, '=') { assert_equal 0, pm1.related_count }
    assert_queries(0, '=') { assert_equal 0, pm2.related_count }
    r = create_relationship source_id: pm1.id, target_id: pm2.id
    assert_queries(0, '=') { assert_equal 1, pm1.related_count }
    assert_queries(0, '=') { assert_equal 1, pm2.related_count }
    r.destroy!
    assert_queries(0, '=') { assert_equal 0, pm1.related_count }
    assert_queries(0, '=') { assert_equal 0, pm2.related_count }
  end

  test "should cache type of media" do
    RequestStore.store[:skip_cached_field_update] = false
    pm = create_project_media
    assert_queries(0, '=') { assert_equal 'Link', pm.type_of_media }
    Rails.cache.clear
    assert_queries(1, '=') { assert_equal 'Link', pm.type_of_media }
    assert_queries(0, '=') { assert_equal 'Link', pm.type_of_media }
  end
end
