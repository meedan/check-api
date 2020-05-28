require_relative '../test_helper'

class CheckConfigTest < ActiveSupport::TestCase
  test "should return nil for missing config" do
    assert_nil CheckConfig.get('does_not_exist')
  end

  test "should return scalar value if not hash" do
    stub_configs({ 'scalar_config' => 'scalar_value' }) do
      assert_equal 'scalar_value', CheckConfig.get('scalar_config')
    end
  end

  test "should return hash value if not lang" do
    stub_configs({ 'hash_config' => { 'subkey_one' => 'subkey_one_value', 'subkey_two' => 'subkey_two_value' }}) do
      assert_equal({ 'subkey_one' => 'subkey_one_value', 'subkey_two' => 'subkey_two_value' }, CheckConfig.get('hash_config'))
    end
  end

  test "should return english value if lang hash" do
    stub_configs({ 'lang_config' => { 'lang' => { 'en' => 'en_value', 'ar' => 'ar_value' }}}) do
      assert_equal 'en_value', CheckConfig.get('lang_config')
    end
  end

  test "should return english value if no team language" do
    t = create_team
    Team.current = t
    stub_configs({ 'lang_config' => { 'lang' => { 'en' => 'en_value', 'ar' => 'ar_value' }}}) do
      assert_equal 'en_value', CheckConfig.get('lang_config')
    end
  end

  test "should return other language value if team language present" do
    t = create_team
    t.set_language = 'ar'
    Team.current = t
    stub_configs({ 'lang_config' => { 'lang' => { 'en' => 'en_value', 'ar' => 'ar_value' }}}) do
      assert_equal 'ar_value', CheckConfig.get('lang_config')
    end
  end
end
