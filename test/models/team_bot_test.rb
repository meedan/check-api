require_relative '../test_helper'

class TeamBotTest < ActiveSupport::TestCase
  def setup
    super
    TeamBot.delete_all
    Sidekiq::Testing.inline!
    create_annotation_type_and_fields('Team Bot Response', { 'Raw Data' => ['JSON', true], 'Formatted Data' => ['Bot Response Format', false] })
  end

  test "should create team bot" do
    assert_difference 'TeamBot.count' do
      create_team_bot
    end
  end

  test "should not create team bot without a name" do
    assert_no_difference 'TeamBot.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_team_bot name: ''
      end
    end
  end

  test "should not create team bot without a team" do
    assert_no_difference 'TeamBot.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_team_bot team_author_id: nil
      end
    end
    tb = create_team_bot
    assert_nothing_raised do
      tb.updated_at = Time.now
      tb.save!
    end
  end

  test "should not create team bot with same name and team" do
    t1 = create_team
    t2 = create_team
    assert_difference 'Source.count' do
      create_team_bot name: 'Bot Test', team_author_id: t1.id, bot_user_id: nil
    end
    assert_difference 'Source.count' do
      create_team_bot name: 'Bot Test', team_author_id: t2.id, bot_user_id: nil
    end
    assert_raises ActiveRecord::RecordInvalid do
      create_team_bot name: 'Bot Test', team_author_id: t1.id
    end
    assert_raises ActiveRecord::RecordInvalid do
      create_team_bot name: 'Bot Test', team_author_id: t2.id
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
    assert_not_nil TeamBot.where(id: tb.id).last
    t.destroy
    assert_nil TeamBot.where(id: tb.id).last
  end

  test "should belong to a bot user" do
    bu = create_bot_user
    tb = create_team_bot bot_user_id: bu.id
    assert_equal bu, tb.bot_user
    assert_equal tb, bu.team_bot
  end

  test "should not create team bot with invalid request URL" do
    assert_no_difference 'TeamBot.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_team_bot request_url: 'invalid'
      end
      assert_raises ActiveRecord::RecordInvalid do
        create_team_bot request_url: 'http://foo bar'
      end
    end
  end

  test "should not create team bot with invalid event" do
    assert_no_difference 'TeamBot.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_team_bot events: [{ event: 'invalid', graphql: nil }]
      end
    end
  end

  test "should create bot user when team bot is created" do
    assert_difference 'ApiKey.count' do
      assert_difference 'BotUser.count' do
        assert_difference 'TeamBot.count' do
          assert_difference 'TeamUser.count' do
            create_team_bot bot_user_id: nil
          end
        end
      end
    end
  end

  test "should create team bot under team where user is owner" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'owner'
    
    with_current_user_and_team(u, t) do
      assert_nothing_raised do
        create_team_bot team_author_id: t.id, bot_user_id: nil
      end
    end
  end

  test "should not create team bot under team where user is contributor" do
    u = create_user
    t = create_team
    t2 = create_team
    create_team_user user: u, team: t, role: 'contributor'
    
    with_current_user_and_team(u, t) do
      assert_raises RuntimeError do
        create_team_bot team_author_id: t.id, bot_user_id: nil
      end
    end
  end

  test "should not create team bot under team where user is editor" do
    u = create_user
    t = create_team
    t2 = create_team
    create_team_user user: u, team: t, role: 'editor'
    
    with_current_user_and_team(u, t) do
      assert_raises RuntimeError do
        create_team_bot team_author_id: t.id, bot_user_id: nil
      end
    end
  end

  test "should not create team bot under team where user is journalist" do
    u = create_user
    t = create_team
    t2 = create_team
    create_team_user user: u, team: t, role: 'journalist'
    
    with_current_user_and_team(u, t) do
      assert_raises RuntimeError do
        create_team_bot team_author_id: t.id, bot_user_id: nil
      end
    end
  end

  test "should not create team bot under team where user is not owner" do
    u = create_user
    t = create_team
    t2 = create_team
    create_team_user user: u, team: t, role: 'owner'
    
    with_current_user_and_team(u, t2) do
      assert_raises RuntimeError do
        create_team_bot team_author_id: t2.id, bot_user_id: nil
      end
    end
  end

  test "should notify team bots in background when project media is created or updated" do
    t1 = create_team
    p1 = create_project team: t1
    tb1a = create_team_bot team_author_id: t1.id, events: [{ event: 'create_project_media', graphql: nil }]
    tb1b = create_team_bot team_author_id: t1.id, events: [{ event: 'update_project_media', graphql: nil }]
    
    t2 = create_team
    p2 = create_project team: t2
    tb2a = create_team_bot team_author_id: t2.id, events: [{ event: 'create_project_media', graphql: nil }]
    tb2b = create_team_bot team_author_id: t2.id, events: [{ event: 'update_project_media', graphql: nil }]
    
    assert_nil tb1a.reload.last_called_at
    assert_nil tb1b.reload.last_called_at
    assert_nil tb2a.reload.last_called_at
    assert_nil tb2b.reload.last_called_at
    
    pm1 = create_project_media project: p1
    
    tb1at = tb1a.reload.last_called_at
    assert_not_nil tb1at
    assert_nil tb1b.reload.last_called_at
    assert_nil tb2a.reload.last_called_at
    assert_nil tb2b.reload.last_called_at

    pm2 = create_project_media project: p2
    
    tb2at = tb2a.reload.last_called_at
    assert_equal tb1at, tb1a.reload.last_called_at
    assert_nil tb1b.reload.last_called_at
    assert_not_nil tb2at
    assert_nil tb2b.reload.last_called_at

    pm1.updated_at = Time.now
    pm1.save!

    tb1bt = tb1b.reload.last_called_at
    assert_equal tb1at, tb1a.reload.last_called_at
    assert_not_nil tb1bt
    assert_equal tb2at, tb2a.reload.last_called_at
    assert_nil tb2b.reload.last_called_at

    pm2.updated_at = Time.now
    pm2.save!

    tb2bt = tb2b.reload.last_called_at
    assert_equal tb1at, tb1a.reload.last_called_at
    assert_equal tb1bt, tb1b.reload.last_called_at
    assert_equal tb2at, tb2a.reload.last_called_at
    assert_not_nil tb2bt
  end

  test "should not notify team bot if object is marked to skip notifications" do
    t = create_team
    p = create_project team: t
    tb = create_team_bot team_author_id: t.id, events: [{ event: 'create_project_media', graphql: nil }]
    assert_nil tb.reload.last_called_at
    pm = create_project_media project: p, skip_notifications: true
    assert_nil tb.reload.last_called_at
  end

  test "should notify team bots in background when source is created or updated" do
    t1 = create_team
    tb1a = create_team_bot team_author_id: t1.id, events: [{ event: 'create_source', graphql: nil }]
    tb1b = create_team_bot team_author_id: t1.id, events: [{ event: 'update_source', graphql: nil }]
    
    t2 = create_team
    tb2a = create_team_bot team_author_id: t2.id, events: [{ event: 'create_source', graphql: nil }]
    tb2b = create_team_bot team_author_id: t2.id, events: [{ event: 'update_source', graphql: nil }]
    
    assert_nil tb1a.reload.last_called_at
    assert_nil tb1b.reload.last_called_at
    assert_nil tb2a.reload.last_called_at
    assert_nil tb2b.reload.last_called_at
    
    s1 = create_source team: t1
    
    tb1at = tb1a.reload.last_called_at
    assert_not_nil tb1at
    assert_nil tb1b.reload.last_called_at
    assert_nil tb2a.reload.last_called_at
    assert_nil tb2b.reload.last_called_at

    s2 = create_source team: t2
    
    tb2at = tb2a.reload.last_called_at
    assert_equal tb1at, tb1a.reload.last_called_at
    assert_nil tb1b.reload.last_called_at
    assert_not_nil tb2at
    assert_nil tb2b.reload.last_called_at

    s1.updated_at = Time.now
    s1.save!

    tb1bt = tb1b.reload.last_called_at
    assert_equal tb1at, tb1a.reload.last_called_at
    assert_not_nil tb1bt
    assert_equal tb2at, tb2a.reload.last_called_at
    assert_nil tb2b.reload.last_called_at

    s2.updated_at = Time.now
    s2.save!

    tb2bt = tb2b.reload.last_called_at
    assert_equal tb1at, tb1a.reload.last_called_at
    assert_equal tb1bt, tb1b.reload.last_called_at
    assert_equal tb2at, tb2a.reload.last_called_at
    assert_not_nil tb2bt
  end

  test "should notify team bots in background when annotation is created or updated" do
    t1 = create_team
    p1 = create_project team: t1
    pm1 = create_project_media project: p1
    tb1a = create_team_bot team_author_id: t1.id, events: [{ event: 'create_annotation_comment', graphql: nil }]
    tb1b = create_team_bot team_author_id: t1.id, events: [{ event: 'update_annotation_comment', graphql: nil }]
    
    t2 = create_team
    p2 = create_project team: t2
    pm2 = create_project_media project: p2
    tb2a = create_team_bot team_author_id: t2.id, events: [{ event: 'create_annotation_comment', graphql: nil }]
    tb2b = create_team_bot team_author_id: t2.id, events: [{ event: 'update_annotation_comment', graphql: nil }]
    
    assert_nil tb1a.reload.last_called_at
    assert_nil tb1b.reload.last_called_at
    assert_nil tb2a.reload.last_called_at
    assert_nil tb2b.reload.last_called_at
    
    c1 = create_comment annotated: pm1
    
    tb1at = tb1a.reload.last_called_at
    assert_not_nil tb1at
    assert_nil tb1b.reload.last_called_at
    assert_nil tb2a.reload.last_called_at
    assert_nil tb2b.reload.last_called_at

    c2 = create_comment annotated: pm2
    
    tb2at = tb2a.reload.last_called_at
    assert_equal tb1at, tb1a.reload.last_called_at
    assert_nil tb1b.reload.last_called_at
    assert_not_nil tb2at
    assert_nil tb2b.reload.last_called_at

    c1.updated_at = Time.now
    c1.save!

    tb1bt = tb1b.reload.last_called_at
    assert_equal tb1at, tb1a.reload.last_called_at
    assert_not_nil tb1bt
    assert_equal tb2at, tb2a.reload.last_called_at
    assert_nil tb2b.reload.last_called_at

    c2.updated_at = Time.now
    c2.save!

    tb2bt = tb2b.reload.last_called_at
    assert_equal tb1at, tb1a.reload.last_called_at
    assert_equal tb1bt, tb1b.reload.last_called_at
    assert_equal tb2at, tb2a.reload.last_called_at
    assert_not_nil tb2bt
  end

  test "should get GraphQL result" do
    t = create_team private: true
    p = create_project team: t
    tb = create_team_bot team_author_id: t.id, bot_user_id: nil
    pm = create_project_media project: p
    c = create_comment text: 'Test Comment'
    s = create_source name: 'Test Source'
    assert_equal pm.id, tb.graphql_result('id, dbid, project { title }', pm, t)['dbid']
    assert_equal 'Test Source', tb.graphql_result('id, dbid, name', s, t)['name']
    assert_equal({ text: 'Test Comment' }.to_json, tb.graphql_result('id, dbid, content', c, t)['content'])
    assert tb.graphql_result('invalid fragment', c, t).has_key?('error')
  end

  test "should call bot" do
    t = create_team
    p1 = create_project team: t, title: 'Test Project'
    p2 = create_project team: t, title: 'Another Test Project'
    tb = create_team_bot team_author_id: t.id, events: [{ event: 'create_project_media', graphql: 'project { title }' }], request_url: 'http://bot'
    data = { event: 'create_project_media', data: { project: { title: 'Test Project' } } }
    WebMock.disable_net_connect!
    WebMock.stub_request(:post, 'http://bot').with(body: hash_including(data)).to_return(body: 'ok')

    with_current_user_and_team(nil, nil) do
      assert_nothing_raised do
        create_project_media project: p1
      end

      assert_raises WebMock::NetConnectNotAllowedError do
        create_project_media project: p2
      end
    end
    
    WebMock.allow_net_connect!
  end

  test "should notify bot about updates over annotations created by it" do
    tb = create_team_bot request_url: 'http://bot'
    a1 = create_dynamic_annotation annotation_type: 'team_bot_response', set_fields: { team_bot_response_formatted_data: { title: 'Foo', description: 'Bar' }.to_json }.to_json, annotator: tb.bot_user
    a2 = create_dynamic_annotation annotation_type: 'team_bot_response', set_fields: { team_bot_response_formatted_data: { title: 'Foo', description: 'Bar' }.to_json }.to_json, annotator: tb.bot_user

    data = { event: 'own_annotation_updated', data: { dbid: a1.id } }
    WebMock.disable_net_connect!
    WebMock.stub_request(:post, 'http://bot').with(body: hash_including(data)).to_return(body: 'ok')

    with_current_user_and_team(nil, nil) do
      assert_nothing_raised do
        a1.updated_at = Time.now
        a1.save!
      end

      assert_raises WebMock::NetConnectNotAllowedError do
        a2.updated_at = Time.now
        a2.save!
      end
    end
    
    WebMock.allow_net_connect!
  end

  test "should get API key" do
    tb = create_team_bot
    assert_kind_of ApiKey, tb.api_key
  end

  test "should destroy related data when bot is destroyed" do
    tb = create_team_bot bot_user_id: nil
    assert_difference 'Source.count', -1 do
      assert_difference 'TeamUser.count', -1 do
        assert_difference 'ApiKey.count', -1 do
          assert_difference 'BotUser.count', -1 do
            assert_difference 'TeamBot.count', -1 do
              tb.destroy!
            end
          end
        end
      end
    end
  end

  test "should get JSON schema path" do
    tb = create_team_bot
    assert_match /^http/, tb.json_schema_url('events')
  end

  test "should show error if can't create related bot user" do
    t = create_team
    t.set_limits_max_number_of_members = 1
    t.save!
    create_team_bot team_author_id: t.id, bot_user_id: nil
    assert_raises RuntimeError do
      create_team_bot team_author_id: t.id, bot_user_id: nil
    end
  end

  test "should not be approved by default" do
    tb = create_team_bot
    assert !tb.approved
  end

  test "should not create without a team" do
    assert_raises ActiveRecord::RecordInvalid do
      create_team_bot team_author_id: nil
    end
  end

  test "should not associate twice" do
    t = create_team
    assert_difference 'TeamBotInstallation.count' do
      tb = create_team_bot team_author_id: t.id
      tb = TeamBot.find(tb.id)
      tb.team_author_id = t.id
      tb.updated_at = Time.now
      tb.save!
    end
  end

  test "should be related to teams and installations" do
    t1 = create_team
    t2 = create_team
    tb = create_team_bot team_author_id: t1.id, approved: true
    tbi = create_team_bot_installation team_id: t2.id, team_bot_id: tb.id
    assert_equal 2, tb.team_bot_installations.count
    assert_equal [t1, t2].sort, tb.reload.teams.sort
    assert_difference 'TeamBotInstallation.count', -2 do
      tb.destroy
    end
  end

  test "should install" do
    t = create_team
    tb = create_team_bot approved: true
    assert_equal [], t.reload.team_bots
    tb.install_to!(t)
    assert_equal [tb], t.reload.team_bots
  end

  test "should uninstall" do
    t = create_team
    tb = create_team_bot approved: true
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
    assert !tb.approved
    User.current = u
    assert_nothing_raised do
      tb.approve!
    end
    User.current = nil
    assert tb.reload.approved
  end

  test "should not approve bot if not admin" do
    u = create_user is_admin: false
    t = create_team
    create_team_user user: u, team: t, role: 'owner'
    tb = create_team_bot team_author_id: t.id
    assert !tb.approved
    User.current = u
    assert_raises ActiveRecord::RecordInvalid do
      tb.approve!
    end
    User.current = nil
    assert !tb.reload.approved
  end

  test "should return non-approved bots" do
    tb1 = create_team_bot approved: false
    tb2 = create_team_bot approved: true
    assert_equal [tb1], TeamBot.not_approved.to_a
  end

  test "should set version" do
    tb = create_team_bot
    assert_equal '0.0.1', tb.version
    tb.version = '0.0.2'
    tb.save!
    assert_equal '0.0.2', tb.reload.version
  end

  test "should set source code URL" do
    tb = create_team_bot
    assert_nil tb.source_code_url
    tb.source_code_url = 'https://github.com/meedan/check-api-bots'
    tb.save!
    assert_equal 'https://github.com/meedan/check-api-bots', tb.reload.source_code_url
  end

  test "should not be limited by default" do
    tb = create_team_bot
    assert !tb.limited
    tb.limited = true
    tb.save!
    assert tb.reload.limited
  end

  test "should set identifier" do
    t = create_team slug: 'test'
    tb = create_team_bot name: 'My Bot', team_author_id: t.id
    assert_equal 'bot_test_my_bot', tb.reload.identifier
    tb = create_team_bot name: 'My Bot!', team_author_id: t.id
    assert_equal 'bot_test_my_bot_1', tb.reload.identifier
  end

  test "should define bot role" do
    tb = create_team_bot role: 'journalist', approved: true
    tu1 = TeamUser.where(team_id: tb.team_author_id, user_id: tb.bot_user_id).last
    assert_equal 'journalist', tu1.role
    tbi = create_team_bot_installation team_bot_id: tb.id
    tu2 = TeamUser.where(team_id: tbi.team_id, user_id: tb.bot_user_id).last
    assert_equal 'journalist', tu2.role
    tb.role = 'contributor'
    tb.save!
    assert_equal 'contributor', tu1.reload.role
    assert_equal 'contributor', tu2.reload.role
  end

  test "should return whether bot is installed under current team" do
    tb1 = create_team_bot approved: true
    tb2 = create_team_bot approved: true
    t = create_team
    create_team_bot_installation team_id: t.id, team_bot_id: tb1.id
    User.current = create_user
    Team.current = t
    assert_equal true, tb1.reload.installed
    assert_equal false, tb2.reload.installed
    Team.current = nil
    User.current = nil
  end

  test "should get number of installations" do
    tb = create_team_bot approved: true
    assert_equal 1, tb.installations_count
    4.times { create_team_bot_installation(team_bot_id: tb.id) }
    assert_equal 5, tb.installations_count
  end

  test "should have specific events for task types" do
    Task.task_types.each do |type|
      assert TeamBot::EVENTS.include?("create_annotation_task_#{type}")
      assert TeamBot::EVENTS.include?("update_annotation_task_#{type}")
    end
  end

  test "should notify team bots in background when task is created" do
    t = create_team
    p = create_project team: t
    pm = create_project_media project: p
    tb1 = create_team_bot team_author_id: t.id, events: [{ event: 'create_annotation_task_free_text', graphql: nil }]
    tb2 = create_team_bot team_author_id: t.id, events: [{ event: 'create_annotation_task_datetime', graphql: nil }]
    
    assert_nil tb1.reload.last_called_at
    assert_nil tb2.reload.last_called_at

    create_task type: 'free_text', annotated: pm
    x = tb1.reload.last_called_at
    assert_not_nil x
    assert_nil tb2.reload.last_called_at

    create_task type: 'datetime', annotated: pm
    assert_equal x, tb1.reload.last_called_at
    assert_not_nil tb2.reload.last_called_at
  end

  test "should have a unique identifier" do
    create_team_bot identifier: 'test'
    assert_raises ActiveRecord::RecordInvalid do
      create_team_bot identifier: 'test'
    end
  end

  test "should have permissions" do
    t1 = create_team
    t2 = create_team
    u = create_user
    create_team_user team: t1, user: u, role: 'owner'
    create_team_user team: t2, user: u, role: 'editor'
    tb = nil
    assert_nothing_raised do
      with_current_user_and_team(u, t2) do
        tb = TeamBot.new({
          name: random_string,
          description: random_string,
          request_url: random_url,
          team_author_id: t1.id,
          events: [{ event: 'create_project_media', graphql: nil }]
        });
        File.open(File.join(Rails.root, 'test', 'data', 'rails.png')) do |f|
          tb.file = f
        end
        tb.save!
        tb = TeamBot.find(tb.id)
        tb.updated_at = Time.now
        tb.save!
        tb = TeamBot.find(tb.id)
        tb.destroy!
      end
    end
  end

  test "should have settings" do
    tb = create_team_bot settings: [{ name: 'foo', label: 'Foo', type: 'string', default: 'Bar' }]
    assert_equal 4, tb.settings[0].keys.size
    assert_nothing_raised do
      JSON.parse(tb.settings_as_json_schema)
    end
  end
end
