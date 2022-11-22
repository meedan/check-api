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
end
