require_relative '../test_helper'

class TeamBotTest < ActiveSupport::TestCase
  def setup
    super
    BotUser.delete_all
    Sidekiq::Testing.inline!
    create_annotation_type_and_fields('Team Bot Response', { 'Raw Data' => ['JSON', true], 'Formatted Data' => ['Bot Response Format', false] })
  end

  test "should create team bot" do
    assert_difference 'BotUser.count' do
      create_team_bot
    end
  end

  test "should not create team bot without a name" do
    assert_no_difference 'BotUser.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_team_bot name: ''
      end
    end
  end

  test "should get avatar" do
    tb = create_team_bot
    assert_match /^http/, tb.avatar
  end

  test "should belong to team" do
    t = create_team
    tb = create_team_bot team_author_id: t.id
    assert_equal t, tb.team_author
    assert_equal [tb], t.team_bots_created
  end

  test "should delete team bot when team is deleted" do
    t = create_team
    tb = create_team_bot team_author_id: t.id
    assert_not_nil BotUser.where(id: tb.id).last
    t.destroy!
    assert_nil BotUser.where(id: tb.id).last
  end

  test "should not create team bot with invalid request URL" do
    assert_no_difference 'BotUser.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_team_bot set_request_url: 'invalid'
      end
      assert_raises ActiveRecord::RecordInvalid do
        create_team_bot set_request_url: 'http://foo bar'
      end
    end
  end

  test "should not create team bot with invalid event" do
    assert_no_difference 'BotUser.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_team_bot set_events: [{ event: 'invalid', graphql: nil }]
      end
    end
  end

  test "should create team bot under team where user is admin" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'admin'

    with_current_user_and_team(u, t) do
      assert_nothing_raised do
        create_team_bot
      end
    end
  end

  ['editor', 'collaborator'].each do |role|
    test "should not create team bot under team where user is #{role}" do
      u = create_user
      t = create_team
      t2 = create_team
      create_team_user user: u, team: t, role: role
      with_current_user_and_team(u, t) do
        assert_raises RuntimeError do
          create_team_bot team_author_id: t.id
        end
      end
    end
  end

  test "should not create team bot under team where user is not owner" do
    u = create_user
    t = create_team
    t2 = create_team
    create_team_user user: u, team: t, role: 'admin'

    with_current_user_and_team(u, t2) do
      assert_raises RuntimeError do
        create_team_bot team_author_id: t.id
      end
    end
  end

  test "should notify team bots in background when project media is created or updated" do
    t1 = create_team
    p1 = create_project team: t1
    tb1a = create_team_bot team_author_id: t1.id, set_events: [{ event: 'create_project_media', graphql: nil }]
    tb1b = create_team_bot team_author_id: t1.id, set_events: [{ event: 'update_project_media', graphql: nil }]

    t2 = create_team
    p2 = create_project team: t2
    tb2a = create_team_bot team_author_id: t2.id, set_events: [{ event: 'create_project_media', graphql: nil }]
    tb2b = create_team_bot team_author_id: t2.id, set_events: [{ event: 'update_project_media', graphql: nil }]

    #assert_nil tb1a.reload.last_called_at
    #assert_nil tb1b.reload.last_called_at
    #assert_nil tb2a.reload.last_called_at
    #assert_nil tb2b.reload.last_called_at

    pm1 = create_project_media project: p1

    #tb1at = tb1a.reload.last_called_at
    #assert_not_nil tb1at
    #assert_nil tb1b.reload.last_called_at
    #assert_nil tb2a.reload.last_called_at
    #assert_nil tb2b.reload.last_called_at

    pm2 = create_project_media project: p2

    #tb2at = tb2a.reload.last_called_at
    #assert_equal tb1at, tb1a.reload.last_called_at
    #assert_nil tb1b.reload.last_called_at
    #assert_not_nil tb2at
    #assert_nil tb2b.reload.last_called_at

    pm1.updated_at = Time.now
    pm1.save!

    #tb1bt = tb1b.reload.last_called_at
    #assert_equal tb1at, tb1a.reload.last_called_at
    #assert_not_nil tb1bt
    #assert_equal tb2at, tb2a.reload.last_called_at
    #assert_nil tb2b.reload.last_called_at

    pm2.updated_at = Time.now
    pm2.save!

    #tb2bt = tb2b.reload.last_called_at
    #assert_equal tb1at, tb1a.reload.last_called_at
    #assert_equal tb1bt, tb1b.reload.last_called_at
    #assert_equal tb2at, tb2a.reload.last_called_at
    #assert_not_nil tb2bt
  end

  test "should not notify team bot if object is marked to skip notifications" do
    t = create_team
    p = create_project team: t
    tb = create_team_bot team_author_id: t.id, set_events: [{ event: 'create_project_media', graphql: nil }]
    #assert_nil tb.reload.last_called_at
    pm = create_project_media project: p, skip_notifications: true
    #assert_nil tb.reload.last_called_at
  end

  test "should notify team bots in background when source is created or updated" do
    t1 = create_team
    tb1a = create_team_bot team_author_id: t1.id, set_events: [{ event: 'create_source', graphql: nil }]
    tb1b = create_team_bot team_author_id: t1.id, set_events: [{ event: 'update_source', graphql: nil }]

    t2 = create_team
    tb2a = create_team_bot team_author_id: t2.id, set_events: [{ event: 'create_source', graphql: nil }]
    tb2b = create_team_bot team_author_id: t2.id, set_events: [{ event: 'update_source', graphql: nil }]

    #assert_nil tb1a.reload.last_called_at
    #assert_nil tb1b.reload.last_called_at
    #assert_nil tb2a.reload.last_called_at
    #assert_nil tb2b.reload.last_called_at

    s1 = create_source team: t1

    #tb1at = tb1a.reload.last_called_at
    #assert_not_nil tb1at
    #assert_nil tb1b.reload.last_called_at
    #assert_nil tb2a.reload.last_called_at
    #assert_nil tb2b.reload.last_called_at

    s2 = create_source team: t2

    #tb2at = tb2a.reload.last_called_at
    #assert_equal tb1at, tb1a.reload.last_called_at
    #assert_nil tb1b.reload.last_called_at
    #assert_not_nil tb2at
    #assert_nil tb2b.reload.last_called_at

    s1.updated_at = Time.now
    s1.save!

    #tb1bt = tb1b.reload.last_called_at
    #assert_equal tb1at, tb1a.reload.last_called_at
    #assert_not_nil tb1bt
    #assert_equal tb2at, tb2a.reload.last_called_at
    #assert_nil tb2b.reload.last_called_at

    s2.updated_at = Time.now
    s2.save!

    #tb2bt = tb2b.reload.last_called_at
    #assert_equal tb1at, tb1a.reload.last_called_at
    #assert_equal tb1bt, tb1b.reload.last_called_at
    #assert_equal tb2at, tb2a.reload.last_called_at
    #assert_not_nil tb2bt
  end

  test "should notify team bots in background when annotation is created or updated" do
    t1 = create_team
    p1 = create_project team: t1
    pm1 = create_project_media project: p1
    tb1a = create_team_bot team_author_id: t1.id, set_events: [{ event: 'create_annotation_comment', graphql: nil }]
    tb1b = create_team_bot team_author_id: t1.id, set_events: [{ event: 'update_annotation_comment', graphql: nil }]

    t2 = create_team
    p2 = create_project team: t2
    pm2 = create_project_media project: p2
    tb2a = create_team_bot team_author_id: t2.id, set_events: [{ event: 'create_annotation_comment', graphql: nil }]
    tb2b = create_team_bot team_author_id: t2.id, set_events: [{ event: 'update_annotation_comment', graphql: nil }]

    #assert_nil tb1a.reload.last_called_at
    #assert_nil tb1b.reload.last_called_at
    #assert_nil tb2a.reload.last_called_at
    #assert_nil tb2b.reload.last_called_at

    tg1 = create_tag annotated: pm1

    #tb1at = tb1a.reload.last_called_at
    #assert_not_nil tb1at
    #assert_nil tb1b.reload.last_called_at
    #assert_nil tb2a.reload.last_called_at
    #assert_nil tb2b.reload.last_called_at

    tg2 = create_tag annotated: pm2

    #tb2at = tb2a.reload.last_called_at
    #assert_equal tb1at, tb1a.reload.last_called_at
    #assert_nil tb1b.reload.last_called_at
    #assert_not_nil tb2at
    #assert_nil tb2b.reload.last_called_at

    tg1.updated_at = Time.now
    tg1.save!

    #tb1bt = tb1b.reload.last_called_at
    #assert_equal tb1at, tb1a.reload.last_called_at
    #assert_not_nil tb1bt
    #assert_equal tb2at, tb2a.reload.last_called_at
    #assert_nil tb2b.reload.last_called_at

    tg2.updated_at = Time.now
    tg2.save!

    #tb2bt = tb2b.reload.last_called_at
    #assert_equal tb1at, tb1a.reload.last_called_at
    #assert_equal tb1bt, tb1b.reload.last_called_at
    #assert_equal tb2at, tb2a.reload.last_called_at
    #assert_not_nil tb2bt
  end

  test "should get GraphQL result" do
    t = create_team private: true
    p = create_project team: t
    tb = create_team_bot team_author_id: t.id
    pm = create_project_media project: p
    tg = create_tag text: 'Test tag'
    s = create_source name: 'Test Source'
    assert_equal pm.id, tb.graphql_result('id, dbid', pm, t)['dbid']
    assert_equal 'Test Source', tb.graphql_result('id, dbid, name', s, t)['name']
    require 'byebug'
    byebug
    assert_equal({ tag: 'Test tag' }.to_json, tb.graphql_result('id, dbid, content', tg, t)['content'])
    assert tb.graphql_result('invalid fragment', tg, t).has_key?('error')
  end

  test "should call bot over event subscription" do
    RequestStore.store[:disable_es_callbacks] = true
    t = create_team name: 'Test Team'
    p1 = create_project team: t, title: 'Test Project'
    p2 = create_project team: t, title: 'Another Test Project'
    tb = create_team_bot team_author_id: t.id, set_events: [{ event: 'create_project_media', graphql: 'team { name }' }], set_request_url: 'http://bot'
    data = { event: 'create_project_media', data: { team: { name: 'Test Team' } } }
    WebMock.disable_net_connect! allow: /#{CheckConfig.get('storage_endpoint')}/
    WebMock.stub_request(:post, 'http://bot').with(body: hash_including(data)).to_return(body: 'ok')

    with_current_user_and_team(nil, nil) do
      assert_nothing_raised do
        create_project_media project: p1
      end

      t.name = random_string
      t.save!

      assert_raises WebMock::NetConnectNotAllowedError do
        create_project_media project: p2
      end
    end
    RequestStore.store[:disable_es_callbacks] = false
    WebMock.allow_net_connect!
  end

  test "should call bot over own annotation updates" do
    t = create_team
    p = create_project team: t
    tb1 = create_team_bot team_author_id: t.id, set_events: [{ event: 'update_annotation_own', graphql: nil }]
    tb2 = create_team_bot team_author_id: t.id, set_events: [{ event: 'update_annotation_own', graphql: nil }]
    pm = create_project_media project: p
    a1 = create_dynamic_annotation annotated: pm, annotation_type: 'team_bot_response', set_fields: { team_bot_response_formatted_data: { title: 'Foo', description: 'Bar' }.to_json }.to_json
    a2 = create_dynamic_annotation annotated: pm, annotation_type: 'team_bot_response', set_fields: { team_bot_response_formatted_data: { title: 'Foo', description: 'Bar' }.to_json }.to_json, annotator: tb1

    a1.updated_at = Time.now
    a1.save!
    #assert_nil tb1.reload.last_called_at
    #assert_nil tb2.reload.last_called_at

    a2.updated_at = Time.now
    a2.save!
    #assert_not_nil tb1.reload.last_called_at
    #assert_nil tb2.reload.last_called_at
  end

  test "should enqueue bot notifications" do
    RequestStore.store[:disable_es_callbacks] = true
    t = create_team
    p = create_project team: t, title: 'Test Project'
    tb = create_team_bot team_author_id: t.id, set_events: [{ event: 'create_project_media', graphql: 'team { slug }' }, { event: 'update_project_media', graphql: 'team { slug }' }], set_request_url: 'http://bot'
    data_create = { event: 'create_project_media', data: { team: { slug: t.slug } } }
    data_update = { event: 'update_project_media', data: { team: { slug: t.slug } } }
    create_stub = WebMock.stub_request(:post, 'http://bot').with(body: hash_including(data_create)).to_return(body: 'ok')
    update_stub = WebMock.stub_request(:post, 'http://bot').with(body: hash_including(data_update)).to_return(body: 'ok')
    WebMock.disable_net_connect! allow: /#{CheckConfig.get('storage_endpoint')}/

    with_current_user_and_team(nil, nil) do
      BotUser.init_event_queue

      assert_nothing_raised do
        pm = create_project_media project: p
        pm.user_id = create_user
        pm.save!
        pm.user_id = create_user
        pm.save!
      end

      assert_nothing_raised do
        BotUser.trigger_events
      end

      assert_equal 1, WebMock::RequestRegistry.instance.times_executed(update_stub.request_pattern)
    end
    RequestStore.store[:disable_es_callbacks] = false
    WebMock.allow_net_connect!
  end

  test "should get API key" do
    tb = create_team_bot
    assert_kind_of ApiKey, tb.api_key
  end

  test "should destroy related data when bot is destroyed" do
    tb = create_team_bot team_author_id: create_team.id
    assert_difference 'Source.count', -1 do
      assert_difference 'TeamUser.count', -1 do
        assert_difference 'ApiKey.count', -1 do
          assert_difference 'BotUser.count', -1 do
            tb.destroy!
          end
        end
      end
    end
  end

  test "should not be approved by default" do
    tb = create_team_bot
    assert !tb.get_approved
  end

  test "should not associate twice" do
    t = create_team
    assert_difference 'TeamBotInstallation.count' do
      tb = create_team_bot team_author_id: t.id
      tb = BotUser.find(tb.id)
      tb.team_author_id = t.id
      tb.updated_at = Time.now
      tb.save!
    end
  end

  test "should be related to teams and installations" do
    t1 = create_team
    t2 = create_team
    tb = create_team_bot team_author_id: t1.id, set_approved: true
    tbi = create_team_bot_installation team_id: t2.id, user_id: tb.id
    assert_equal 2, tb.team_bot_installations.count
    assert_equal [t1, t2].sort, tb.reload.teams.sort
    assert_difference 'TeamBotInstallation.count', -2 do
      tb.destroy
    end
  end

  test "should install" do
    t = create_team
    tb = create_team_bot set_approved: true
    assert_equal [], t.reload.team_bots
    tb.install_to!(t)
    assert_equal [tb], t.reload.team_bots
  end

  test "should uninstall" do
    t = create_team
    tb = create_team_bot set_approved: true
    assert_equal [], t.reload.team_bots
    tb.install_to!(t)
    assert_equal [tb], t.reload.team_bots
    tb.uninstall_from!(t)
    assert_equal [], t.reload.team_bots
    tb.uninstall_from!(t)
  end

  test "should approve bot if admin" do
    u = create_user is_admin: true
    tb = create_team_bot
    assert !tb.get_approved
    User.current = u
    assert_nothing_raised do
      tb.approve!
    end
    User.current = nil
    assert tb.reload.get_approved
  end

  test "should not approve bot if not admin" do
    u = create_user is_admin: false
    t = create_team
    create_team_user user: u, team: t, role: 'admin'
    tb = create_team_bot team_author_id: t.id
    assert !tb.get_approved
    User.current = u
    assert_raises ActiveRecord::RecordInvalid do
      tb.approve!
    end
    User.current = nil
    assert !tb.reload.get_approved
  end

  test "should return non-approved bots" do
    tb1 = create_team_bot set_approved: false
    tb2 = create_team_bot set_approved: true
    assert_equal [tb1], BotUser.not_approved.to_a
  end

  test "should set version" do
    tb = create_team_bot
    assert_equal '0.0.1', tb.get_version
    tb.set_version '0.0.2'
    tb.save!
    assert_equal '0.0.2', tb.reload.get_version
  end

  test "should set source code URL" do
    tb = create_team_bot
    assert_nil tb.get_source_code_url
    tb.set_source_code_url'https://github.com/meedan/check-api-bots'
    tb.save!
    assert_equal 'https://github.com/meedan/check-api-bots', tb.reload.get_source_code_url
  end

  test "should not be limited by default" do
    tb = create_team_bot
    assert !tb.get_limited
    tb.set_limited true
    tb.save!
    assert tb.reload.get_limited
  end

  test "should set identifier" do
    t = create_team slug: 'test'
    tb = create_team_bot name: 'My Bot', team_author_id: t.id
    assert_equal 'bot_my_bot', tb.reload.identifier
    tb = create_team_bot name: 'My Bot!', team_author_id: t.id
    assert_equal 'bot_my_bot_1', tb.reload.identifier
  end

  test "should define bot role" do
    tb = create_team_bot set_role: 'editor', set_approved: true
    tu1 = TeamUser.where(team_id: tb.team_author_id, user_id: tb.id).last
    assert_equal 'editor', tu1.role
    tbi = create_team_bot_installation user_id: tb.id
    tu2 = TeamUser.where(team_id: tbi.team_id, user_id: tb.id).last
    assert_equal 'editor', tu2.role
    tb.set_role 'collaborator'
    tb.save!
    assert_equal 'collaborator', tu1.reload.role
    assert_equal 'collaborator', tu2.reload.role
  end

  test "should return whether bot is installed under current team" do
    tb1 = create_team_bot set_approved: true
    tb2 = create_team_bot set_approved: true
    t = create_team
    create_team_bot_installation team_id: t.id, user_id: tb1.id
    User.current = create_user
    Team.current = t
    assert_equal true, tb1.reload.installed
    assert_equal false, tb2.reload.installed
    Team.current = nil
    User.current = nil
  end

  test "should get number of installations" do
    tb = create_team_bot set_approved: true
    assert_equal 1, tb.reload.installations_count
    4.times { create_team_bot_installation(user_id: tb.id) }
    assert_equal 5, tb.reload.installations_count
  end

  test "should have specific events for task types" do
    Task.task_types.each do |type|
      assert BotUser::EVENTS.include?("create_annotation_task_#{type}")
      assert BotUser::EVENTS.include?("update_annotation_task_#{type}")
    end
  end

  test "should notify team bots in background when task is created" do
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p
    tb1 = create_team_bot team_author_id: t.id, set_events: [{ event: 'create_annotation_task_free_text', graphql: nil }]
    tb2 = create_team_bot team_author_id: t.id, set_events: [{ event: 'create_annotation_task_datetime', graphql: nil }]

    #assert_nil tb1.reload.last_called_at
    #assert_nil tb2.reload.last_called_at

    create_task type: 'free_text', annotated: pm
    #x = tb1.reload.last_called_at
    #assert_not_nil x
    #assert_nil tb2.reload.last_called_at

    create_task type: 'datetime', annotated: pm
    #assert_equal x, tb1.reload.last_called_at
    #assert_not_nil tb2.reload.last_called_at
  end

  test "should have a unique identifier" do
    create_team_bot login: 'test'
    assert_raises ActiveRecord::RecordInvalid do
      create_team_bot login: 'test'
    end
  end

  test "should have permissions" do
    t1 = create_team
    t2 = create_team
    u = create_user
    create_team_user team: t1, user: u, role: 'admin'
    create_team_user team: t2, user: u, role: 'editor'
    tb = nil
    assert_nothing_raised do
      with_current_user_and_team(u, t2) do
        tb = BotUser.new({
          name: random_string,
          team_author_id: t1.id
        })
        tb.set_description = random_string
        tb.set_request_url = random_url
        tb.set_events = [{ event: 'create_project_media', graphql: nil }]
        File.open(File.join(Rails.root, 'test', 'data', 'rails.png')) do |f|
          tb.image = f
        end
        tb.save!
        tb = BotUser.find(tb.id)
        tb.updated_at = Time.now
        tb.save!
        tb = BotUser.find(tb.id)
        tb.destroy!
      end
    end
  end

  test "should have settings" do
    tb = create_team_bot set_settings: [{ name: 'foo', label: 'Foo', type: 'string', default: 'Bar' }]
    assert_equal 5, tb.get_settings[0].keys.size
    assert_nothing_raised do
      JSON.parse(tb.settings_as_json_schema)
    end
  end

  test "should not make a real HTTP request to a core bot" do
    b = create_team_bot name: 'Keep', set_request_url: CheckConfig.get('checkdesk_base_url_private') + '/foo/bar'
    b.call({})
  end

  test "should return UI schema for team bot settings" do
    settings = [{ name: 'smooch_message_foo', label: 'Foo', type: 'string', default: '' }]
    tb = create_team_bot set_settings: settings
    assert_match /textarea/, tb.settings_ui_schema
  end

  test "should notify team bots when report is published" do
    Dynamic.any_instance.stubs(:report_image_generate_png)
    team = create_team name: 'Test Team'
    team_bot = create_team_bot team_author_id: team.id, set_events: [{ event: 'publish_report', graphql: nil }], set_request_url: 'http://bot'
    pm_1 = create_project_media team: team
    pm_2 = create_project_media team: team
    WebMock.disable_net_connect! allow: /http:\/\/bot|#{CheckConfig.get('elasticsearch_host')}|#{CheckConfig.get('storage_endpoint')}/
    data = { event: 'publish_report' }
    publish_stub = WebMock.stub_request(:post, 'http://bot').with(body: hash_including(data)).to_return(body: 'ok')

    with_current_user_and_team(nil, nil) do
      BotUser.init_event_queue
      publish_report(pm_1)
      publish_report(pm_2)
      BotUser.trigger_events
    end

    assert_equal 2, WebMock::RequestRegistry.instance.times_executed(publish_stub.request_pattern)
    WebMock.allow_net_connect!
    Dynamic.any_instance.unstub(:report_image_generate_png)
  end
end
