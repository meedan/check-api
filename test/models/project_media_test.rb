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
    pender_url = CONFIG['pender_host'] + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    assert_difference 'ProjectMedia.count', 2 do
      create_project_media media: nil, quote: 'Claim report'
      create_project_media media: nil, url: url
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
    pm = create_project_media project: p, media: m
    with_current_user_and_team(u, t) do
      pm.project_id = p2.id; pm.save!
      pm.reload
      assert_equal pm.project_id, p2.id
    end
    u2 = create_user
    tu = create_team_user team: t, user: u2, role: 'journalist'
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
    assert_raise CheckPermissions::AccessDenied do
      with_current_user_and_team(u, pt) do
        ProjectMedia.find_if_can(ppm.id)
      end
    end
    with_current_user_and_team(pu, pt) do
      ProjectMedia.find_if_can(ppm.id)
    end
    tu = pt.team_users.last
    tu.update_column(:status, 'requested')
    assert_raise CheckPermissions::AccessDenied do
      with_current_user_and_team(pu, pt) do
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

  test "should notify Pusher in background" do
    Rails.stubs(:env).returns(:production)
    t = create_team
    p = create_project team:  t
    CheckNotifications::Pusher::Worker.drain
    assert_equal 0, CheckNotifications::Pusher::Worker.jobs.size
    create_project_media project: p
    assert_equal 2, CheckNotifications::Pusher::Worker.jobs.size
    CheckNotifications::Pusher::Worker.drain
    assert_equal 0, CheckNotifications::Pusher::Worker.jobs.size
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
    perm_keys = ["read ProjectMedia", "update ProjectMedia", "destroy ProjectMedia", "create Comment", "create Flag", "create Status", "create Tag", "create Task", "create Dynamic"].sort
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
      assert_raises ActiveRecord::RecordInvalid do
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
    pender_url = CONFIG['pender_host'] + '/api/medias'
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

  test "should update es after move media to other projects" do
    t = create_team
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m, disable_es_callbacks: false
    create_comment annotated: pm
    create_tag annotated: pm
    sleep 1
    ms = MediaSearch.find(pm.id)
    assert_equal ms.project_id.to_i, p.id
    assert_equal ms.team_id.to_i, t.id
    t2 = create_team
    p2 = create_project team: t2
    Sidekiq::Testing.fake! do
      pm.project = p2; pm.save!
      ElasticSearchWorker.drain
    end
    # confirm annotations log
    sleep 1
    ms = MediaSearch.find(pm.id)
    assert_equal ms.project_id.to_i, p2.id
    assert_equal ms.team_id.to_i, t2.id
  end

  test "should have versions" do
    m = create_valid_media
    t = create_team
    p = create_project team: t
    u = create_user
    create_team_user user: u, team: t, role: 'owner'
    pm = nil
    User.current = u
    assert_difference 'PaperTrail::Version.count', 2 do
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
      create_comment annotated: pm
      create_tag annotated: pm
      create_flag annotated: pm
      s = pm.annotations.where(annotation_type: 'status').last.load
      s.status = 'In Progress'; s.save!
      e = create_embed annotated: pm, title: 'Test'
      info = { title: 'Foo' }.to_json; pm.embed = info; pm.save!
      info = { title: 'Bar' }.to_json; pm.embed = info; pm.save!
      pm.project_id = p2.id; pm.save!
      t = create_task annotated: pm
      t = Task.find(t.id); t.response = { annotation_type: 'response', set_fields: { response: 'Test', task: t.id.to_s, note: 'Test' }.to_json }.to_json; t.save!
      t = Task.find(t.id); t.label = 'Test?'; t.save!
      r = DynamicAnnotation::Field.where(field_name: 'response').last; r.value = 'Test 2'; r.save!
      r = DynamicAnnotation::Field.where(field_name: 'note').last; r.value = 'Test 2'; r.save!

      assert_equal ["create_comment", "create_tag", "create_flag", "update_status", "create_embed", "update_embed", "update_embed", "update_projectmedia", "create_task", "create_dynamicannotationfield", "create_dynamicannotationfield", "create_dynamicannotationfield", "update_task", "update_task", "update_dynamicannotationfield", "update_dynamicannotationfield"].sort, pm.get_versions_log.map(&:event_type).sort
      assert_equal 13, pm.get_versions_log_count
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
    pender_url = CONFIG['pender_host'] + '/api/medias'
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
    sleep 1
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
end
