require_relative '../test_helper'

class DummySettingsModel
  def self.serialize(_field); end

  include CheckSettings
  attr_accessor :settings, :preferences

  check_settings :settings
  check_settings :preferences

  def initialize(settings = {}, preferences = {})
    @settings = settings
    @preferences = preferences
  end

  def [](field)
    instance_variable_get("@#{field}")
  end

  def []=(field, value)
    instance_variable_set("@#{field}", value)
  end
end

class CheckSettingsTest < ActiveSupport::TestCase
  test "can set, get, and reset settings for a given class" do
    obj = DummySettingsModel.new

    obj.set_settings_language = 'en'
    assert_equal 'en', obj.get_settings_language
    obj.reset_settings_language
    assert_nil obj.get_settings_language
  end

  test "set/get/reset method works the same as accessing the hash settings directly" do
    obj = DummySettingsModel.new

    obj.set_settings_bot = 'active'
    assert_equal obj.get_settings_bot, obj.settings['bot']
    obj.reset_settings_bot
    assert_nil obj.settings['bot']
    obj.settings['language'] = 'pt'
    assert_equal 'pt', obj.get_settings_language
  end

  test "works with a plain hash" do
    obj = DummySettingsModel.new({ 'language' => 'en' })

    assert_equal 'en', obj.get_settings_language
    obj.set_settings_language = 'es'
    assert_equal 'es', obj.get_settings_language
  end

  test "works with HashWithIndifferentAccess" do
    obj = DummySettingsModel.new({ bot: 'enabled' }.with_indifferent_access)

    assert_equal 'enabled', obj.get_settings_bot
    obj.set_settings_bot = 'disabled'
    assert_equal 'disabled', obj.get_settings_bot
  end

  test "works with ActionController::Parameters" do
    params = ActionController::Parameters.new({ language: 'de' }).permit(:language)
    obj = DummySettingsModel.new(params)

    assert_equal 'de', obj.get_settings_language
    obj.set_settings_language = 'it'
    assert_equal 'it', obj.get_settings_language
    obj.reset_settings_language
    assert_nil obj.get_settings_language
  end

  test "works with ActionController::Parameters as nested field" do
    events_params = ActionController::Parameters.new({
      team_author_id: 111,
      version: "0.0.1"
    }).permit(:team_author_id, :version)

    obj = DummySettingsModel.new({ "events" => events_params })

    events = obj.get_settings_events

    assert_equal 111, events[:team_author_id]
    assert_equal 111, events["team_author_id"]
    assert_equal "0.0.1", events[:version]
    assert_equal "0.0.1", events["version"]
  end
end
