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
      smooch_menu_option_id: 'test',
      smooch_menu_option_label: 'newsletter label'
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

  test 'should list keywords' do
    team = create_team_with_smooch_bot_installed
    nlu = SmoochNlu.new(team.slug)
    nlu.enable!
    Bot::Alegre.expects(:request).with{ |x, y, _z| x == 'post' && y == '/text/similarity/' }.once
    nlu.add_keyword_to_menu_option('en', 'main', 0, 'subscribe')
    expected_output = {
      'en' => {
        'main' => [
          {'index' => 0, 'title' => 'newsletter label', 'keywords' => ['subscribe'], 'id' => 'test'}
        ]
      }
    }
    # Since the demo team has only one language and menu all of the following are nearly the same
    assert_equal nlu.list_menu_keywords('en', 'main'), expected_output
    assert_equal nlu.list_menu_keywords('en', ['main']), expected_output

    # These calls should include an empty secondary menu
    expected_output['en']['secondary'] = []
    assert_equal nlu.list_menu_keywords(), expected_output
    assert_equal nlu.list_menu_keywords('en'), expected_output
    assert_equal nlu.list_menu_keywords(['en']), expected_output
  end

  test 'should add keyword if it does not exist' do
    Bot::Alegre.expects(:request).with{ |x, y, _z| x == 'post' && y == '/text/similarity/' }.once
    team = create_team_with_smooch_bot_installed
    SmoochNlu.new(team.slug).add_keyword_to_menu_option('en', 'main', 0, 'subscribe to the newsletter')
  end

  test 'should not add keyword if it exists' do
    team = create_team_with_smooch_bot_installed
    nlu = SmoochNlu.new(team.slug)
    Bot::Alegre.expects(:request).with{ |x, y, _z| x == 'post' && y == '/text/similarity/' }.once
    nlu.add_keyword_to_menu_option('en', 'main', 0, 'subscribe to the newsletter')
    Bot::Alegre.expects(:request).with{ |x, y, _z| x == 'post' && y == '/text/similarity/' }.never
    nlu.add_keyword_to_menu_option('en', 'main', 0, 'subscribe to the newsletter')
  end

  test 'should delete keyword' do
    Bot::Alegre.expects(:request).with{ |x, y, _z| x == 'delete' && y == '/text/similarity/' }.once
    team = create_team_with_smooch_bot_installed
    SmoochNlu.new(team.slug).remove_keyword_from_menu_option('en', 'main', 0, 'subscribe to the newsletter')
  end

  test 'should not return a menu option if NLU is not enabled' do
    Bot::Alegre.stubs(:request).never
    team = create_team_with_smooch_bot_installed
    SmoochNlu.new(team.slug).disable!
    Bot::Smooch.get_installation('smooch_id', 'test')
    assert_equal [], SmoochNlu.menu_options_from_message('I want to subscribe to the newsletter', 'en', @menu_options, random_string)
  end

  test 'should return a menu option if NLU is enabled' do
    Bot::Alegre.stubs(:request).with{ |x, y, z| x == 'post' && y == '/text/similarity/search/' && z[:text] =~ /newsletter/ }.returns({ 'result' => [
      { '_score' => 0.9, '_source' => { 'context' => { 'menu_option_id' => 'test' } } },
    ]})
    team = create_team_with_smooch_bot_installed
    SmoochNlu.new(team.slug).enable!
    Bot::Smooch.get_installation('smooch_id', 'test')
    assert_not_nil SmoochNlu.menu_options_from_message('I want to subscribe to the newsletter', 'en', @menu_options, random_string)
  end
end
