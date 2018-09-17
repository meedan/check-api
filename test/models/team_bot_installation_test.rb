require_relative '../test_helper'

class TeamBotInstallationTest < ActiveSupport::TestCase
  def setup
    super
    TeamBotInstallation.delete_all
    Sidekiq::Testing.inline!
  end

  test "should create team bot installation" do
    assert_difference 'TeamBotInstallation.count' do
      create_team_bot
    end
  end

  test "should belong to team" do
    t = create_team
    tb = create_team_bot approved: true
    tbi = create_team_bot_installation team_id: t.id, team_bot_id: tb.id
    assert_equal t, tbi.team
  end

  test "should belong to team bot" do
    t = create_team
    tb = create_team_bot approved: true
    tbi = create_team_bot_installation team_id: t.id, team_bot_id: tb.id
    assert_equal tb, tbi.team_bot
  end

  test "should not install without team" do
    tb = create_team_bot
    assert_no_difference 'TeamBotInstallation.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_team_bot_installation team_id: nil, team_bot_id: tb.id
      end
    end
  end

  test "should not install without bot" do
    assert_no_difference 'TeamBotInstallation.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_team_bot_installation team_bot_id: nil
      end
    end
  end

  test "should not install more than once" do
    t = create_team
    tb = create_team_bot approved: true
    assert_difference 'TeamBotInstallation.count' do
      create_team_bot_installation team_id: t.id, team_bot_id: tb.id
    end
    assert_no_difference 'TeamBotInstallation.count' do
      assert_raises ActiveRecord::RecordNotUnique do
        create_team_bot_installation team_id: t.id, team_bot_id: tb.id
      end
    end
  end

  test "should not be installed if not approved" do
    t1 = create_team
    t2 = create_team
    tb = create_team_bot team_author_id: t1.id, approved: false

    assert_no_difference 'TeamBotInstallation.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_team_bot_installation team_bot_id: tb.id, team_id: t2.id
      end
    end
  end

  test "should be installed if approved" do
    t1 = create_team
    t2 = create_team
    tb = create_team_bot team_author_id: t1.id, approved: true

    assert_difference 'TeamBotInstallation.count' do
      create_team_bot_installation team_bot_id: tb.id, team_id: t2.id
    end
  end

  test "should gain access to team when installation is created" do
    tb = create_team_bot approved: true
    t = create_team
    assert_difference 'TeamUser.count' do
      create_team_bot_installation team_id: t.id, team_bot_id: tb.id
    end
  end

  test "should lose access to team when bot is uninstalled" do
    tbi = create_team_bot_installation
    assert_difference 'TeamUser.count', -1 do
      tbi.destroy
    end
  end

  test "should not be installed if limited" do
    t1 = create_team slug: 'test'
    t2 = create_team
    tb = create_team_bot name: 'Test Bot', team_author_id: t1.id, approved: true, limited: true
    assert_equal 'bot_test_test_bot', tb.reload.identifier
    assert !t2.get_limits_bot_test_test_bot

    assert_no_difference 'TeamBotInstallation.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_team_bot_installation team_bot_id: tb.id, team_id: t2.id
      end
    end
  end

  test "should be installed if limited" do
    t1 = create_team slug: 'test'
    t2 = create_team
    t2.set_limits_bot_test_test_bot(true)
    t2.save!
    tb = create_team_bot name: 'Test Bot', team_author_id: t1.id, approved: true, limited: true
    assert_equal 'bot_test_test_bot', tb.reload.identifier
    assert t2.get_limits_bot_test_test_bot

    assert_difference 'TeamBotInstallation.count' do
      assert_nothing_raised do
        create_team_bot_installation team_bot_id: tb.id, team_id: t2.id
      end
    end
  end

  test "should have settings" do
    tb = create_team_bot_installation
    assert_equal({}, tb.settings)
    tb.set_foo = 'bar'
    assert_equal 'bar', tb.get_foo
    assert_equal({ 'foo': 'bar' }, tb.settings)
    assert_kind_of String, tb.json_settings
  end

  test "should follow schema" do
    schema = [{
      name: 'foo',
      label: 'Foo',
      type: 'number',
      default: 0
    }]
    tb = create_team_bot settings: schema, approved: true
    assert_raises ActiveRecord::RecordInvalid do
      create_team_bot_installation(team_bot_id: tb.id, settings: { foo: 'bar' })
    end
    assert_nothing_raised do
      create_team_bot_installation(team_bot_id: tb.id, settings: { foo: 10 })
      create_team_bot_installation(team_bot_id: tb.id, json_settings: '{"foo":10}')
    end
  end

  test "should define settings as JSON" do
    tbi = create_team_bot_installation
    assert_nil tbi.get_foo
    tbi.json_settings = '{"foo":"bar"}'
    tbi.save!
    assert_equal 'bar', tbi.reload.get_foo
  end
end
