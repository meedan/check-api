require_relative '../../test_helper'

class Bot::AlegreTest < ActiveSupport::TestCase
  def setup
    super
    ft = DynamicAnnotation::FieldType.where(field_type: 'language').last || create_field_type(field_type: 'language', label: 'Language')
    at = create_annotation_type annotation_type: 'language', label: 'Language'
    create_field_instance annotation_type_object: at, name: 'language', label: 'Language', field_type_object: ft, optional: false
    @bot = create_alegre_bot
    p = create_project
    p.team.set_languages = ['en','pt','es']
    p.team.save!
    p.save!
    m = create_claim_media quote: 'I like apples'
    @pm = create_project_media project: p, media: m
    AlegreClient.host = 'http://alegre'
  end

  test "should return language" do
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      AlegreClient::Mock.mock_languages_identification_returns_text_language do
        WebMock.disable_net_connect! allow: [CONFIG['elasticsearch_host']]
        assert_difference 'Annotation.count' do
          assert_equal 'en', @bot.get_language(@pm)
        end
      end
    end
  end

  test "should return und language if there is an error" do
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      AlegreClient::Mock.mock_languages_identification_returns_error do
        WebMock.disable_net_connect! allow: [CONFIG['elasticsearch_host']]
        assert_equal 'und', @bot.get_language(@pm)
      end
      AlegreClient::Request.stubs(:get_languages_identification).raises(StandardError)
      lang = @bot.get_language(@pm)
      AlegreClient::Request.unstub(:get_languages_identification)
      assert_equal 'und', lang
      AlegreClient::Request.stubs(:get_languages_identification).returns({
        'type' => 'language',
        'data' => [['UND', 1.0]]
      })
      lang = @bot.get_language(@pm)
      AlegreClient::Request.unstub(:get_languages_identification)
      assert_equal 'und', lang
    end
  end

  test "should return language object" do
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      AlegreClient::Mock.mock_languages_identification_returns_text_language do
        WebMock.disable_net_connect! allow: [CONFIG['elasticsearch_host']]
        assert_equal 'en', @bot.get_language(@pm)
        assert_equal 'en', @bot.language_object(@pm).value
      end
    end
  end

  test "should return null language object if there is no annotation" do
    pm = create_project_media
    assert_nil @bot.language_object(pm)
  end

  test "should notify Pusher when language is saved" do
    lang = @bot.send(:save_language, @pm, 'en')
    assert lang.sent_to_pusher
  end

  test "should link similar images" do
    ft = create_field_type field_type: 'image_path', label: 'Image Path'
    at = create_annotation_type annotation_type: 'reverse_image', label: 'Reverse Image'
    create_field_instance annotation_type_object: at, name: 'reverse_image_path', label: 'Reverse Image', field_type_object: ft, optional: false
    vframe_url = CONFIG['vframe_host'] + '/api/v1/match'
    WebMock.stub_request(:post, vframe_url)
    .to_return(body: '{"results":[]}')
    pm1 = create_project_media project: @pm.project, media: create_uploaded_image
    @bot.get_image_similarities(pm1)
    WebMock.stub_request(:post, vframe_url)
    .to_return(body: '{"results":[{"context":{"project_media_id":'+pm1.id.to_s+'}}]}')
    pm2 = create_project_media project: @pm.project, media: create_uploaded_image
    @bot.get_image_similarities(pm2)
    r = Relationship.where("source_id = :source_id AND target_id = :target_id", {
      :source_id => pm1.id,
      :target_id => pm2.id
    })
    assert_equal 1, r.length
    WebMock.stub_request(:post, vframe_url)
    .to_return(body: 'invalid result')
    assert_nothing_raised do
      @bot.get_image_similarities(pm2)
    end
    WebMock.stub_request(:post, vframe_url)
    .to_return(body: '{"error":"message"}')
    assert_nothing_raised do
      @bot.get_image_similarities(pm2)
    end
  end

  test "should return true when bot is called successfully" do
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      AlegreClient::Mock.mock_languages_identification_returns_text_language do
        WebMock.disable_net_connect! allow: [CONFIG['elasticsearch_host']]
        assert Bot::Alegre.run({ data: { dbid: @pm.id }, event: 'create_project_media' })
      end
    end
  end

  test "should return false when bot cannot be called" do
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      AlegreClient::Mock.mock_languages_identification_returns_text_language do
        WebMock.disable_net_connect! allow: [CONFIG['elasticsearch_host']]
        assert !Bot::Alegre.run({ event: 'create_project_media' })
      end
    end
  end

  test "should capture error when calling bot" do
    Bot::Alegre.any_instance.stubs(:get_language).raises(RuntimeError)
    assert_nothing_raised do
      Bot::Alegre.run('test')
    end
    Bot::Alegre.any_instance.unstub(:get_language)
  end

  test "should add relationships" do
    p = create_project
    pm1 = create_project_media project: p
    pm2 = create_project_media project: p
    pm3 = create_project_media project: p
    create_relationship source_id: pm3.id, target_id: pm2.id
    @bot.add_relationships(pm1, [pm2.id])
    r = Relationship.last
    assert_equal pm1, r.target
    assert_equal pm3, r.source
  end
end
