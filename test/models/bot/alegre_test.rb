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
    m = create_claim_media quote: 'I like apples'
    @pm = create_project_media project: p, media: m
  end

  test "should return language" do
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      WebMock.stub_request(:get, 'http://alegre/text/langid').to_return(body: {
        'result': {
          'language': 'en',
          'confidence': 1.0
        }
      }.to_json)
      WebMock.disable_net_connect! allow: [CONFIG['elasticsearch_host']]
      assert_difference 'Annotation.count' do
        assert_equal 'en', Bot::Alegre.get_language(@pm)
      end
    end
  end

  test "should return language und if there is an error" do
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      WebMock.stub_request(:get, 'http://alegre/text/langid').to_return(body: {
        'foo': 'bar'
      }.to_json)
      WebMock.disable_net_connect! allow: [CONFIG['elasticsearch_host']]
      assert_difference 'Annotation.count' do
        assert_equal 'und', Bot::Alegre.get_language(@pm)
      end
    end
  end

  test "should link similar images" do
    ft = create_field_type field_type: 'image_path', label: 'Image Path'
    at = create_annotation_type annotation_type: 'reverse_image', label: 'Reverse Image'
    create_field_instance annotation_type_object: at, name: 'reverse_image_path', label: 'Reverse Image', field_type_object: ft, optional: false
    pm1 = create_project_media project: @pm.project, media: create_uploaded_image
    pm2 = create_project_media project: @pm.project, media: create_uploaded_image

    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      WebMock.disable_net_connect! allow: [CONFIG['elasticsearch_host']]
      WebMock.stub_request(:post, 'http://alegre/image/similarity').to_return(body: {
        "success": true
      }.to_json)
      WebMock.stub_request(:get, 'http://alegre/image/similarity').to_return(body: {
        "result": []
      }.to_json)
      Bot::Alegre.get_image_similarities(pm1)
      WebMock.stub_request(:get, 'http://alegre/image/similarity').to_return(body: {
        "result": [
          {
            "id": 1,
            "sha256": "1782b1d1993fcd9f6fd8155adc6009a9693a8da7bb96d20270c4bc8a30c97570",
            "phash": 17399941807326929,
            "url": "https:\/\/www.gstatic.com\/webp\/gallery3\/1.png",
            "context": {
              "team_id": pm1.team.id.to_s,
              "project_media_id": pm1.id.to_s
            },
            "score": 0
          }
        ]
      }.to_json)
      Bot::Alegre.get_image_similarities(pm2)
    end
    r = Relationship.where("source_id = :source_id AND target_id = :target_id", {
      :source_id => pm1.id,
      :target_id => pm2.id
    })
    assert_equal 1, r.length
  end

  test "should return true when bot is called successfully" do
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      WebMock.stub_request(:get, 'http://alegre/text/langid').to_return(body: {
        'result': {
          'language': 'en',
          'confidence': 1.0
        }
      }.to_json)
      WebMock.disable_net_connect! allow: [CONFIG['elasticsearch_host']]
      assert Bot::Alegre.run({ data: { dbid: @pm.id }, event: 'create_project_media' })
    end
  end

  test "should return false when bot cannot be called" do
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      WebMock.stub_request(:get, 'http://alegre/text/langid').to_return(body: {
        'result': {
          'language': 'en',
          'confidence': 1.0
        }
      }.to_json)
      WebMock.disable_net_connect! allow: [CONFIG['elasticsearch_host']]
      assert !Bot::Alegre.run({ data: { dbid: @pm.id }, event: 'some_other_event' })
      assert !Bot::Alegre.run({ event: 'create_project_media' })
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
    Bot::Alegre.add_relationships(pm1, [pm2.id])
    r = Relationship.last
    assert_equal pm1, r.target
    assert_equal pm3, r.source
  end
end
