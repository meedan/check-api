require_relative '../test_helper'

class ProjectMediaTest < ActiveSupport::TestCase
  def setup
    require 'sidekiq/testing'
    Sidekiq::Testing.fake!
    super
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
    m2 = create_valid_media
    Rails.cache.clear
    tu.update_column(:role, 'journalist')
    pm = nil
    assert_difference 'ProjectMedia.count' do
      pm = create_project_media project: p, media: m2
    end
    m3 = create_valid_media
    m3.user_id = u.id; m3.save!
    assert_difference 'ProjectMedia.count' do
      pm = create_project_media project: p, media: m3
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
    url = 'http://test.com'
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    assert_difference 'ProjectMedia.count', 2 do
      create_project_media media: nil, quote: 'Claim report'
      create_project_media media: nil, url: url
    end
  end

  test "should find media by normalized url" do
    url = 'http://test.com'
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
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

  test "should contributor add a new media" do
    t = create_team
    u = create_user
    p = create_project team: t
    tu = create_team_user team: t, user: u, role: 'contributor'
    with_current_user_and_team(u, t) do
      assert_difference 'ProjectMedia.count' do
        create_project_media project: p, quote: 'Claim report'
      end
    end
  end

  test "should update and destroy project media" do
    u = create_user
    t = create_team
    p = create_project team: t
    p2 = create_project team: t
    m = create_valid_media user_id: u.id
    create_team_user team: t, user: u
    pm = create_project_media project: p, media: m, user: u 
    with_current_user_and_team(u, t) do
      pm.project_id = p2.id; pm.save!
      pm.reload
      assert_equal pm.project_id, p2.id
    end
    u2 = create_user
    tu = create_team_user team: t, user: u2, role: 'editor'
    with_current_user_and_team(u2, t) do
      pm.save!
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
        pm_own.disable_es_callbacks = true
        pm_own.destroy!
      end
    end
    assert_raise RuntimeError do
      with_current_user_and_team(u, t) do
        pm_own.disable_es_callbacks = true
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
    pu2 = create_user
    create_team_user team: pt, user: pu2, status: 'requested'
    pp = create_project team: pt
    m = create_media project: pp
    ppm = create_project_media project: pp, media: m
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
    tu = create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    t.set_slack_notifications_enabled = 1; t.set_slack_webhook = 'https://hooks.slack.com/services/123'; t.set_slack_channel = '#test'; t.save!
    with_current_user_and_team(u, t) do
      m = create_valid_media
      pm = create_project_media project: p, media: m
      assert pm.sent_to_slack
      msg = pm.slack_notification_message
      # verify base URL
      assert_match "#{CONFIG['checkdesk_client']}/#{t.slug}", msg
      # verify notification URL
      match = msg.match(/\/project\/([0-9]+)\/media\/([0-9]+)/)
      assert_equal p.id, match[1].to_i
      assert_equal pm.id, match[2].to_i
      # claim media
      m = create_claim_media
      pm = create_project_media project: p, media: m
      assert pm.sent_to_slack
    end
  end

  test "should notify Slack when project media is created with empty user" do
    t = create_team slug: 'test'
    u = create_user
    tu = create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    t.set_slack_notifications_enabled = 1; t.set_slack_webhook = 'https://hooks.slack.com/services/123'; t.set_slack_channel = '#test'; t.save!
    with_current_user_and_team(nil, t) do
      m = create_valid_media
      pm = create_project_media project: p, media: m, user: nil
      assert pm.sent_to_slack
      msg = pm.slack_notification_message
      # verify base URL
      assert_match "#{CONFIG['checkdesk_client']}/#{t.slug}", msg
      # verify notification URL
      match = msg.match(/\/project\/([0-9]+)\/media\/([0-9]+)/)
      assert_equal p.id, match[1].to_i
      assert_equal pm.id, match[2].to_i
      # claim media
      m = create_claim_media
      pm = create_project_media project: p, media: m, user: nil
      assert pm.sent_to_slack
      msg = pm.slack_notification_message
      assert_match "A new Claim has been added", msg
    end
  end

  test "should verify attribution of Slack notifications" do
    t = create_team slug: 'test'
    u = create_user
    tu = create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    uu = create_user
    m = create_valid_media user: uu
    t.set_slack_notifications_enabled = 1; t.set_slack_webhook = 'https://hooks.slack.com/services/123'; t.set_slack_channel = '#test'; t.save!
    with_current_user_and_team(u, t) do
      pm = create_project_media project: p, media: m, origin: 'http://localhost:3333'
      assert pm.sent_to_slack
      msg = pm.slack_notification_message
      assert_match "*#{u.name}* added a new", msg
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
    CheckNotifications::Pusher::Worker.drain
    assert_equal 0, CheckNotifications::Pusher::Worker.jobs.size
    create_project_media project: p
    assert_equal 4, CheckNotifications::Pusher::Worker.jobs.size
    CheckNotifications::Pusher::Worker.drain
    assert_equal 0, CheckNotifications::Pusher::Worker.jobs.size
    Rails.unstub(:env)
  end

  test "should update project media embed data" do
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
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
    perm_keys = ["read ProjectMedia", "update ProjectMedia", "destroy ProjectMedia", "create Comment", "create Flag",
      "create Tag", "create Task", "create Dynamic", "restore ProjectMedia", "embed ProjectMedia", "lock Annotation",
      "update Status", "administer Content"].sort
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

  test "should set user when project media is created" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'journalist'
    p = create_project team: t, user: create_user
    pm = nil
    with_current_user_and_team(u, t) do
      pm = create_project_media project: p
    end
    assert_equal u, pm.user
  end

  test "should create embed for uploaded image" do
    ft = create_field_type field_type: 'image_path', label: 'Image Path'
    at = create_annotation_type annotation_type: 'reverse_image', label: 'Reverse Image'
    create_field_instance annotation_type_object: at, name: 'reverse_image_path', label: 'Reverse Image', field_type_object: ft, optional: false
    create_bot name: 'Check Bot'
    pm = ProjectMedia.new
    pm.project_id = create_project.id
    pm.file = File.new(File.join(Rails.root, 'test', 'data', 'rails.png'))
    pm.disable_es_callbacks = true
    pm.save!
    assert_equal 'rails.png', pm.embed['title']
  end

  test "should be unique" do
    p = create_project
    m = create_valid_media
    assert_difference 'ProjectMedia.count' do
      create_project_media project: p, media: m
    end
    assert_no_difference 'ProjectMedia.count' do
      assert_raises RuntimeError do
        create_project_media project: p, media: m
      end
    end
  end

  test "should protect attributes from mass assignment" do
    raw_params = { project: create_project, user: create_user }
    params = ActionController::Parameters.new(raw_params)

    assert_raise ActiveModel::ForbiddenAttributesError do
      ProjectMedia.create(params)
    end
  end

  test "should flag overridden attributes" do
    t = create_team
    p = create_project team: t
    url = 'http://test.com'
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item", "title": "org_title", "description":"org_desc"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    pm = create_project_media url: url, project: p
    attributes = pm.overridden_embed_attributes
    attributes.each{|k| assert_not pm.overridden[k]}
    pm.embed={title: 'title'}.to_json
    assert pm.overridden['title']
    attributes = pm.overridden_embed_attributes
    attributes.delete('title')
    attributes.each{|k| assert_not pm.overridden[k]}
    pm.embed={description: 'description'}.to_json
    assert pm.overridden['description']
    attributes.delete('description')
    attributes.each{|k| assert_not pm.overridden[k]}
    pm.embed={username: 'username'}.to_json
    assert pm.overridden['username']
    attributes.delete('username')
    attributes.each{|k| assert_not pm.overridden[k]}
    # Claim media
    pm = create_project_media quote: 'Claim', project: p
    pm.embed={title: 'title', description: 'description', username: 'username'}.to_json
    pm.overridden_embed_attributes.each{|k| assert_not pm.overridden[k]}
  end

  test "should create auto tasks" do
    t = create_team
    p1 = create_project team: t
    p2 = create_project team: t
    t.checklist = [ { 'label' => 'Can you see this automatic task?', 'type' => 'free_text', 'description' => 'This was created automatically', 'projects' => [] }, { 'label' => 'Can you see this automatic task for a project only?', 'type' => 'free_text', 'description' => 'This was created automatically', 'projects' => [p2.id] } ]
    t.save!
    assert_difference 'Task.length', 1 do
      pm1 = create_project_media project: p1
    end
    assert_difference 'Task.length', 2 do
      pm2 = create_project_media project: p2
    end
  end

  test "should contributor create auto tasks" do
    t = create_team
    t.checklist = [ { 'label' => 'Can you see this automatic task?', 'type' => 'free_text', 'description' => 'This was created automatically', 'projects' => [] }]
    t.save!
    u = create_user
    p = create_project team: t
    tu = create_team_user team: t, user: u, role: 'contributor'
    with_current_user_and_team(u, t) do
      assert_difference 'Task.length' do
        create_project_media project: p
      end
    end
  end

  test "should get project source" do
    t = create_team
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m
    assert_not_nil pm.project_source
    c = create_claim_media
    pm = create_project_media project: p, media: c
    assert_nil pm.project_source
    pm = create_project_media project: p, quote: 'Claim', quote_attributions: {name: 'source name'}.to_json
    assert_not_nil pm.project_source
  end

  test "should move related sources after move media to other projects" do
    t = create_team
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m
    ps = pm.project_source
    t2 = create_team
    p2 = create_project team: t2
    pm.project = p2; pm.save!
    assert_equal ps.reload.project_id, p2.id
  end

  test "should have versions" do
    m = create_valid_media
    t = create_team
    p = create_project team: t
    u = create_user
    create_team_user user: u, team: t, role: 'owner'
    pm = nil
    User.current = u
    assert_difference 'PaperTrail::Version.count', 3 do
      pm = create_project_media project: p, media: m, user: u
    end
    assert_equal 1, pm.versions.count
    User.current = nil
  end

  test "should check if project media belonged to a previous project" do
    t = create_team
    u = create_user
    create_team_user user: u, team: t
    p = create_project team: t
    p2 = create_project team: t
    with_current_user_and_team(u, t) do
      pm = create_project_media project: p
      assert ProjectMedia.belonged_to_project(pm.id, p.id)
      pm.project = p2; pm.save!
      assert_equal p2, pm.project
      assert ProjectMedia.belonged_to_project(pm.id, p.id)
    end
  end

  test "should get log" do
    create_verification_status_stuff
    m = create_valid_media
    u = create_user
    t = create_team
    p = create_project team: t
    p2 = create_project team: t
    create_team_user user: u, team: t, role: 'owner'
    at = create_annotation_type annotation_type: 'response'
    ft1 = create_field_type field_type: 'task_reference'
    ft2 = create_field_type field_type: 'text'
    create_field_instance annotation_type_object: at, field_type_object: ft1, name: 'task'
    create_field_instance annotation_type_object: at, field_type_object: ft2, name: 'response'
    create_field_instance annotation_type_object: at, field_type_object: ft2, name: 'note'

    with_current_user_and_team(u, t) do
      pm = create_project_media project: p, media: m, user: u
      c = create_comment annotated: pm
      tg = create_tag annotated: pm
      f = create_flag annotated: pm
      s = pm.annotations.where(annotation_type: 'verification_status').last.load
      s.status = 'In Progress'; s.save!
      e = create_embed annotated: pm, title: 'Test'
      info = { title: 'Foo' }.to_json; pm.embed = info; pm.save!
      info = { title: 'Bar' }.to_json; pm.embed = info; pm.save!
      pm.project_id = p2.id; pm.save!
      t = create_task annotated: pm, annotator: u
      t = Task.find(t.id); t.response = { annotation_type: 'response', set_fields: { response: 'Test', task: t.id.to_s, note: 'Test' }.to_json }.to_json; t.save!
      t = Task.find(t.id); t.label = 'Test?'; t.save!
      r = DynamicAnnotation::Field.where(field_name: 'response').last; r.value = 'Test 2'; r.save!
      r = DynamicAnnotation::Field.where(field_name: 'note').last; r.value = 'Test 2'; r.save!

      assert_equal ["create_dynamic", "create_dynamic", "create_comment", "create_tag", "create_flag", "create_embed", "update_embed", "update_embed", "update_projectmedia", "create_task", "create_dynamicannotationfield", "create_dynamicannotationfield", "create_dynamicannotationfield", "create_dynamicannotationfield", "update_task", "update_task", "update_dynamicannotationfield", "update_dynamicannotationfield", "update_dynamicannotationfield"].sort, pm.get_versions_log.map(&:event_type).sort
      assert_equal 15, pm.get_versions_log_count
      c.destroy
      assert_equal 15, pm.get_versions_log_count
      tg.destroy
      assert_equal 15, pm.get_versions_log_count
      f.destroy
      assert_equal 15, pm.get_versions_log_count
    end
  end

  test "should get previous project" do
    p1 = create_project
    p2 = create_project
    pm = create_project_media project: p1
    assert_equal p1, pm.project
    assert_nil pm.project_was
    pm.previous_project_id = p1.id
    pm.project_id = p2.id
    pm.save!
    assert_equal p1, pm.project_was
    assert_equal p2, pm.project
  end

  test "should create annotation when project media with picture is created" do
    ft = create_field_type field_type: 'image_path', label: 'Image Path'
    at = create_annotation_type annotation_type: 'reverse_image', label: 'Reverse Image'
    create_field_instance annotation_type_object: at, name: 'reverse_image_path', label: 'Reverse Image', field_type_object: ft, optional: false
    create_bot name: 'Check Bot'
    i = create_uploaded_image
    assert_difference "Dynamic.where(annotation_type: 'reverse_image').count" do
      create_project_media media: i
    end
  end

  test "should refresh Pender data" do
    create_translation_status_stuff
    create_verification_status_stuff(false)
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    url = random_url
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: '{"type":"media","data":{"url":"' + url + '","type":"item","foo":"1"}}')
    WebMock.stub_request(:get, pender_url).with({ query: { url: url, refresh: '1' } }).to_return(body: '{"type":"media","data":{"url":"' + url + '","type":"item","foo":"2"}}')
    m = create_media url: url
    pm = create_project_media media: m
    t1 = pm.updated_at.to_i
    em1 = pm.media.pender_embed
    assert_not_nil em1
    assert_equal '1', JSON.parse(em1.data['embed'])['foo']
    assert_equal 1, em1.refreshes_count
    sleep 2
    pm = ProjectMedia.find(pm.id)
    pm.refresh_media = true
    pm.save!
    t2 = pm.reload.updated_at.to_i
    assert t2 > t1
    em2 = pm.media.pender_embed
    assert_equal '2', JSON.parse(em2.data['embed'])['foo']
    assert_equal 2, em2.refreshes_count
    assert_equal em1, em2
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

  test "should have reference to search project object" do
    pm = create_project_media
    assert_kind_of CheckSearch, pm.check_search_project
  end

  test "should have empty mt annotation" do
    ft = DynamicAnnotation::FieldType.where(field_type: 'language').last || create_field_type(field_type: 'language', label: 'Language')
    at = create_annotation_type annotation_type: 'language', label: 'Language'
    create_field_instance annotation_type_object: at, name: 'language', label: 'Language', field_type_object: ft, optional: false

    ft = DynamicAnnotation::FieldType.where(field_type: 'json').last || create_field_type(field_type: 'json', label: 'JSON structure')
    at = create_annotation_type annotation_type: 'mt', label: 'Machine translation'
    create_field_instance annotation_type_object: at, name: 'mt_translations', label: 'Machine translations', field_type_object: ft, optional: false

    create_bot name: 'Alegre Bot'
    t = create_team
    p = create_project team: t
    text = 'Test'
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      url = CONFIG['alegre_host'] + "/api/languages/identification?text=" + text
      response = '{"type":"language","data": [["EN", 1]]}'
      WebMock.stub_request(:get, url).with(:headers => {'X-Alegre-Token'=> CONFIG['alegre_token']}).to_return(body: response)
      pm = create_project_media project: p, quote: text
      mt = pm.annotations.where(annotation_type: 'mt').last
      assert_nil mt
      p.settings = {:languages => ['ar']}; p.save!
      pm = create_project_media project: p, quote: text
      mt = pm.annotations.where(annotation_type: 'mt').last
      assert_not_nil mt
    end
  end

  test "should update mt annotation" do
    ft = DynamicAnnotation::FieldType.where(field_type: 'language').last || create_field_type(field_type: 'language', label: 'Language')
    at = create_annotation_type annotation_type: 'language', label: 'Language'
    create_field_instance annotation_type_object: at, name: 'language', label: 'Language', field_type_object: ft, optional: false

    ft = DynamicAnnotation::FieldType.where(field_type: 'json').last || create_field_type(field_type: 'json', label: 'JSON structure')
    at = create_annotation_type annotation_type: 'mt', label: 'Machine translation'
    create_field_instance annotation_type_object: at, name: 'mt_translations', label: 'Machine translations', field_type_object: ft, optional: false

    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'owner'
    u = User.find(u.id)
    User.stubs(:current).returns(u)
    Team.stubs(:current).returns(t)
    p = create_project team: t
    p.settings = {:languages => ['ar', 'en']}; p.save!
    text = 'Testing'
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      url = CONFIG['alegre_host'] + "/api/languages/identification?text=" + text
      response = '{"type":"language","data": [["EN", 1]]}'
      WebMock.stub_request(:get, url).with(:headers => {'X-Alegre-Token'=> CONFIG['alegre_token']}).to_return(body: response)
      pm = create_project_media project: p, quote: text
      pm2 = create_project_media project: p, quote: text
      Sidekiq::Testing.inline! do
        url = CONFIG['alegre_host'] + "/api/mt?from=en&to=ar&text=" + text
        # Test with machine translation
        response = '{"type":"mt","data": "testing -ar"}'
        # Test handle raising an error
        WebMock.stub_request(:get, url).with(:headers => {'X-Alegre-Token'=> 'in_valid_token'}).to_return(body: response)
        pm.update_mt=1
        mt_field = DynamicAnnotation::Field.joins(:annotation).where('annotations.annotation_type' => 'mt', 'annotations.annotated_type' => pm.class.name, 'annotations.annotated_id' => pm.id.to_s, field_type: 'json').first
        assert_equal 0, JSON.parse(mt_field.value).size
        # Test with valid response
        WebMock.stub_request(:get, url).with(:headers => {'X-Alegre-Token'=> CONFIG['alegre_token']}).to_return(body: response)
        pm.update_mt=1
        mt_field = DynamicAnnotation::Field.joins(:annotation).where('annotations.annotation_type' => 'mt', 'annotations.annotated_type' => pm.class.name, 'annotations.annotated_id' => pm.id.to_s, field_type: 'json').first
        assert_equal 1, JSON.parse(mt_field.value).size
        # Test with type => error
        response = '{"type":"error","data": {"message": "Language not supported"}}'
        WebMock.stub_request(:get, url).with(:headers => {'X-Alegre-Token'=> CONFIG['alegre_token']}).to_return(body: response)
        pm2.update_mt=1
        mt_field = DynamicAnnotation::Field.joins(:annotation).where('annotations.annotation_type' => 'mt', 'annotations.annotated_type' => pm2.class.name, 'annotations.annotated_id' => pm2.id.to_s, field_type: 'json').first
        assert_equal 0, JSON.parse(mt_field.value).size
      end
    end
    User.unstub(:current)
    Team.unstub(:current)
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
    tu = create_team_user team: t, user: u, role: 'owner'
    tu = create_team_user team: t, user: u2
    p = create_project team: t
    pm = create_project_media project: p, quote: 'Claim', user: u2
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

  test "should have oEmbed endpoint" do
    create_annotation_type_and_fields('Embed Code', { 'Copied' => ['Boolean', false] })
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
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
    stub_config('checkdesk_base_url', 'https://checkmedia.org') do
      assert_equal "https://checkmedia.org/api/project_medias/#{pm.id}/oembed", pm.oembed_url
    end

    t = create_team private: true
    p = create_project team: t
    pm = create_project_media project: p
    stub_config('checkdesk_base_url', 'https://checkmedia.org') do
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
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"profile"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    u = create_user url: url, provider: 'twitter'
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
    create_team_user user: u, team: t, role: 'journalist'
    p = create_project team: t
    pm = create_project_media project: p, user: u
    assert_equal 'journalist', pm.author_role
    pm.user = create_user
    assert_equal 'none', pm.author_role
    pm.user = nil
    assert_equal 'none', pm.author_role
  end

  test "should get source URL for external link for oEmbed" do
    url = 'http://twitter.com/test/123456'
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l = create_link url: url
    pm = create_project_media media: l
    assert_equal url, pm.source_url
    c = create_claim_media
    pm = create_project_media media: c
    assert_match CONFIG['checkdesk_client'], pm.source_url
  end

  test "should get resolved tasks for oEmbed" do
    create_annotation_type annotation_type: 'response'
    pm = create_project_media
    assert_equal [], pm.completed_tasks
    assert_equal 0, pm.completed_tasks_count
    t1 = create_task annotated: pm
    t1.response = { annotation_type: 'response', set_fields: {} }.to_json
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
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l = create_link url: url
    pm = create_project_media media: l
    assert_equal 'Twitter', pm.provider
    c = create_claim_media
    pm = create_project_media media: c
    stub_config('app_name', 'Check') do
      assert_equal 'Check', pm.provider
    end
  end

  test "should get published time for oEmbed" do
    create_translation_status_stuff
    url = 'http://twitter.com/test/123456'
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item","published_at":"1989-01-25 08:30:00"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l = create_link url: url
    pm = create_project_media media: l
    assert_equal '25/01/1989', pm.published_at.strftime('%d/%m/%Y')
    c = create_claim_media
    pm = create_project_media media: c
    assert_equal Time.now.strftime('%d/%m/%Y'), pm.published_at.strftime('%d/%m/%Y')
  end

  test "should get source author for oEmbed" do
    u = create_user name: 'Foo'
    url = 'http://twitter.com/test/123456'
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
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
    create_translation_status_stuff
    create_verification_status_stuff(false)
    Bot::Alegre.delete_all
    u = create_user login: 'test', name: 'Test', profile_image: 'http://profile.picture'
    c = create_claim_media quote: 'Test'
    t = create_team name: 'Test Team', slug: 'test-team'
    p = create_project title: 'Test Project', team: t
    pm = create_project_media media: c, user: u, project: p
    create_comment text: 'A comment', annotated: pm
    create_comment text: 'A second comment', annotated: pm
    at = create_annotation_type annotation_type: 'task_response_free_text', label: 'Task'
    ft1 = create_field_type field_type: 'text_field', label: 'Text Field'
    ft2 = create_field_type field_type: 'task_reference', label: 'Task Reference'
    fi1 = create_field_instance annotation_type_object: at, name: 'response_task', label: 'Response', field_type_object: ft1
    fi2 = create_field_instance annotation_type_object: at, name: 'note_task', label: 'Note', field_type_object: ft1
    fi3 = create_field_instance annotation_type_object: at, name: 'task_reference', label: 'Task', field_type_object: ft2
    t = create_task annotated: pm
    t.response = { annotation_type: 'task_response_free_text', set_fields: { response_task: 'Task response', task_reference: t.id.to_s }.to_json }.to_json
    t.save!

    ProjectMedia.any_instance.stubs(:created_at).returns(Time.parse('2016-06-05'))
    ProjectMedia.any_instance.stubs(:updated_at).returns(Time.parse('2016-06-05'))

    expected = File.read(File.join(Rails.root, 'test', 'data', "oembed-#{pm.default_media_status_type}.html")).gsub(/project\/[0-9]+\/media\/[0-9]+/, 'url').gsub(/.*<body/m, '<body').gsub('http://localhost:3333', CONFIG['checkdesk_client']).gsub('http://localhost:3000', CONFIG['checkdesk_base_url'])
    actual = ProjectMedia.find(pm.id).html.gsub(/project\/[0-9]+\/media\/[0-9]+/, 'url').gsub(/.*<body/m, '<body')

    assert_equal expected, actual

    ProjectMedia.any_instance.unstub(:created_at)
    ProjectMedia.any_instance.unstub(:updated_at)
  end

  test "should have metadata for oEmbed" do
    pm = create_project_media
    assert_kind_of String, pm.metadata
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
    ft2 = create_field_type field_type: 'task_reference', label: 'Task Reference'
    fi1 = create_field_instance annotation_type_object: at, name: 'response_free_text', label: 'Response', field_type_object: ft1
    fi2 = create_field_instance annotation_type_object: at, name: 'note_free_text', label: 'Note', field_type_object: ft1
    fi3 = create_field_instance annotation_type_object: at, name: 'task_free_text', label: 'Task', field_type_object: ft2

    t = create_team
    p = create_project team: t
    t.checklist = [ { 'label' => 'When?', 'type' => 'free_text', 'description' => '', 'projects' => [] } ]
    t.save!
    pm = create_project_media(project: p, set_tasks_responses: { 'when' => 'Yesterday' })

    t = Task.where(annotation_type: 'task').last
    assert_equal 'Yesterday', t.first_response
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
    ft2 = create_field_type field_type: 'task_reference', label: 'Task Reference'
    fi1 = create_field_instance annotation_type_object: at, name: 'response_free_text', label: 'Response', field_type_object: ft1
    fi2 = create_field_instance annotation_type_object: at, name: 'note_free_text', label: 'Note', field_type_object: ft1
    fi3 = create_field_instance annotation_type_object: at, name: 'task_free_text', label: 'Task', field_type_object: ft2

    t = create_team
    p = create_project team: t
    p2 = create_project team: t
    p3 = create_project team: t
    t.checklist = [ { "label" => "who?", "type" => "free_text", "description" => "",
      "mapping" => { "type" => "free_text", "match" => "$.mentions[?(@['@type'] == 'Person')].name", "prefix" => "Suggested by Krzana: "},
      "projects" => [p.id] },
      { "label" => "where?", "type" => "geolocation", "description" => "",
      "mapping" => { "type" => "geolocation", "match" => "$.mentions[?(@['@type'] == 'Place')]", "prefix" => ""},
      "projects" => [p2.id] },
      { "label" => "when?", "type" => "datetime", "description" => "",
      "mapping" => { "type" => "datetime", "match" => "dateCreated", "prefix" => ""},
      "projects" => [p3.id] }
    ]
    t.save!

    pender_url = CONFIG['pender_url_private'] + '/api/medias'
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
    # assert_not_nil t.first_response
  end

  test "should expose conflict error from Pender" do
    url = 'http://test.com'
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    response = '{"type":"error","data":{"message":"Conflict","code":9}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response, status: 409)
    p = create_project
    pm = ProjectMedia.new
    pm.project = p
    pm.url = url
    assert !pm.valid?
    assert pm.errors.messages.values.flatten.include?('This link is already being parsed, please try again in a few seconds.')
  end

  test "should create project source" do
    t = create_team
    p = create_project team: t
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    media_url = 'http://www.facebook.com/meedan/posts/123456'
    media2_url = 'http://www.facebook.com/meedan/posts/456789'
    author_url = 'http://facebook.com/123456'

    data = { url: media_url, author_url: author_url, type: 'item' }
    response = '{"type":"media","data":' + data.to_json + '}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: media_url } }).to_return(body: response)

    data = { url: media2_url, author_url: author_url, type: 'item' }
    response = '{"type":"media","data":' + data.to_json + '}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: media2_url } }).to_return(body: response)

    data = { url: author_url, provider: 'facebook', picture: 'http://fb/p.png', author_name: 'UNIVERSITÄT', username: 'username', title: 'Foo', description: 'Bar', type: 'profile' }
    response = '{"type":"media","data":' + data.to_json + '}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: author_url } }).to_return(body: response)

    with_current_user_and_team(u, t) do
      assert_difference 'ProjectSource.count' do
        create_project_media project: p, url: media_url
      end
      # should not duplicate ProjectSource for same account
      assert_no_difference 'ProjectSource.count' do
        create_project_media project: p, url: media2_url
      end
      assert_no_difference 'ProjectSource.count' do
        create_project_media project: p, quote: 'Claim', quote_attributions: {name: 'UNIVERSITÄT'}.to_json
      end
    end
    # test move media to project with same source
    p2 = create_project team: t
    p3 = create_project team: t
    with_current_user_and_team(u, t) do
      pm = create_project_media project: p2, url: media_url
      pm2 = create_project_media project: p3, url: media2_url
      assert_nothing_raised do
        pm.project = p3
        pm.save!
      end
    end
  end

  test "should set quote attributions" do
    t = create_team
    p = create_project team: t
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    with_current_user_and_team(u, t) do
      assert_difference 'ClaimSource.count', 2 do
        pm = create_project_media project: p, quote: 'Claim', quote_attributions: {name: 'source name'}.to_json
        s = pm.project_source.source
        assert_not_nil pm.project_source
        assert_equal s.name, 'source name'
        pm2 = create_project_media project: p, quote: 'Claim 2', quote_attributions: {name: 'source name'}.to_json
        assert_equal pm2.project_source.source, s
      end
    end
  end

  test "should not get project source" do
    p = create_project
    l = create_link
    a = l.account
    a.destroy
    l = Link.find(l.id)
    pm = create_project_media project: p, media: l
    assert_nil pm.send(:get_project_source, p.id)
  end

  test "should not create project media under archived project" do
    p = create_project
    p.archived = true
    p.save!

    assert_raises ActiveRecord::RecordInvalid do
      create_project_media project: p
    end
  end

  test "should archive" do
    pm = create_project_media
    assert !pm.archived
    pm.archived = true
    pm.save!
    assert pm.reload.archived
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

  test "should not create media through browser extension if team is not allowed to" do
    t = create_team
    t.set_limits_browser_extension = false
    t.save!
    p = create_project team: t
    assert_raises ActiveRecord::RecordInvalid do
      RequestStore.stubs(:[]).with(:request).returns(OpenStruct.new({ headers: { 'X-Check-Client' => 'browser-extension' } }))
      create_project_media project: p
      RequestStore.unstub(:[])
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
    p = create_project team: t
    create_team_user team: t, user: u1, role: 'owner'
    create_team_user team: t, user: u2, role: 'owner'
    pm = nil
    
    with_current_user_and_team(u1, t) do
      pm = create_project_media project: p, user: u1
      pm = ProjectMedia.find(pm.id)
      info = { title: 'Title' }.to_json
      pm.embed = info
      pm.save!
    end
    
    with_current_user_and_team(u2, t) do
      pm = ProjectMedia.find(pm.id)
      info = { title: 'Title' }.to_json
      pm.embed = info
      pm.save!
    end
    
    assert_nothing_raised do
      embed = pm.get_annotations('embed').last.load
      embed.title_is_overridden?
    end
  end

  test "should return custom status HTML and color for embed" do
    create_translation_status_stuff
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
    pm = create_project_media
    t.send "set_media_#{pm.default_media_status_type.pluralize}", value
    t.save!
    p = create_project team: t
    pm = create_project_media project: p
    assert_equal 'stop', pm.last_status
    assert_equal '<span id="oembed__status">Stopped</span>', pm.last_status_html
    assert_equal '#a00', pm.last_status_color
    s = pm.last_status_obj
    s.status = 'done'
    s.save!
    assert_equal '<span id="oembed__status">Done!</span>', pm.last_status_html
    assert_equal '#fc3', pm.last_status_color
  end

  test "should return core status HTML and color for embed" do
    create_translation_status_stuff
    create_verification_status_stuff(false)
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p
    assert_equal "<span id=\"oembed__status\" class=\"l\">status_#{pm.last_status}</span>", pm.last_status_html
    assert_equal '#518FFF', pm.last_status_color.upcase
    s = pm.last_status_obj
    s.status = 'in_progress'
    s.save!
    assert_equal '<span id="oembed__status" class="l">status_in_progress</span>', pm.last_status_html
    assert_equal '#FFBB5D', pm.last_status_color.upcase
  end

  test "should get description" do
    c = create_claim_media quote: 'Test'
    pm = create_project_media media: c
    assert_equal 'Test', pm.reload.description
    info = { description: 'Test 2' }.to_json
    pm.embed = info
    pm.save!
    assert_equal 'Test 2', pm.reload.description
  end

  test "should create pender_archive annotation when link is created" do
    create_annotation_type_and_fields('Pender Archive', { 'Response' => ['JSON', false] })
    l = create_link
    t = create_team
    t.archive_pender_archive_enabled = 1
    t.set_limits_keep_screenshot = true
    t.save!
    p = create_project team: t
    assert_difference 'Dynamic.where(annotation_type: "pender_archive").count' do
      create_project_media media: l, project: p
    end
  end

  test "should not create pender_archive annotation when media is created if media is not a link" do
    create_annotation_type_and_fields('Pender Archive', { 'Response' => ['JSON', false] })
    c = create_claim_media
    t = create_team
    t.archive_pender_archive_enabled = 1
    t.set_limits_keep_screenshot = true
    t.save!
    p = create_project team: t
    assert_no_difference 'Dynamic.where(annotation_type: "pender_archive").count' do
      create_project_media media: c, project: p
    end
  end

  test "should not create pender_archive annotation when link is created if there is no annotation type" do
    l = create_link
    t = create_team
    t.archive_pender_archive_enabled = 1
    t.set_limits_keep_screenshot = true
    t.save!
    p = create_project team: t
    assert_no_difference 'Dynamic.where(annotation_type: "pender_archive").count' do
      create_project_media media: l, project: p
    end
  end

  test "should not create pender_archive annotation when link is created if team is not allowed" do
    create_annotation_type_and_fields('Pender Archive', { 'Response' => ['JSON', false] })
    l = create_link
    t = create_team
    t.archive_pender_archive_enabled = 1
    t.set_limits_keep_screenshot = false
    t.save!
    p = create_project team: t
    assert_no_difference 'Dynamic.where(annotation_type: "pender_archive").count' do
      create_project_media media: l, project: p
    end
  end

  test "should not create pender_archive annotation when link is created if archiver is not enabled" do
    create_annotation_type_and_fields('Pender Archive', { 'Response' => ['JSON', false] })
    l = create_link
    t = create_team
    t.archive_pender_archive_enabled = 0
    t.set_limits_keep_screenshot = true
    t.save!
    p = create_project team: t
    assert_no_difference 'Dynamic.where(annotation_type: "pender_archive").count' do
      create_project_media media: l, project: p
    end
  end

  test "should create pender_archive annotation when link is created using information from pender_embed" do
    create_annotation_type_and_fields('Pender Archive', { 'Response' => ['JSON', false] })
    l = create_link
    t = create_team
    t.archive_pender_archive_enabled = 1
    t.set_limits_keep_screenshot = true
    t.save!
    p = create_project team: t
    Link.any_instance.stubs(:pender_embed).returns(OpenStruct.new({ data: { embed: { screenshot_taken: 1, 'archives' => {} }.to_json } }))
    assert_difference 'Dynamic.where(annotation_type: "pender_archive").count' do
      create_project_media media: l, project: p
    end
    Link.any_instance.unstub(:pender_embed)
  end

  test "should create pender_archive annotation when link is created using information from pender_data" do
    create_annotation_type_and_fields('Pender Archive', { 'Response' => ['JSON', false] })
    l = create_link
    t = create_team
    t.archive_pender_archive_enabled = 1
    t.set_limits_keep_screenshot = true
    t.save!
    p = create_project team: t
    Link.any_instance.stubs(:pender_data).returns({ screenshot_taken: 1, 'archives' => {} })
    Link.any_instance.stubs(:pender_embed).raises(RuntimeError)
    assert_difference 'Dynamic.where(annotation_type: "pender_archive").count' do
      create_project_media media: l, project: p
    end
    Link.any_instance.unstub(:pender_data)
    Link.any_instance.unstub(:pender_embed)
  end

  test "should get number of contributing users" do
    create_verification_status_stuff
    pm = create_project_media
    create_comment annotated: pm, annotator: create_user
    create_comment annotated: pm, annotator: create_user
    create_tag annotated: pm, annotator: create_user
    create_task annotated: pm, annotator: create_user
    assert_equal 5, pm.contributing_users_count
  end

  test "should get time to first and last status" do
    create_translation_status_stuff
    create_verification_status_stuff(false)
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'owner'
    p = create_project team: t

    with_current_user_and_team(u, t) do
      time = Time.now - 10.minutes
      Time.stubs(:now).returns(time)

      pm = create_project_media project: p, user: u
      assert_equal '', pm.time_to_status(:first)
      assert_equal '', pm.time_to_status(:last)

      Time.stubs(:now).returns(time + 5.minutes)
      s = pm.last_status_obj
      s.status = 'In Progress'; s.save!
      assert_equal '', pm.time_to_status(:first)
      assert_equal 5.minutes.to_i, pm.time_to_status(:last)

      Time.stubs(:now).returns(time + 8.minutes)
      s = pm.last_status_obj
      s.status = ::Workflow::Workflow.core_options(pm, pm.default_media_status_type)[:default]
      s.save!

      assert_equal 5.minutes.to_i, pm.time_to_status(:first)
      assert_equal 8.minutes.to_i, pm.time_to_status(:last)
      Time.unstub(:now)
    end
  end

  test "should reject a status of verified if all required tasks are not resolved" do
    create_verification_status_stuff
    create_annotation_type annotation_type: 'response'
    pm = create_project_media
    t1 = create_task annotated: pm
    t2 = create_task annotated: pm, required: true
    t1.response = { annotation_type: 'response', set_fields: {} }.to_json
    t1.save!
    s = pm.annotations.where(annotation_type: 'verification_status').last.load
    assert_raise ActiveRecord::RecordInvalid do
      s.status = 'verified'; s.save!
    end
    assert_raise ActiveRecord::RecordInvalid do
      s.status = 'false'; s.save!
    end
    t2.response = { annotation_type: 'response', set_fields: {} }.to_json
    t2.save!
    s.status = 'verified'; s.save!
    assert_equal s.reload.status, 'verified'
  end

  test "should back status to active if required task added to resolved item" do
    create_translation_status_stuff
    create_verification_status_stuff(false)
    p = create_project
    pm = create_project_media project: p
    s = pm.annotations.where(annotation_type: 'verification_status').last.load
    s.status = 'verified'; s.save!
    
    pm = ProjectMedia.find(pm.id)
    assert_equal 'verified', pm.last_verification_status
    
    pm = ProjectMedia.find(pm.id)
    create_task annotated: pm
    assert_equal 'verified', pm.last_verification_status
   
    pm = ProjectMedia.find(pm.id)
    create_task annotated: pm, required: true
    assert_equal 'in_progress', pm.last_verification_status
  end

  test "should move pending item to in progress status" do
    create_translation_status_stuff
    create_verification_status_stuff(false)
    stub_config('app_name', 'Check') do
      create_annotation_type annotation_type: 'response'
      p = create_project
      pm = create_project_media project: p
      default = 'undetermined'
      active = 'in_progress'
      s = pm.annotations.where(annotation_type: 'verification_status').last.load
      t = create_task annotated: pm
      assert_not_equal pm.last_status, active
      # add comment
      create_comment annotated: pm, disable_update_status: false
      assert_equal pm.last_verification_status, active
      s.status = default; s.save!
      # add tag
      create_tag annotated: pm, disable_update_status: false
      assert_equal pm.last_verification_status, active
      s.status = default; s.save!
      # add response
      t.response = { annotation_type: 'response', set_fields: {} }.to_json
      t.save!
      assert_equal pm.last_verification_status, active
      # change status to verified and tests autmatic update
      s.status = 'verified'; s.save!
      create_comment annotated: pm, disable_update_status: false
      assert_equal pm.last_verification_status, 'verified'
    end
  end

  test "should update media account when change author_url" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
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


    m = create_media url: url, account: nil, account_id: nil
    a = m.account
    p = create_project team: t
    pm = create_project_media media: m, project: p
    sleep 1
    pm = ProjectMedia.find(pm.id)
    with_current_user_and_team(u, t) do
      pm.refresh_media = true
    end
    assert_not_equal a, m.reload.account
    assert_nil Account.where(id: a.id).last
  end

  test "should create media when normalized URL exists" do
    ft = create_field_type field_type: 'image_path', label: 'Image Path'
    at = create_annotation_type annotation_type: 'reverse_image', label: 'Reverse Image'
    create_field_instance annotation_type_object: at, name: 'reverse_image_path', label: 'Reverse Image', field_type_object: ft, optional: false
    create_bot name: 'Check Bot'

    url = 'https://www.facebook.com/Ma3komMona/videos/695409680623722'
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l = create_link url: url
    pm = create_project_media media: l

    url = 'https://www.facebook.com/Ma3komMona/videos/vb.268809099950451/695409680623722/?type=3&theater'
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    response = '{"type":"media","data":{"url":"https://www.facebook.com/Ma3komMona/videos/695409680623722","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    assert_difference 'ProjectMedia.count' do
      pm = ProjectMedia.new
      pm.url = url
      pm.project = create_project
      pm.save!
    end
  end

  test "should get previous project search object" do
    p1 = create_project
    p2 = create_project
    pm = create_project_media project: p1
    pm.previous_project_id = p1.id
    pm.project_id = p2.id
    pm.save!
    assert_kind_of CheckSearch, pm.check_search_project_was
  end

  test "should move media to active status" do
    create_verification_status_stuff
    stub_config('app_name', 'Check') do
      pm = create_project_media
      assert_equal 'undetermined', pm.last_verification_status
      create_task annotated: pm, disable_update_status: false
      assert_equal 'in_progress', pm.reload.last_verification_status
    end
  end

  test "should not complete media if there are pending tasks" do
    create_verification_status_stuff
    pm = create_project_media
    s = pm.last_verification_status_obj
    create_task annotated: pm, required: true
    assert_equal 'undetermined', s.reload.get_field('verification_status_status').status
    assert_raises ActiveRecord::RecordInvalid do
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
    stub_config('app_name', 'Check') do
      pm = create_project_media
      assert_equal 'undetermined', pm.last_verification_status
      s = pm.last_verification_status_obj
      s.locked = true
      s.save!
      create_task annotated: pm, disable_update_status: false
      assert_equal 'undetermined', pm.reload.last_verification_status
    end
  end

  test "should not return to active status if required task added to resolved item but status is locked" do
    create_translation_status_stuff
    create_verification_status_stuff(false)
    p = create_project
    pm = create_project_media project: p
    s = pm.annotations.where(annotation_type: 'verification_status').last.load
    s.status = 'verified'
    s.locked = true
    s.save!
    
    pm = ProjectMedia.find(pm.id)
    assert_equal 'verified', pm.last_verification_status
    
    pm = ProjectMedia.find(pm.id)
    create_task annotated: pm
    assert_equal 'verified', pm.last_verification_status
   
    pm = ProjectMedia.find(pm.id)
    create_task annotated: pm, required: true
    assert_equal 'verified', pm.last_verification_status
  end

  test "should expose target languages" do
    pm = create_project_media
    assert_nothing_raised do
      JSON.parse(pm.target_languages)
    end
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
      assert_nil pm.last_translation_status_obj
    end
  end

  test "should have relationships and parent and children reports" do
    s1 = create_project_media
    s2 = create_project_media
    t1 = create_project_media
    t2 = create_project_media
    create_project_media
    create_relationship source_id: s1.id, target_id: t1.id
    create_relationship source_id: s2.id, target_id: t2.id
    assert_equal [t1], s1.targets
    assert_equal [t2], s2.targets
    assert_equal [s1], t1.sources
    assert_equal [s2], t2.sources
  end
end
