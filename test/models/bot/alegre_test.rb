require File.join(File.expand_path(File.dirname(__FILE__)), '..', '..', 'test_helper')

class Bot::AlegreTest < ActiveSupport::TestCase
  def setup
    super
    ft = DynamicAnnotation::FieldType.where(field_type: 'language').last || create_field_type(field_type: 'language', label: 'Language')
    at = create_annotation_type annotation_type: 'language', label: 'Language'
    create_field_instance annotation_type_object: at, name: 'language', label: 'Language', field_type_object: ft, optional: false
    @bot = create_alegre_bot
    @pm = create_project_media
    AlegreClient.host = 'http://alegre'
  end

  test "should return language" do
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      AlegreClient::Mock.mock_languages_identification_returns_text_language do
        WebMock.disable_net_connect! allow: [CONFIG['elasticsearch_host']]
        assert_difference 'Annotation.count' do
          assert_equal 'fr', @bot.get_language_from_alegre('I like apples', @pm)
        end
      end
    end
  end

  test "should return null if text is blank" do
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      AlegreClient::Mock.mock_languages_identification_returns_parameter_text_is_missing do
        WebMock.disable_net_connect! allow: [CONFIG['elasticsearch_host']]
        assert_nil @bot.get_language_from_alegre('', @pm)
      end
    end
  end

  test "should return null if Alegre is not setup" do
    stub_configs({ 'alegre_host' => '', 'alegre_token' => '' }) do
      assert_nil @bot.get_language_from_alegre('Test', @pm)
    end
  end

  test "should return access denied" do
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      AlegreClient::Mock.mock_languages_identification_returns_access_denied do
        WebMock.disable_net_connect! allow: [CONFIG['elasticsearch_host']]
        assert_nil @bot.get_language_from_alegre('Test', @pm)
      end
    end
  end

  test "should return language name" do
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      AlegreClient::Mock.mock_languages_identification_returns_text_language do
        WebMock.disable_net_connect! allow: [CONFIG['elasticsearch_host']]
        assert_equal 'fr', @bot.get_language_from_alegre('I like apples', @pm)
        assert_equal 'fr', @bot.language(@pm)
      end
    end
  end

  test "should return null for language name if there is no annotation" do
    pm = create_project_media
    assert_nil @bot.language(pm)
  end
end
