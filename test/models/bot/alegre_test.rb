require_relative '../../test_helper'

class Bot::AlegreTest < ActiveSupport::TestCase
  def setup
    super
    ft = DynamicAnnotation::FieldType.where(field_type: 'language').last || create_field_type(field_type: 'language', label: 'Language')
    at = create_annotation_type annotation_type: 'language', label: 'Language'
    create_field_instance annotation_type_object: at, name: 'language', label: 'Language', field_type_object: ft, optional: false
    @bot = create_alegre_bot
    p = create_project
    p.set_languages = ['en','pt','es']
    p.save!
    @pm = create_project_media project: p
    AlegreClient.host = 'http://alegre'
  end

  test "should return language" do
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      AlegreClient::Mock.mock_languages_identification_returns_text_language do
        WebMock.disable_net_connect! allow: [CONFIG['elasticsearch_host']]
        assert_difference 'Annotation.count' do
          assert_equal 'en', @bot.get_language_from_alegre('I like apples', @pm)
        end
      end
    end
  end

  test "should return null if there is an error" do
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      AlegreClient::Mock.mock_languages_identification_returns_error do
        WebMock.disable_net_connect! allow: [CONFIG['elasticsearch_host']]
        assert_nil @bot.get_language_from_alegre('', @pm)
      end
    end
  end

  test "should return language object" do
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      AlegreClient::Mock.mock_languages_identification_returns_text_language do
        WebMock.disable_net_connect! allow: [CONFIG['elasticsearch_host']]
        assert_equal 'en', @bot.get_language_from_alegre('I like apples', @pm)
        assert_equal 'en', @bot.language_object(@pm).value
      end
    end
  end

  test "should return null for language object if there is no annotation" do
    pm = create_project_media
    assert_nil @bot.language_object(pm)
  end

  test "should have profile image" do
    b = create_alegre_bot
    assert_kind_of String, b.profile_image
  end

  test "should return null language if Alegre client throws exception" do
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      AlegreClient::Request.stubs(:get_languages_identification).raises(StandardError)
      lang = @bot.get_language_from_alegre('I like apples', @pm)
      AlegreClient::Request.unstub(:get_languages_identification)
      assert_nil lang
    end
  end

  test "should return no machine translations if Alegre client throws exception" do
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      AlegreClient::Request.stubs(:get_mt).raises(StandardError)
      translations = @bot.get_mt_from_alegre(@pm, @pm.user)
      AlegreClient::Request.unstub(:get_mt)
      assert_equal [], translations
    end
  end
end
