require_relative '../test_helper'

class ProjectMedia5Test < ActiveSupport::TestCase
  def setup
    require 'sidekiq/testing'
    Sidekiq::Testing.fake!
    super
    create_team_bot login: 'keep', name: 'Keep'
    create_verification_status_stuff
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

  test "should get status label" do
    pm = create_project_media
    assert_equal 'Unstarted', pm.last_verification_status_label
  end

  test "should respect state transition roles" do
    t = create_team
    value = {
      label: 'Status',
      default: 'stop',
      active: 'done',
      statuses: [
        { id: 'stop', label: 'Stopped', role: 'editor', completed: '', description: 'Not started yet', style: { backgroundColor: '#a00' } },
        { id: 'done', label: 'Done!', role: 'editor', completed: '', description: 'Nothing left to be done here', style: { backgroundColor: '#fc3' } }
      ]
    }
    t.send :set_media_verification_statuses, value
    t.save!
    pm = create_project_media team: t
    s = pm.last_status_obj
    s.status = 'done'
    s.save!
    u = create_user
    create_team_user team: t, user: u, role: 'collaborator'
    assert_equal 'done', pm.reload.status
    with_current_user_and_team(u ,t) do
      a = Annotation.where(annotation_type: 'verification_status', annotated_type: 'ProjectMedia', annotated_id: pm.id).last.load
      f = a.get_field('verification_status_status')
      f.value = 'stop'
      assert_raises ActiveRecord::RecordInvalid do
        f.save!
      end
    end
  end

  test "should have a media not not necessarily a project" do
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

  test "should notify Slack based on slack events" do
    t = create_team slug: 'test'
    u = create_user
    tu = create_team_user team: t, user: u, role: 'admin'
    t.set_slack_notifications_enabled = 1
    t.set_slack_webhook = 'https://hooks.slack.com/services/123'
    slack_notifications = []
    slack_notifications << {
      "label": random_string,
      "event_type": "any_activity",
      "slack_channel": "##{random_string}"
    }
    slack_notifications << {
      "label": random_string,
      "event_type": "status_changed",
      "values": ["in_progress"],
      "slack_channel": "##{random_string}"
    }
    t.slack_notifications = slack_notifications.to_json
    t.save!
    with_current_user_and_team(u, t) do
      m = create_valid_media
      pm = create_project_media team: t, media: m
      assert pm.sent_to_slack
      m = create_claim_media
      pm = create_project_media team: t, media: m
      assert pm.sent_to_slack
      pm = create_project_media team: t
      assert pm.sent_to_slack
      # status changes
      s = pm.last_status_obj
      s.status = 'in_progress'
      s.save!
      assert s.sent_to_slack
    end
  end

  test "should not duplicate slack notification for custom slack list settings" do
    Rails.stubs(:env).returns(:production)
    t = create_team slug: 'test'
    t.set_slack_notifications_enabled = 1
    t.set_slack_webhook = 'https://hooks.slack.com/services/123'
    slack_notifications = []
    slack_notifications << {
      "label": random_string,
      "event_type": "status_changed",
      "values": ["in_progress"],
      "slack_channel": "##{random_string}"
    }
    slack_notifications << {
      "label": random_string,
      "event_type": "any_activity",
      "slack_channel": "##{random_string}"
    }
    t.slack_notifications = slack_notifications.to_json
    t.save!
    u = create_user
    Sidekiq::Testing.fake! do
      create_team_user team: t, user: u, role: 'admin'
      with_current_user_and_team(u, t) do
        SlackNotificationWorker.drain
        assert_equal 0, SlackNotificationWorker.jobs.size
        pm = create_project_media team: t
        assert_equal 1, SlackNotificationWorker.jobs.size
        SlackNotificationWorker.drain
        assert_equal 0, SlackNotificationWorker.jobs.size
        # status changes
        s = pm.last_status_obj
        s.status = 'in_progress'
        s.save!
        assert_equal 1, SlackNotificationWorker.jobs.size
        Rails.unstub(:env)
      end
    end
  end

  test "should notify Pusher when project media is created" do
    pm = create_project_media
    assert pm.sent_to_pusher
    t = create_team
    m = create_claim_media team: t
    pm = create_project_media team: t, media: m
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
    CheckPusher::Worker.drain
    assert_equal 0, CheckPusher::Worker.jobs.size
    create_project_media team: t
    assert_equal 2, CheckPusher::Worker.jobs.size
    CheckPusher::Worker.drain
    assert_equal 0, CheckPusher::Worker.jobs.size
    Rails.unstub(:env)
  end

  test "should update project media embed data" do
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    url = 'http://test.com'
    response = '{"type":"media","data":{"url":"' + url + '/normalized","type":"item", "title": "test media", "description":"add desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    m = create_media(account: create_valid_account, url: url)
    t1 = create_team
    t2 = create_team
    pm1 = create_project_media team: t1, media: m
    pm2 = create_project_media team: t2, media: m
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
    m1 = create_metadata annotated: pm
    m2 = create_metadata annotated: pm
    m3 = create_metadata annotated: nil
    assert_equal [m1.id, m2.id].sort, pm.reload.annotations('metadata').map(&:id).sort
  end

  test "should get permissions" do
    u = create_user
    t = create_team current_user: u
    tu = create_team_user team: t, user: u, role: 'admin'
    pm = create_project_media team: t, current_user: u
    perm_keys = [
      "read ProjectMedia", "update ProjectMedia", "destroy ProjectMedia",
      "create Tag", "create Task", "create Dynamic", "not_spam ProjectMedia", "restore ProjectMedia", "confirm ProjectMedia",
      "embed ProjectMedia", "lock Annotation","update Status", "administer Content", "create Relationship",
      "create Source", "update Source", "create ClaimDescription"
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
    pm = ProjectMedia.new
    pm.team_id = create_team.id
    pm.file = File.new(File.join(Rails.root, 'test', 'data', 'rails.png'))
    pm.disable_es_callbacks = true
    pm.media_type = 'UploadedImage'
    pm.save!
    assert_equal media_filename('rails.png', false), pm.title
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
    # test with smooch user
    with_current_user_and_team(bot, team) do
      pm = create_project_media team: team, media: m
      assert_equal "image-#{team.slug}-#{pm.id}", pm.title
      pm2 = create_project_media team: team, media: v
      assert_equal "video-#{team.slug}-#{pm2.id}", pm2.title
      pm3 = create_project_media team: team, media: a
      assert_equal "audio-#{team.slug}-#{pm3.id}", pm3.title
      pm.destroy; pm2.destroy; pm3.destroy
    end
    # test with non smooch user
    with_current_user_and_team(u, team) do
      pm = create_project_media team: team, media: m
      assert_equal pm.title, media_filename('rails.png', false)
      pm2 = create_project_media team: team, media: v
      assert_equal pm2.title, media_filename('rails.mp4', false)
      pm3 = create_project_media team: team, media: a
      assert_equal pm3.title, media_filename('rails.mp3', false)
    end
  end

  test "should set automatic title for links" do
    bot = create_team_bot name: 'Smooch', login: 'smooch', set_approved: true
    u = create_user
    team = create_team slug: 'workspace-slug'
    create_team_user team: team, user: bot, role: 'admin'
    create_team_user team: team, user: u, role: 'admin'
    # Youtube
    url = random_url
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item", "provider": "youtube", "title":"youtube"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l_youtube = create_link url: url
    # Twitter
    url = random_url
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item", "provider": "twitter", "title":"twitter"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l_twitter = create_link url: url
    # Facebook
    url = random_url
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item", "provider": "facebook", "title":"facebook"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l_facebook = create_link url: url
    # Instagram
    url = random_url
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item", "provider": "instagram", "title":"instagram"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l_instagram = create_link url: url
    # tiktok
    url = random_url
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item", "provider": "tiktok", "title":"tiktok"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l_tiktok = create_link url: url
    # telegram
    url = random_url
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item", "provider": "telegram", "title":"telegram"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l_telegram = create_link url: url
    # weblink
    url = random_url
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item", "provider": "page", "title":"weblink"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l_weblink = create_link url: url
    # test with smooch user
    with_current_user_and_team(bot, team) do
      pm_youtube = create_project_media team: team, media: l_youtube
      assert_equal "youtube-#{team.slug}-#{pm_youtube.id}", pm_youtube.title
      pm_twitter = create_project_media team: team, media: l_twitter
      assert_equal "twitter-#{team.slug}-#{pm_twitter.id}", pm_twitter.title
      pm_facebook = create_project_media team: team, media: l_facebook
      assert_equal "facebook-#{team.slug}-#{pm_facebook.id}", pm_facebook.title
      pm_instagram = create_project_media team: team, media: l_instagram
      assert_equal "instagram-#{team.slug}-#{pm_instagram.id}", pm_instagram.title
      pm_tiktok = create_project_media team: team, media: l_tiktok
      assert_equal "tiktok-#{team.slug}-#{pm_tiktok.id}", pm_tiktok.title
      pm_telegram = create_project_media team: team, media: l_telegram
      assert_equal "telegram-#{team.slug}-#{pm_telegram.id}", pm_telegram.title
      pm_weblink = create_project_media team: team, media: l_weblink
      assert_equal "weblink-#{team.slug}-#{pm_weblink.id}", pm_weblink.title
      [pm_youtube, pm_twitter, pm_facebook, pm_instagram, pm_tiktok, pm_telegram, pm_weblink].each{|pm| pm.destroy!}
    end
    # test with non smooch user
    with_current_user_and_team(u, team) do
      pm_youtube = create_project_media team: team, media: l_youtube
      assert_equal "youtube", pm_youtube.title
      assert_equal "youtube-#{team.slug}-#{pm_youtube.id}", pm_youtube.media_slug
      pm_twitter = create_project_media team: team, media: l_twitter
      assert_equal "twitter", pm_twitter.title
      pm_facebook = create_project_media team: team, media: l_facebook
      assert_equal "facebook", pm_facebook.title
      pm_instagram = create_project_media team: team, media: l_instagram
      assert_equal "instagram", pm_instagram.title
      pm_tiktok = create_project_media team: team, media: l_tiktok
      assert_equal "tiktok", pm_tiktok.title
      assert_equal "tiktok-#{team.slug}-#{pm_tiktok.id}", pm_tiktok.media_slug
      pm_telegram = create_project_media team: team, media: l_telegram
      assert_equal "telegram", pm_telegram.title
      pm_weblink = create_project_media team: team, media: l_weblink
      assert_equal "weblink", pm_weblink.title
      assert_equal "weblink-#{team.slug}-#{pm_weblink.id}", pm_weblink.media_slug
    end
  end

  test "should set automatic title for claims" do
    bot = create_team_bot name: 'Smooch', login: 'smooch', set_approved: true
    u = create_user
    team = create_team slug: 'workspace-slug'
    create_team_user team: team, user: bot, role: 'admin'
    create_team_user team: team, user: u, role: 'admin'
    # test with smooch user
    with_current_user_and_team(bot, team) do
      pm = create_project_media team: team, quote: random_string
      assert_equal "text-#{team.slug}-#{pm.id}", pm.title
      # verify media_slug field
      cd = create_claim_description project_media: pm, description: 'description_text'
      assert_equal pm.get_title, cd.description
      assert_equal "text-#{team.slug}-#{pm.id}", pm.media_slug
    end
    # test with non smooch user
    with_current_user_and_team(u, team) do
      quote = random_string
      pm = create_project_media team: team, quote: quote
      assert_equal quote, pm.title
      # verify media_slug field
      cd = create_claim_description project_media: pm, description: 'description_text'
      assert_equal pm.get_title, cd.description
      assert_equal "text-#{team.slug}-#{pm.id}", pm.media_slug
    end
  end

  test "should protect attributes from mass assignment" do
    raw_params = { team: create_team, user: create_user }
    params = ActionController::Parameters.new(raw_params)

    assert_raise ActiveModel::ForbiddenAttributesError do
      ProjectMedia.create(params)
    end
  end

  test "should create auto tasks" do
    t = create_team
    create_team_task team_id: t.id
    Sidekiq::Testing.inline! do
      assert_difference 'Task.length', 1 do
        pm1 = create_project_media team: t
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

  test "should have versions" do
    with_versioning do
      t = create_team
      m = create_valid_media team: t
      u = create_user
      create_team_user user: u, team: t, role: 'admin'
      pm = nil
      User.current = u
      assert_difference 'PaperTrail::Version.count', 2 do
        pm = create_project_media team: t, media: m, user: u, skip_autocreate_source: false
      end
      assert_difference 'PaperTrail::Version.count' do
        pm.archived = CheckArchivedFlags::FlagCodes::SPAM
        pm.save!
      end
      assert_equal 3, Version.from_partition(t.id).where(item_type: 'ProjectMedia', item_id: pm.id).count
      pm.destroy!
      v = Version.from_partition(t.id).where(item_type: 'ProjectMedia', item_id: pm.id, event: 'destroy').last
      assert_not_nil v
      User.current = nil
    end
  end

  test "should get log" do
    with_versioning do
      m = create_valid_media
      u = create_user
      t = create_team
      create_team_user user: u, team: t, role: 'admin'

      with_current_user_and_team(u, t) do
        pm = create_project_media team: t, media: m, user: u
        t = create_task annotated: pm
        tg = create_tag annotated: pm
        f = create_flag annotated: pm
        s = pm.annotations.where(annotation_type: 'verification_status').last.load
        s.status = 'In Progress'; s.save!
        info = { title: 'Foo' }; pm.analysis = info; pm.save!
        info = { title: 'Bar' }; pm.analysis = info; pm.save!

        assert_equal [
          "create_dynamic", "create_dynamicannotationfield", "create_projectmedia",
          "create_projectmedia", "create_tag", "update_dynamicannotationfield"
        ].sort, pm.get_versions_log.map(&:event_type).sort
      end
    end
  end

  test "should refresh Pender data" do
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

  test "should set media type for links" do
    l = create_link
    pm = create_project_media url: l.url
    pm.send :set_media_type
    assert_equal 'Link', pm.media_type
  end

  test "should create link and account using team pender key" do
    t = create_team
    Team.stubs(:current).returns(t)

    url1 = random_url
    author_url1 = random_url
    PenderClient::Request.stubs(:get_medias).with(CheckConfig.get('pender_url_private'), { url: url1 }, CheckConfig.get('pender_key'), nil).returns({"type" => "media","data" => {"url" => url1, "type" => "item", "title" => "Default token", "author_url" => author_url1}})
    PenderClient::Request.stubs(:get_medias).with(CheckConfig.get('pender_url_private'), { url: author_url1 }, CheckConfig.get('pender_key'), nil).returns({"type" => "media","data" => {"url" => author_url1, "type" => "profile", "title" => "Default token", "author_name" => 'Author with default token'}})

    url2 = random_url
    author_url2 = random_url
    PenderClient::Request.stubs(:get_medias).with(CheckConfig.get('pender_url_private'), { url: url2 }, 'specific_token', nil).returns({"type" => "media","data" => {"url" => url2, "type" => "item", "title" => "Specific token", "author_url" => author_url2}})
    PenderClient::Request.stubs(:get_medias).with(CheckConfig.get('pender_url_private'), { url: author_url2 }, 'specific_token', nil).returns({"type" => "media","data" => {"url" => author_url2, "type" => "profile", "title" => "Specific token", "author_name" => 'Author with specific token'}})

    pm = ProjectMedia.create url: url1, team: t
    assert_equal 'Default token', ProjectMedia.find(pm.id).media.metadata['title']
    assert_equal 'Author with default token', ProjectMedia.find(pm.id).media.account.metadata['author_name']

    t.set_pender_key = 'specific_token'; t.save!

    pm = ProjectMedia.create! url: url2, team: t
    assert_equal 'Specific token', ProjectMedia.find(pm.id).media.metadata['title']
    assert_equal 'Author with specific token', ProjectMedia.find(pm.id).media.account.metadata['author_name']

    Team.unstub(:current)
    PenderClient::Request.unstub(:get_medias)
  end

  test "should refresh using team pender key" do
    t = create_team
    l = create_link
    Team.stubs(:current).returns(t)
    pm = create_project_media media: l, team: t

    author_url1 = random_url
    PenderClient::Request.stubs(:get_medias).with(CheckConfig.get('pender_url_private'), { url: l.url, refresh: '1' }, CheckConfig.get('pender_key'), nil).returns({"type" => "media","data" => {"url" => l.url, "type" => "item", "title" => "Default token", "author_url" => author_url1}})
    PenderClient::Request.stubs(:get_medias).with(CheckConfig.get('pender_url_private'), { url: author_url1 }, CheckConfig.get('pender_key'), nil).returns({"type" => "media","data" => {"url" => author_url1, "type" => "profile", "title" => "Default token", "author_name" => 'Author with default token'}})

    PenderClient::Request.stubs(:get_medias).with(CheckConfig.get('pender_url_private'), { url: l.url, refresh: '1' }, 'specific_token', nil).returns({"type" => "media","data" => {"url" => l.url, "type" => "item", "title" => "Specific token", "author_url" => author_url1}})
    PenderClient::Request.stubs(:get_medias).with(CheckConfig.get('pender_url_private'), { url: author_url1 }, 'specific_token', nil).returns({"type" => "media","data" => {"url" => author_url1, "type" => "profile", "title" => "Author with specific token", "author_name" => 'Author with specific token'}})

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

  test "should save history version even if the original project media does not exist anymore" do
    t = create_team
    old_pm_id = 123456 # something that does not exist anymore
    new = create_project_media team: t
    ProjectMedia.apply_replace_by(old_pm_id, new.id, "{\"author_id\":1234,\"assignments_ids\":[],\"skip_send_report\":true}")

    history = new.versions.first.object_changes
    assert_equal history, { pm_id: [123456,new.id]}.to_json
  end

  test "should replace a blank project media by another project media" do
    setup_elasticsearch
    t = create_team
    u = create_user
    u2 = create_user
    u3 = create_user
    create_team_user team: t, user: u2
    create_team_user team: t, user: u3
    at = create_annotation_type annotation_type: 'task_response_single_choice', label: 'Task'
    ft1 = create_field_type field_type: 'single_choice', label: 'Single Choice'
    fi1 = create_field_instance annotation_type_object: at, name: 'response_task', label: 'Response', field_type_object: ft1
    tag_a = create_tag_text team_id: t.id
    tag_b = create_tag_text team_id: t.id
    tag_c = create_tag_text team_id: t.id
    tt = create_team_task team_id: t.id, task_type: 'single_choice', options: [{ label: 'Foo'}, { label: 'Faa' }]
    tt2 = create_team_task team_id: t.id, task_type: 'single_choice', options: [{ label: 'Optiona a'}, { label: 'Option b' }]
    create_team_user team: t, user: u, role: 'admin'
    with_current_user_and_team(u, t) do
      RequestStore.store[:skip_clear_cache] = true
      old = create_project_media team: t, media: Blank.create!, channel: { main: CheckChannels::ChannelCodes::FETCH }, disable_es_callbacks: false 
      cd = create_claim_description project_media: old
      fc = create_fact_check claim_description: cd
      old_r = publish_report(old)
      old_s = old.last_status_obj
      # assign to
      s_old = Dynamic.find(old_s.id)
      s_old.assigned_to_ids =[u.id, u2.id].join(',')
      s_old.save!
      new = create_project_media team: t, media: create_uploaded_video, disable_es_callbacks: false
      new_r = publish_report(new)
      new_s = new.last_status_obj
      old_tag_a = create_tag tag: tag_a.id, annotated: old
      old_tag_b = create_tag tag: tag_b.id, annotated: old
      new_tag_a = create_tag tag: tag_a.id, annotated: new
      new_tag_c = create_tag tag: tag_c.id, annotated: new
      # add task response
      new_tt = new.annotations('task').select{|t| t.team_task_id == tt.id}.last
      new_tt.response = { annotation_type: 'task_response_single_choice', set_fields: { response_task: 'Foo' }.to_json }.to_json
      new_tt.save!
      new_tt2 = new.annotations('task').select{|t| t.team_task_id == tt2.id}.last
      # assign to
      s = new.last_verification_status_obj
      s = Dynamic.find(s.id)
      s.assigned_to_ids = [u2.id, u3.id].join(',')
      s.save!
      old.replace_by(new)
      assert_nil ProjectMedia.find_by_id(old.id)
      assert_nil Annotation.find_by_id(new_s.id)
      assert_nil Annotation.find_by_id(new_r.id)
      assert_equal old_r, new.get_dynamic_annotation('report_design')
      assert_equal old_s, new.get_dynamic_annotation('verification_status')
      new = new.reload
      assert_equal 'Import', new.creator_name
      data = { "main" => CheckChannels::ChannelCodes::FETCH }
      assert_equal data, new.channel
      assert_equal 3, new.annotations('tag').count
      # Verify replace log entry
      replace_v = Version.from_partition(new.team_id).where(event_type: 'replace_projectmedia', associated_id: new.id, associated_type: 'ProjectMedia')
      assert_not_empty replace_v
      # Verifiy assignment
      s = new.last_verification_status_obj
      assert_equal [u.id, u2.id, u3.id], s.assignments.map(&:user_id).sort
      # Verify ES
      result = $repository.find(get_es_id(new))
      assert_equal [CheckChannels::ChannelCodes::FETCH], result['channel']
      assert_equal [new_tag_a.id, new_tag_c.id, old_tag_b.id].sort, result['tags'].collect{ |tag| tag['id'] }.sort
      assert_equal [new_tt.id, new_tt2.id].sort, result['task_responses'].collect{ |task| task['id'] }.sort
      assert_equal [u.id, u2.id, u3.id], result['assigned_user_ids'].sort
    end
  end

  test "should create metrics annotation after create a project media" do
    create_annotation_type_and_fields('Metrics', { 'Data' => ['JSON', false] })
    url = 'https://twitter.com/meedan/status/1321600654750613505'
    response = {"type" => "media","data" => {"url" => url, "type" => "item", "metrics" => {"facebook"=> {"reaction_count" => 2, "comment_count" => 5, "share_count" => 10, "comment_plugin_count" => 0 }}}}

    PenderClient::Request.stubs(:get_medias).with(CheckConfig.get('pender_url_private'), { url: url }, CheckConfig.get('pender_key'), nil).returns(response)
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

  test "should return error if method does not exist" do
    pm = create_project_media
    assert_raises NoMethodError do
      pm.send(random_string)
    end
  end
end
