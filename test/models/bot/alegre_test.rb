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

  test "should return und if there is an error" do
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

  test "should return null for language object if there is no annotation" do
    pm = create_project_media
    assert_nil @bot.language_object(pm)
  end

  test "should have profile image" do
    b = create_alegre_bot
    assert_kind_of String, b.profile_image
  end

  # test "should return no machine translations if Alegre client throws exception" do
  #   stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
  #     AlegreClient::Request.stubs(:get_mt).raises(StandardError)
  #     translations = @bot.get_mt_from_alegre(@pm, @pm.user)
  #     AlegreClient::Request.unstub(:get_mt)
  #     assert_equal [], translations
  #   end
  # end

  # test "should not link similar claims when none exist" do
  #   stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
  #     AlegreClient::Mock.mock_languages_identification_returns_text_language do
  #       WebMock.disable_net_connect! allow: [CONFIG['elasticsearch_host']]
  #       response = '{"result":[]}'
  #       WebMock.stub_request(:post, 'http://alegre/similarity/query')
  #       .with(body: {
  #         text: 'I like apples',
  #         language: 'en',
  #         context: {
  #           project_id: @pm.project.id
  #         }
  #       })
  #       .to_return(body: response, status: 200)
  #       WebMock.stub_request(:post, 'http://alegre/similarity/')
  #       .with(body: {
  #         text: 'I like apples',
  #         language: 'en',
  #         context: {
  #           team_id: @pm.project.team.id,
  #           project_id: @pm.project.id,
  #           project_media_id: @pm.id
  #         }
  #       })
  #       .to_return(status: 200)
  #       @bot.create_similarities_from_alegre(@pm)
  #       r = Relationship.where("target_id = :target_id", {
  #         :target_id => @pm.id
  #       })
  #       assert_equal 0, r.length
  #       WebMock.allow_net_connect!
  #     end
  #   end
  # end

  # test "should link similar claims without existing relationships" do
  #   stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
  #     AlegreClient::Mock.mock_languages_identification_returns_text_language do
  #       WebMock.disable_net_connect! allow: [CONFIG['elasticsearch_host']]
  #       pm1 = create_project_media project: @pm.project
  #       response = '{"result":[{"_source":{"context":{"project_media_id":'+pm1.id.to_s+'}}}]}'
  #       WebMock.stub_request(:post, 'http://alegre/similarity/query')
  #       .with(body: {
  #         text: 'I like apples',
  #         language: 'en',
  #         context: {
  #           project_id: @pm.project.id
  #         }
  #       })
  #       .to_return(body: response, status: 200)
  #       WebMock.stub_request(:post, 'http://alegre/similarity/')
  #       .with(body: {
  #         text: 'I like apples',
  #         language: 'en',
  #         context: {
  #           team_id: @pm.project.team.id,
  #           project_id: @pm.project.id,
  #           project_media_id: @pm.id
  #         }
  #       })
  #       .to_return(status: 200)
  #       @bot.create_similarities_from_alegre(@pm)
  #       r = Relationship.where("source_id = :source_id AND target_id = :target_id", {
  #         :source_id => pm1.id,
  #         :target_id => @pm.id
  #       })
  #       assert_equal 1, r.length
  #       WebMock.allow_net_connect!
  #     end
  #   end
  # end

  # test "should link similar claims with existing relationships" do
  #   stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
  #     AlegreClient::Mock.mock_languages_identification_returns_text_language do
  #       WebMock.disable_net_connect! allow: [CONFIG['elasticsearch_host']]
  #       pm1 = create_project_media project: @pm.project
  #       pm2 = create_project_media project: @pm.project
  #       create_relationship({ source_id: pm1.id, target_id: pm2.id })
  #       response = '{"result":[{"_source":{"context":{"project_media_id":'+pm1.id.to_s+'}}}]}'
  #       WebMock.stub_request(:post, 'http://alegre/similarity/query')
  #       .with(body: {
  #         text: 'I like apples',
  #         language: 'en',
  #         context: {
  #           project_id: @pm.project.id
  #         }
  #       })
  #       .to_return(body: response, status: 200)
  #       WebMock.stub_request(:post, 'http://alegre/similarity/')
  #       .with(body: {
  #         text: 'I like apples',
  #         language: 'en',
  #         context: {
  #           team_id: @pm.project.team.id,
  #           project_id: @pm.project.id,
  #           project_media_id: @pm.id
  #         }
  #       })
  #       .to_return(status: 200)
  #       @bot.create_similarities_from_alegre(@pm)
  #       r = Relationship.where("source_id = :source_id AND target_id = :target_id", {
  #         :source_id => pm1.id,
  #         :target_id => @pm.id
  #       })
  #       assert_equal 1, r.length
  #       WebMock.allow_net_connect!
  #     end
  #   end
  # end

  # test "should flatten 3-level similarity relationships" do
  #   stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
  #     AlegreClient::Mock.mock_languages_identification_returns_text_language do
  #       WebMock.disable_net_connect! allow: [CONFIG['elasticsearch_host']]
  #       pm1 = create_project_media project: @pm.project
  #       pm2 = create_project_media project: @pm.project
  #       create_relationship({ source_id: pm1.id, target_id: pm2.id })
  #       response = '{"result":[{"_source":{"context":{"project_media_id":'+pm2.id.to_s+'}}}]}'
  #       WebMock.stub_request(:post, 'http://alegre/similarity/query')
  #       .with(body: {
  #         text: 'I like apples',
  #         language: 'en',
  #         context: {
  #           project_id: @pm.project.id
  #         }
  #       })
  #       .to_return(body: response, status: 200)
  #       WebMock.stub_request(:post, 'http://alegre/similarity/')
  #       .with(body: {
  #         text: 'I like apples',
  #         language: 'en',
  #         context: {
  #           team_id: @pm.project.team.id,
  #           project_id: @pm.project.id,
  #           project_media_id: @pm.id
  #         }
  #       })
  #       .to_return(status: 200)
  #       @bot.create_similarities_from_alegre(@pm)
  #       r = Relationship.where("source_id = :source_id AND target_id = :target_id", {
  #         :source_id => pm1.id,
  #         :target_id => @pm.id
  #       })
  #       assert_equal 1, r.length
  #       WebMock.allow_net_connect!
  #     end
  #   end
  # end

  test "should notify Pusher when language is saved" do
    lang = @bot.send(:save_language, @pm, 'en')
    assert lang.sent_to_pusher
  end
end
