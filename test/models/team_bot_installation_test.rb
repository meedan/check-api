require_relative '../test_helper'

class TeamBotInstallationTest < ActiveSupport::TestCase
  def setup
    super
    TeamBotInstallation.delete_all
    Sidekiq::Testing.inline!
  end

  test "should create team bot installation" do
    assert_difference 'TeamBotInstallation.count' do
      Team.current = create_team
      create_team_bot
      Team.current = nil
    end
  end

  test "should belong to team" do
    t = create_team
    tb = create_team_bot set_approved: true
    tbi = create_team_bot_installation team_id: t.id, user_id: tb.id
    assert_equal t, tbi.team
  end

  test "should belong to team bot" do
    t = create_team
    tb = create_team_bot set_approved: true
    tbi = create_team_bot_installation team_id: t.id, user_id: tb.id
    assert_equal tb, tbi.bot_user
  end

  test "should not install without team" do
    tb = create_team_bot
    assert_no_difference 'TeamBotInstallation.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_team_bot_installation team_id: nil, user_id: tb.id
      end
    end
  end

  test "should not install without bot" do
    assert_no_difference 'TeamBotInstallation.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_team_bot_installation user_id: nil
      end
    end
  end

  test "should not install more than once" do
    t = create_team
    tb = create_team_bot set_approved: true
    assert_difference 'TeamBotInstallation.count' do
      create_team_bot_installation team_id: t.id, user_id: tb.id
    end
    assert_no_difference 'TeamBotInstallation.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_team_bot_installation team_id: t.id, user_id: tb.id
      end
    end
  end

  test "should not be installed if not approved" do
    t1 = create_team
    t2 = create_team
    Team.current = t1
    tb = create_team_bot set_approved: false
    Team.current = nil

    assert_no_difference 'TeamBotInstallation.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_team_bot_installation user_id: tb.id, team_id: t2.id
      end
    end
  end

  test "should be installed if approved" do
    t1 = create_team
    t2 = create_team
    Team.current = t1
    tb = create_team_bot set_approved: true
    Team.current = nil

    assert_difference 'TeamBotInstallation.count' do
      create_team_bot_installation user_id: tb.id, team_id: t2.id
    end
  end

  test "should gain access to team when installation is created" do
    tb = create_team_bot set_approved: true
    t = create_team
    assert_difference 'TeamUser.count' do
      create_team_bot_installation team_id: t.id, user_id: tb.id
    end
  end

  test "should lose access to team when bot is uninstalled" do
    tbi = create_team_bot_installation
    assert_difference 'TeamUser.count', -1 do
      tbi.destroy
    end
  end

  test "should have settings" do
    tb = create_team_bot_installation
    assert_equal({}, tb.settings)
    tb.set_foo = 'bar'
    assert_equal 'bar', tb.get_foo
    assert_equal({ 'foo': 'bar' }, tb.settings)
    assert_kind_of String, tb.json_settings
    b = create_team_bot login: 'smooch', set_approved: true
    tb = create_team_bot_installation user_id: b.id
    assert tb.settings.kind_of?(Hash)
    assert_not_empty tb.settings
  end

  test "should get alegre settings with fallback values" do
    b = create_team_bot login: 'alegre', set_approved: true
    tb = create_team_bot_installation user_id: b.id
    # verifiy settings with fallback values
    stub_configs({ 'text_length_matching_threshold' => 7, 'text_elasticsearch_suggestion_threshold' => 0.8, 'image_hash_suggestion_threshold' => 0.6}) do
      settings = tb.alegre_settings
      assert_not_empty settings
      assert_equal 7, settings['text_length_matching_threshold']
      assert_equal 0.8, settings['text_elasticsearch_suggestion_threshold']
      assert_equal 0.6, settings['image_hash_suggestion_threshold']
      # override default settings
      settings['text_length_matching_threshold'] = 4
      settings['text_elasticsearch_suggestion_threshold'] = 0.4
      tb.json_settings = settings.to_json
      tb.save!
      settings = tb.reload.alegre_settings
      assert_equal 4, settings['text_length_matching_threshold']
      assert_equal 0.4, settings['text_elasticsearch_suggestion_threshold']
      assert_equal 0.6, settings['image_hash_suggestion_threshold']
    end
  end

  test "should follow schema" do
    schema = [{
      name: 'foo',
      label: 'Foo',
      type: 'number',
      default: 0
    }]
    tb = create_team_bot set_settings: schema, set_approved: true
    tbi = create_team_bot_installation(user_id: tb.id, settings: { foo: 'bar' })
    assert_raises ActiveRecord::RecordInvalid do
      tbi.save!
    end
    assert_nothing_raised do
      tbi = create_team_bot_installation(user_id: tb.id, settings: { foo: 10 })
      tbi.save!
      tbi = create_team_bot_installation(user_id: tb.id, json_settings: '{"foo":10}')
      tbi.save!
    end
  end

  test "should define settings as JSON" do
    tbi = create_team_bot_installation
    assert_nil tbi.get_foo
    tbi.json_settings = '{"foo":"bar"}'
    tbi.save!
    assert_equal 'bar', tbi.reload.get_foo
  end

  test "should set default settings" do
    tb = create_team_bot set_approved: true
    tb.set_settings([
      { "name" => "archive_archive_org_enabled", "label" => "Enable Archive.org", "type" => "boolean", "default" => "true" },
      { "name" => "archive_keep_backup_enabled", "label" => "Enable Video Vault", "type" => "boolean", "default" => "false" }
    ])
    tb.save!
    tbi = create_team_bot_installation user_id: tb.id
    assert tbi.get_archive_archive_org_enabled
    assert !tbi.get_archive_keep_backup_enabled
  end

  test "should not set default settings" do
    tb = create_team_bot set_approved: true
    tb.set_settings([
      { "name" => "archive_archive_org_enabled", "label" => "Enable Archive.org", "type" => "boolean", "default" => "true" },
      { "name" => "archive_keep_backup_enabled", "label" => "Enable Video Vault", "type" => "boolean", "default" => "false" }
    ])
    tb.save!
    tbi = create_team_bot_installation user_id: tb.id, settings: { archive_perma_cc_enabled: false }
    assert tbi.get_archive_archive_org_enabled
    assert !tbi.get_archive_keep_backup_enabled
  end

  test "should add files" do
    b = create_team_bot login: 'smooch', set_approved: true
    tbi = create_team_bot_installation user_id: b.id, settings: { smooch_workflows: [{}, {}] }
    tbi = TeamBotInstallation.find(tbi.id)
    File.open(File.join(Rails.root, 'test', 'data', 'rails.png')) do |f|
      tbi.file = ['', f]
    end
    tbi.save!
    assert tbi.reload.get_smooch_workflows[0]['smooch_greeting_image'].blank?
    assert_match /rails.png/, tbi.reload.get_smooch_workflows[1]['smooch_greeting_image']
  end

  test "should not edit same instance concurrently" do
    tbi = create_team_bot_installation
    assert_equal 0, tbi.lock_version
    assert_nothing_raised do
      tbi.json_settings = '{"foo":"bar"}'
      tbi.save!
    end
    assert_equal 1, tbi.reload.lock_version
    assert_raises ActiveRecord::StaleObjectError do
      tbi.lock_version = 0
      tbi.json_settings = '{"foo":"bar2"}'
      tbi.save!
    end
    assert_equal 1, tbi.reload.lock_version
    assert_nothing_raised do
      tbi.lock_version = 0
      tbi.updated_at = Time.now + 1
      tbi.save!
    end
  end

  test "should not set Smooch Bot WhatsApp token if not a super-admin" do
    t = create_team
    u1 = create_user is_admin: true
    create_team_user user: u1, team: t, role: 'admin'
    u2 = create_user is_admin: false
    create_team_user user: u2, team: t, role: 'admin'
    b = create_team_bot login: 'smooch', set_approved: true
    tbi = create_team_bot_installation user_id: b.id, team_id: t.id, settings: { turnio_token: 'abc123', turnio_secret: 'test' }
    assert_equal 'test', tbi.reload.get_turnio_secret
    assert_equal 'abc123', tbi.reload.get_turnio_token

    with_current_user_and_team(u1, t) do
      tbi = TeamBotInstallation.find(tbi.id)
      tbi.settings = { turnio_token: 'def456', turnio_secret: 'foo' }
      tbi.save!
      assert_equal 'foo', tbi.reload.get_turnio_secret
      assert_equal 'def456', tbi.reload.get_turnio_token
    end

    with_current_user_and_team(u2, t) do
      tbi = TeamBotInstallation.find(tbi.id)
      tbi.settings = { turnio_token: 'ghi789', turnio_secret: 'bar' }
      tbi.save!
      assert_equal 'bar', tbi.reload.get_turnio_secret
      assert_equal 'def456', tbi.reload.get_turnio_token
    end
  end

  test "should not trigger additional queries when accessing bot_user" do
    team_bot = create_team_bot set_approved: true
    team_bot_installation = create_team_bot_installation(user_id: team_bot.id)

    initial_query_count = ActiveRecord::Base.connection.query_cache.size

    assert_queries(0) do
      team_bot_installation.bot_user
    end

    assert_equal initial_query_count, ActiveRecord::Base.connection.query_cache.size
  end
end
