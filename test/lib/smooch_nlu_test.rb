require_relative '../test_helper'

class SmoochNluTest < ActiveSupport::TestCase
  def setup
    WebMock.disable_net_connect! allow: /#{CheckConfig.get('elasticsearch_host')}|#{CheckConfig.get('storage_endpoint')}/
  end

  def teardown
    Rails.cache.clear
  end

  def create_team_with_smooch_bot_installed
    team = create_team
    bot = create_team_bot login: 'smooch', name: 'Smooch', set_approved: true
    @menu_options = [{
      smooch_menu_option_value: 'newsletter',
      smooch_menu_option_id: 'test'
    }.with_indifferent_access]
    settings = {
      team_id: team.id,
      smooch_id: 'test',
      smooch_workflows: [
        {
          smooch_workflow_language: 'en',
          smooch_state_main: {
            smooch_menu_options: @menu_options
          }
        }
      ]
    }.with_indifferent_access
    create_team_bot_installation team_id: team.id, user_id: bot.id, settings: settings
    team
  end

  test 'should raise exception if there is no team with provided slug' do
    assert_raises SmoochNlu::SmoochBotNotInstalledError do
      SmoochNlu.new(random_string)
    end
  end

  test 'should raise exception if Smooch Bot is not installed' do
    assert_raises SmoochNlu::SmoochBotNotInstalledError do
      SmoochNlu.new(create_team.slug)
    end
  end

  test 'should enable' do
    team = create_team_with_smooch_bot_installed
    assert !SmoochNlu.new(team.slug).enabled?
    SmoochNlu.new(team.slug).enable!
    assert SmoochNlu.new(team.slug).enabled?
  end

  test 'should disable' do
    team = create_team_with_smooch_bot_installed
    SmoochNlu.new(team.slug).enable!
    assert SmoochNlu.new(team.slug).enabled?
    SmoochNlu.new(team.slug).disable!
    assert !SmoochNlu.new(team.slug).enabled?
  end

  test 'should add keyword if it does not exist' do
    Bot::Alegre.expects(:request_api).with{ |x, y, _z| x == 'post' && y == '/text/similarity/' }.once
    team = create_team_with_smooch_bot_installed
    SmoochNlu.new(team.slug).add_keyword('en', 'main', 0, 'subscribe to the newsletter')
  end

  test 'should not add keyword if it exists' do
    team = create_team_with_smooch_bot_installed
    nlu = SmoochNlu.new(team.slug)
    Bot::Alegre.expects(:request_api).with{ |x, y, _z| x == 'post' && y == '/text/similarity/' }.once
    nlu.add_keyword('en', 'main', 0, 'subscribe to the newsletter')
    Bot::Alegre.expects(:request_api).with{ |x, y, _z| x == 'post' && y == '/text/similarity/' }.never
    nlu.add_keyword('en', 'main', 0, 'subscribe to the newsletter')
  end

  test 'should delete keyword' do
    Bot::Alegre.expects(:request_api).with{ |x, y, _z| x == 'delete' && y == '/text/similarity/' }.once
    team = create_team_with_smooch_bot_installed
    SmoochNlu.new(team.slug).remove_keyword('en', 'main', 0, 'subscribe to the newsletter')
  end

  test 'should not return a menu option if NLU is not enabled' do
    Bot::Alegre.stubs(:request_api).never
    team = create_team_with_smooch_bot_installed
    SmoochNlu.new(team.slug).disable!
    Bot::Smooch.get_installation('smooch_id', 'test')
    assert_nil SmoochNlu.menu_option_from_message('I want to subscribe to the newsletter', @menu_options)
  end

  test 'should return a menu option if NLU is enabled' do
    Bot::Alegre.stubs(:request_api).with{ |x, y, z| x == 'get' && y == '/text/similarity/' && z[:text] =~ /newsletter/ }.returns({ 'result' => [
      { '_score' => 0.9, '_source' => { 'context' => { 'menu_option_id' => 'test' } } },
    ]})
    team = create_team_with_smooch_bot_installed
    SmoochNlu.new(team.slug).enable!
    Bot::Smooch.get_installation('smooch_id', 'test')
    assert_not_nil SmoochNlu.menu_option_from_message('I want to subscribe to the newsletter', @menu_options)
  end
end
