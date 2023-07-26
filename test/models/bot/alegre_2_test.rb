require_relative '../../test_helper'

class Bot::Alegre2Test < ActiveSupport::TestCase
  def setup
    super
    ft = DynamicAnnotation::FieldType.where(field_type: 'language').last || create_field_type(field_type: 'language', label: 'Language')
    at = create_annotation_type annotation_type: 'language', label: 'Language'
    create_field_instance annotation_type_object: at, name: 'language', label: 'Language', field_type_object: ft, optional: false
    b = create_alegre_bot(name: "alegre", login: "alegre")
    b.approve!
    @team = t = create_team
    t.set_languages = ['en','pt','es']
    t.save!
    b.install_to!(t)
    create_flag_annotation_type
    create_extracted_text_annotation_type
    Sidekiq::Testing.inline!
    Bot::Alegre.stubs(:should_get_similar_items_of_type?).returns(true)
    Bot::Alegre.unstub(:request_api)
    Bot::Alegre.unstub(:media_file_url)
    @media_path = random_url
    @params = { url: @media_path, context: { has_custom_id: true, team_id: @team.id }, threshold: 0.9, match_across_content_types: true }
  end

  def teardown
    super
    Bot::Alegre.unstub(:should_get_similar_items_of_type?)
  end

  test "should match similar videos" do
    pm1 = create_project_media team: @team, media: create_uploaded_video
    pm2 = create_project_media team: @team, media: create_uploaded_video
    pm3 = create_project_media team: @team, media: create_uploaded_video
    Bot::Alegre.stubs(:request_api).with('get', '/video/similarity/', @params, 'body').returns({
      result: [
        {
          context: [
            { team_id: @team.id.to_s, project_media_id: pm1.id.to_s }
          ],
          score: 0.971234,
          filename: '/app/persistent_disk/blah/12342.tmk'
        },
        {
          context: [
            { team_id: @team.id.to_s, project_media_id: pm2.id.to_s }
          ],
          score: 0.983167,
          filename: '/app/persistent_disk/blah/12343.tmk'
        }
      ]
    }.with_indifferent_access)
    Bot::Alegre.stubs(:media_file_url).with(pm3).returns(@media_path)
    assert_difference 'Relationship.count' do
      Bot::Alegre.relate_project_media_to_similar_items(pm3)
    end
    Bot::Alegre.unstub(:request_api)
    Bot::Alegre.unstub(:media_file_url)
    r = Relationship.last
    assert_equal pm3, r.target
    assert_equal pm2, r.source
    assert_equal r.weight, 0.983167
  end

  test "should match similar audios" do
    pm1 = create_project_media team: @team, media: create_uploaded_audio
    pm2 = create_project_media team: @team, media: create_uploaded_audio
    pm3 = create_project_media team: @team, media: create_uploaded_audio
    Bot::Alegre.stubs(:request_api).with('get', '/audio/similarity/', @params, 'body').returns({
      result: [
        {
          id: 1,
          doc_id: random_string,
          chromaprint_fingerprint: [6581800, 2386744, 2583368, 2488648, 6343163, 14978026, 300191082, 309757210, 304525578, 304386106, 841261098, 841785386],
          url: 'https://foo.com/bar.wav',
          context: [
            { team_id: @team.id.to_s, project_media_id: pm1.id.to_s }
          ],
          score: 0.971234,
        },
        {
          id: 2,
          doc_id: random_string,
          chromaprint_fingerprint: [2386744, 2583368, 2488648, 6343163, 14978026, 300191082, 309757210, 304525578, 304386106, 841261098, 841785386, 858042410, 825593963, 823509230],
          url: 'https://bar.com/foo.wav',
          context: [
            { team_id: @team.id.to_s, project_media_id: pm2.id.to_s }
          ],
          score: 0.983167,
        }
      ]
    }.with_indifferent_access)
    Bot::Alegre.stubs(:media_file_url).with(pm3).returns(@media_path)
    assert_difference 'Relationship.count' do
      Bot::Alegre.relate_project_media_to_similar_items(pm3)
    end
    Bot::Alegre.unstub(:media_file_url)
    r = Relationship.last
    assert_equal pm3, r.target
    assert_equal pm2, r.source
    assert_equal r.weight, 0.983167
  end

  test "should match audio with similar audio from video" do
    p = create_project
    pm1 = create_project_media team: @team, media: create_uploaded_video
    pm2 = create_project_media team: @team, media: create_uploaded_audio
    pm3 = create_project_media team: @team, media: create_uploaded_audio
    Bot::Alegre.stubs(:request_api).with('get', '/audio/similarity/', @params, 'body').returns({
      result: [
        {
          id: 2,
          doc_id: random_string,
          hash_value: '0111',
          url: 'https://foo.com/baz.mp4',
          context: [
            { team_id: @team.id.to_s, project_media_id: pm1.id.to_s }
          ],
          score: 0.971234,
        },
        {
          id: 1,
          doc_id: random_string,
          hash_value: '0101',
          url: 'https://foo.com/bar.mp4',
          context: [
            { team_id: @team.id.to_s, project_media_id: pm2.id.to_s, content_type: 'video' }
          ],
          score: 0.983167,
        }
      ]
    }.with_indifferent_access)
    Bot::Alegre.stubs(:media_file_url).with(pm3).returns(@media_path)
    assert_difference 'Relationship.count' do
      Bot::Alegre.relate_project_media_to_similar_items(pm3)
    end
    Bot::Alegre.unstub(:request_api)
    Bot::Alegre.unstub(:media_file_url)
    r = Relationship.last
    assert_equal pm3, r.target
    assert_equal pm2, r.source
    assert_equal r.weight, 0.983167
  end

  test "should match similar images" do
    pm1 = create_project_media team: @team, media: create_uploaded_image
    pm2 = create_project_media team: @team, media: create_uploaded_image
    pm3 = create_project_media team: @team, media: create_uploaded_image
    result = {
      result: [
        {
          id: 1,
          sha256: random_string(256),
          phash: random_string(72),
          url: 'https://foo.com/bar.png',
          context: [{
            team_id: @team.id.to_s,
            project_media_id: pm1.id.to_s
          }],
          score: 0.5
        },
        {
          id: 2,
          sha256: random_string(256),
          phash: random_string(72),
          url: 'https://bar.com/foo.png',
          context: [{
            team_id: @team.id.to_s,
            project_media_id: pm2.id.to_s
          }],
          score: 0.9
        }
      ]
    }.with_indifferent_access
    Bot::Alegre.stubs(:request_api).with('get', '/image/similarity/', @params.merge({ threshold: 0.89 }), 'body').returns(result)
    Bot::Alegre.stubs(:request_api).with('get', '/image/similarity/', @params.merge({ threshold: 0.95 }), 'body').returns(result)
    Bot::Alegre.stubs(:media_file_url).with(pm3).returns(@media_path)
    assert_difference 'Relationship.count' do
      Bot::Alegre.relate_project_media_to_similar_items(pm3)
    end
    Bot::Alegre.unstub(:request_api)
    Bot::Alegre.unstub(:media_file_url)
    r = Relationship.last
    assert_equal pm3, r.target
    assert_equal pm2, r.source
    assert_equal r.weight, 0.9
  end

  test "should handle similar items from different workspaces" do
    t2 = create_team
    t3 = create_team
    pm1a = create_project_media team: @team, media: create_uploaded_image
    pm2 = create_project_media team: t2, media: create_uploaded_image
    pm3 = create_project_media team: t3, media: create_uploaded_image
    pm4 = create_project_media media: create_uploaded_image
    pm1b = create_project_media team: @team, media: create_uploaded_image
    response = {
      result: [
        {
          id: pm4.id,
          sha256: random_string,
          phash: random_string,
          url: random_url,
          context: [
            {
              team_id: t2.id,
              has_custom_id: true,
              project_media_id: pm2.id
            },
            {
              team_id: @team.id,
              has_custom_id: true,
              project_media_id: pm1b.id
            },
            {
              team_id: t3.id,
              has_custom_id: true,
              project_media_id: pm3.id
            },
          ],
          score: 0
        }
      ]
    }.with_indifferent_access
    Bot::Alegre.stubs(:media_file_url).with(pm1a).returns(@media_path)
    Bot::Alegre.stubs(:request_api).with('get', '/image/similarity/', @params.merge({ threshold: 0.89 }), 'body').returns(response)
    Bot::Alegre.stubs(:request_api).with('get', '/image/similarity/', @params.merge({ threshold: 0.95 }), 'body').returns(response)
    assert_difference 'Relationship.count' do
      Bot::Alegre.relate_project_media_to_similar_items(pm1a)
    end
    Bot::Alegre.unstub(:request_api)
    assert_equal pm1b, Relationship.last.source
    assert_equal pm1a, Relationship.last.target
  end

  test "should link similar images, get flags and extract text" do
    image_path = random_url
    ft = create_field_type field_type: 'image_path', label: 'Image Path'
    at = create_annotation_type annotation_type: 'reverse_image', label: 'Reverse Image'
    create_field_instance annotation_type_object: at, name: 'reverse_image_path', label: 'Reverse Image', field_type_object: ft, optional: false
    Bot::Alegre.unstub(:request_api)
    stub_configs({ 'alegre_host' => 'http://alegre.test', 'alegre_token' => 'test' }) do
      WebMock.stub_request(:post, 'http://alegre.test/text/langid/').to_return(body: { 'result' => { 'language' => 'es' }}.to_json)
      WebMock.disable_net_connect! allow: /#{CheckConfig.get('elasticsearch_host')}|#{CheckConfig.get('storage_endpoint')}/
      WebMock.stub_request(:post, 'http://alegre.test/text/similarity/').to_return(body: 'success')
      WebMock.stub_request(:delete, 'http://alegre.test/text/similarity/').to_return(body: {success: true}.to_json)
      WebMock.stub_request(:get, 'http://alegre.test/text/similarity/').to_return(body: {success: true}.to_json)
      WebMock.stub_request(:post, 'http://alegre.test/image/similarity/').to_return(body: {
        "success": true
      }.to_json)
      WebMock.stub_request(:get, 'http://alegre.test/image/similarity/').to_return(body: {
        "result": []
      }.to_json)
      WebMock.stub_request(:get, 'http://alegre.test/image/classification/').with({ query: { uri: image_path } }).to_return(body: {
        "result": valid_flags_data
      }.to_json)
      WebMock.stub_request(:get, 'http://alegre.test/image/ocr/').with({ query: { url: image_path } }).to_return(body: {
        "text": "Foo bar"
      }.to_json)
      WebMock.stub_request(:post, 'http://alegre.test/image/similarity/').to_return(body: 'success')

      # Similarity
      t = create_team
      pm1 = create_project_media team: t, media: create_uploaded_image
      Bot::Alegre.stubs(:media_file_url).returns(image_path)
      assert Bot::Alegre.run({ data: { dbid: pm1.id }, event: 'create_project_media' })
      Bot::Alegre.unstub(:media_file_url)
      context = [{
        "team_id" => pm1.team.id.to_s,
        "project_media_id" => pm1.id.to_s
      }]
      WebMock.stub_request(:get, 'http://alegre.test/image/similarity/').with(body: /"url":"#{image_path}"/).to_return(body: {
        "result": [
          {
            "id": 1,
            "sha256": "1782b1d1993fcd9f6fd8155adc6009a9693a8da7bb96d20270c4bc8a30c97570",
            "phash": 17399941807326929,
            "url": "https:\/\/www.gstatic.com\/webp\/gallery3\/1.png",
            "context": context,
            "score": 0
          }
        ]
      }.to_json)
      pm2 = create_project_media team: t, media: create_uploaded_image
      response = {pm1.id => {:score => 0, :context => context, :model=>nil, :source_field=>"image", :target_field => "image"}}
      Bot::Alegre.stubs(:media_file_url).returns(image_path)
      assert_equal response, Bot::Alegre.get_items_with_similarity('image', pm2, Bot::Alegre.get_threshold_for_query('image', pm2))

      # Flags
      Bot::Alegre.unstub(:media_file_url)
      WebMock.stub_request(:get, 'http://alegre.test/image/classification/').to_return(body: {
        "result": valid_flags_data
      }.to_json)
      pm3 = create_project_media team: t, media: create_uploaded_image
      Bot::Alegre.stubs(:media_file_url).returns(image_path)
      assert Bot::Alegre.run({ data: { dbid: pm3.id }, event: 'create_project_media' })
      assert_not_nil pm3.get_annotations('flag').last
      Bot::Alegre.unstub(:media_file_url)

      # Text extraction
      Bot::Alegre.unstub(:media_file_url)
      pm4 = create_project_media team: t, media: create_uploaded_image
      Bot::Alegre.stubs(:media_file_url).returns(image_path)
      assert Bot::Alegre.run({ data: { dbid: pm4.id }, event: 'create_project_media' })
      extracted_text_annotation = pm4.get_annotations('extracted_text').last
      assert_equal 'Foo bar', extracted_text_annotation.data['text']
      Bot::Alegre.unstub(:media_file_url)
    end
  end

  test "should pause database connection when calling Alegre" do
    RequestStore.store[:pause_database_connection] = true
    assert_nothing_raised do
      Bot::Alegre.request_api('post', '/text/langid/')
    end
    RequestStore.store[:pause_database_connection] = false
  end

  test "should get items with similar title" do
    create_verification_status_stuff
    RequestStore.store[:skip_cached_field_update] = false
    pm = create_project_media quote: "Blah", team: @team
    pm.analysis = { title: 'Title 1' }
    pm.save!
    pm2 = create_project_media quote: "Blah2", team: @team
    pm2.analysis = { title: 'Title 1' }
    pm2.save!
    Bot::Alegre.stubs(:request_api).returns({"result" => [{
        "_index" => "alegre_similarity",
        "_type" => "_doc",
        "_id" => "tMXj53UB36CYclMPXp14",
        "_score" => 0.9,
        "_source" => {
          "content" => "Bautista began his wrestling career in 1999, and signed with the World Wrestling Federation (WWF, now WWE) in 2000. From 2002 to 2010, he gained fame under the ring name Batista and became a six-time world champion by winning the World Heavyweight Championship four times and the WWE Championship twice. He holds the record for the longest reign as World Heavyweight Champion at 282 days and has also won the World Tag Team Championship three times (twice with Ric Flair and once with John Cena) and the WWE Tag Team Championship once (with Rey Mysterio). He was the winner of the 2005 Royal Rumble match and went on to headline WrestleMania 21, one of the top five highest-grossing pay-per-view events in professional wrestling history",
          "context" => {
            "team_id" => pm2.team.id.to_s,
            "field" => "title",
            "project_media_id" => pm2.id.to_s
          }
        }
      }
      ]
    })
    response = Bot::Alegre.get_items_with_similar_title(pm, Bot::Alegre.get_threshold_for_query('text', pm))
    assert_equal response.class, Hash
    Bot::Alegre.unstub(:request_api)
  end

  test "should respond to a media_file_url request" do
    p = create_project
    m = create_uploaded_image
    pm1 = create_project_media project: p, is_image: true, media: m
    assert_equal Bot::Alegre.media_file_url(pm1).class, String
  end
  
  test "should return singular model for indexing" do
    p = create_project
    tbi = TeamBotInstallation.new
    tbi.set_text_similarity_enabled = false
    tbi.user = BotUser.alegre_user
    tbi.team = p.team
    tbi.settings = {"alegre_model_in_use" => "xlm-r-bert-base-nli-stsb-mean-tokens"}
    tbi.save!
    assert_equal Bot::Alegre.get_tbi_indexing_models(tbi), "xlm-r-bert-base-nli-stsb-mean-tokens"
  end

  test "should return multiple models for indexing" do
    p = create_project
    tbi = TeamBotInstallation.new
    tbi.set_text_similarity_enabled = false
    tbi.user = BotUser.alegre_user
    tbi.team = p.team
    tbi.settings = {"alegre_models_in_use" => ["xlm-r-bert-base-nli-stsb-mean-tokens", "gooby"]}
    tbi.save!
    assert_equal Bot::Alegre.get_tbi_indexing_models(tbi), ["xlm-r-bert-base-nli-stsb-mean-tokens", "gooby"]
  end

  test "should return default model for indexing" do
    p = create_project
    tbi = TeamBotInstallation.new
    tbi.set_text_similarity_enabled = false
    tbi.user = BotUser.alegre_user
    tbi.team = p.team
    tbi.settings = {}
    tbi.save!
    assert_equal Bot::Alegre.get_tbi_indexing_models(tbi), Bot::Alegre.default_model
  end

  test "should return singular model for matching" do
    p = create_project
    tbi = TeamBotInstallation.new
    tbi.set_text_similarity_enabled = false
    tbi.user = BotUser.alegre_user
    tbi.team = p.team
    tbi.settings = {"text_similarity_model" => "xlm-r-bert-base-nli-stsb-mean-tokens"}
    tbi.save!
    assert_equal Bot::Alegre.get_tbi_matching_models(tbi), "xlm-r-bert-base-nli-stsb-mean-tokens"
  end

  test "should return multiple models for matching" do
    p = create_project
    tbi = TeamBotInstallation.new
    tbi.set_text_similarity_enabled = false
    tbi.user = BotUser.alegre_user
    tbi.team = p.team
    tbi.settings = {"text_similarity_models" => ["xlm-r-bert-base-nli-stsb-mean-tokens", "gooby"]}
    tbi.save!
    assert_equal Bot::Alegre.get_tbi_matching_models(tbi), ["xlm-r-bert-base-nli-stsb-mean-tokens", "gooby"]
  end

  test "should return default model for matching" do
    p = create_project
    tbi = TeamBotInstallation.new
    tbi.set_text_similarity_enabled = false
    tbi.user = BotUser.alegre_user
    tbi.team = p.team
    tbi.settings = {}
    tbi.save!
    assert_equal Bot::Alegre.get_tbi_matching_models(tbi), Bot::Alegre.default_model
  end

  test "should return a generic key/val" do
    p = create_project
    tbi = TeamBotInstallation.new
    tbi.set_text_similarity_enabled = false
    tbi.user = BotUser.alegre_user
    tbi.team = p.team
    pm = create_project_media quote: "Blah", team: p.team
    pm.analysis = { title: 'Title 1' }
    pm.save!
    tbi.settings = {"text_vector_matching_threshold" => 0.92}
    tbi.save!
    assert_equal Bot::Alegre.get_matching_key_value(pm, "text", "vector", true, "xlm-r-bert-base-nli-stsb-mean-tokens"), ["text_vector_matching_threshold", 0.92]
  end

  test "should return a specific key/val" do
    p = create_project
    tbi = TeamBotInstallation.new
    tbi.set_text_similarity_enabled = false
    tbi.user = BotUser.alegre_user
    tbi.team = p.team
    pm = create_project_media quote: "Blah", team: p.team
    pm.analysis = { title: 'Title 1' }
    pm.save!
    tbi.settings = {"text_vector_matching_threshold" => 0.92, "text_vector_xlm-r-bert-base-nli-stsb-mean-tokens_matching_threshold" => 0.97}
    tbi.save!
    assert_equal Bot::Alegre.get_matching_key_value(pm, "text", "vector", true, "xlm-r-bert-base-nli-stsb-mean-tokens"), ["text_vector_xlm-r-bert-base-nli-stsb-mean-tokens_matching_threshold", 0.97]
  end

  test "should return a generic key/val for suggestion" do
    p = create_project
    tbi = TeamBotInstallation.new
    tbi.set_text_similarity_enabled = false
    tbi.user = BotUser.alegre_user
    tbi.team = p.team
    pm = create_project_media quote: "Blah", team: p.team
    pm.analysis = { title: 'Title 1' }
    pm.save!
    tbi.settings = {"text_vector_suggestion_threshold" => 0.92}
    tbi.save!
    assert_equal Bot::Alegre.get_matching_key_value(pm, "text", "vector", false, "xlm-r-bert-base-nli-stsb-mean-tokens"), ["text_vector_suggestion_threshold", 0.92]
  end

  test "should return a specific key/val for suggestion" do
    p = create_project
    tbi = TeamBotInstallation.new
    tbi.set_text_similarity_enabled = false
    tbi.user = BotUser.alegre_user
    tbi.team = p.team
    pm = create_project_media quote: "Blah", team: p.team
    pm.analysis = { title: 'Title 1' }
    pm.save!
    tbi.settings = {"text_vector_suggestion_threshold" => 0.92, "text_vector_xlm-r-bert-base-nli-stsb-mean-tokens_suggestion_threshold" => 0.97}
    tbi.save!
    assert_equal Bot::Alegre.get_matching_key_value(pm, "text", "vector", false, "xlm-r-bert-base-nli-stsb-mean-tokens"), ["text_vector_xlm-r-bert-base-nli-stsb-mean-tokens_suggestion_threshold", 0.97]
  end

  test "should return an alegre indexing model" do
    create_verification_status_stuff
    RequestStore.store[:skip_cached_field_update] = false
    pm = create_project_media quote: "Blah", team: p.team
    pm.analysis = { content: 'Description 1' }
    pm.save!
    BotUser.stubs(:alegre_user).returns(User.new)
    TeamBotInstallation.stubs(:find_by_team_id_and_user_id).returns(TeamBotInstallation.new)
    assert_equal Bot::Alegre.indexing_models_to_use(pm), [Bot::Alegre.default_model]
    BotUser.unstub(:alegre_user)
    TeamBotInstallation.unstub(:find_by_team_id_and_user_id)
  end

  test "should not get similar texts for texts with up to 2 words" do
    assert_equal({}, Bot::Alegre.get_items_from_similar_text(random_number, 'Foo bar'))
  end

  test "should match rule by extracted text" do
    t = create_team
    create_tag_text text: 'test', team_id: t.id
    rules = []
    rules << {
      "name": random_string,
      "project_ids": "",
      "rules": {
        "operator": "and",
        "groups": [
          {
            "operator": "and",
            "conditions": [
              {
                "rule_definition": "extracted_text_contains_keyword",
                "rule_value": "Foo"
              }
            ]
          }
        ]
      },
      "actions": [
        {
          "action_definition": "add_tag",
          "action_value": "test"
        }
      ]
    }
    t.rules = rules.to_json
    t.save!
    pm = create_project_media team: t
    create_dynamic_annotation annotation_type: 'extracted_text', annotated: pm, set_fields: { text: 'Foo' }.to_json
    assert_equal ['test'], pm.get_annotations('tag').map(&:load).map(&:tag_text)
  end

  test "should be able to request deletion from index for a text given no fields" do
    create_verification_status_stuff
    RequestStore.store[:skip_cached_field_update] = false
    pm = create_project_media quote: "Blah", team: @team
    pm.analysis = { content: 'Description 1' }
    pm.save!
    Bot::Alegre.stubs(:request_api).returns(true)
    assert Bot::Alegre.delete_from_index(pm)
    Bot::Alegre.unstub(:request_api)
  end

  test "should get items with similar description" do
    create_verification_status_stuff
    RequestStore.store[:skip_cached_field_update] = false
    pm = create_project_media quote: "Blah", team: @team
    pm.analysis = { content: 'Description 1' }
    pm.save!
    pm2 = create_project_media quote: "Blah2", team: @team
    pm2.analysis = { content: 'Description 1' }
    pm2.save!
    Bot::Alegre.stubs(:request_api).returns({
      "result" => [
        {
          "_source" => {
            "id" => 1,
            "sha256" => "1782b1d1993fcd9f6fd8155adc6009a9693a8da7bb96d20270c4bc8a30c97570",
            "phash" => 17399941807326929,
            "url" => "https:\/\/www.gstatic.com\/webp\/gallery3\/1.png",
            "context" => [{
              "team_id" => pm2.team.id.to_s,
              "project_media_id" => pm2.id.to_s
            }],
          },
          "_score" => 0.9
        }
      ]
    })
    response = Bot::Alegre.get_items_with_similar_description(pm, Bot::Alegre.get_threshold_for_query('text', pm))
    assert_equal response.class, Hash
    Bot::Alegre.unstub(:request_api)
  end

  test "should get items with similar title when using non-elasticsearch matching model" do
    create_verification_status_stuff
    RequestStore.store[:skip_cached_field_update] = false
    pm = create_project_media quote: "Blah", team: @team
    pm.analysis = { title: 'This is some more longer title that has enough text to be worth checking Title 1' }
    pm.save!
    pm2 = create_project_media quote: "Blah2", team: @team
    pm2.analysis = { title: 'Title 1' }
    pm2.save!
    Bot::Alegre.stubs(:request_api).returns({"result" => [{
        "_index" => "alegre_similarity",
        "_type" => "_doc",
        "_id" => "tMXj53UB36CYclMPXp14",
        "_score" => 0.9,
        "_source" => {
          "content" => "Bautista began his wrestling career in 1999, and signed with the World Wrestling Federation (WWF, now WWE) in 2000. From 2002 to 2010, he gained fame under the ring name Batista and became a six-time world champion by winning the World Heavyweight Championship four times and the WWE Championship twice. He holds the record for the longest reign as World Heavyweight Champion at 282 days and has also won the World Tag Team Championship three times (twice with Ric Flair and once with John Cena) and the WWE Tag Team Championship once (with Rey Mysterio). He was the winner of the 2005 Royal Rumble match and went on to headline WrestleMania 21, one of the top five highest-grossing pay-per-view events in professional wrestling history",
          "context" => {
            "team_id" => pm2.team.id.to_s,
            "field" => "title",
            "project_media_id" => pm2.id.to_s
          }
        }
      }
      ]
    })
    Bot::Alegre.stubs(:matching_model_to_use).with([pm.team_id]).returns(Bot::Alegre::MEAN_TOKENS_MODEL)
    response = Bot::Alegre.get_items_with_similar_title(pm, [{ key: 'text_elasticsearch_suggestion_threshold', model: 'elasticsearch', value: 0.1, automatic: false }])
    assert_equal response.class, Hash
    Bot::Alegre.unstub(:request_api)
    Bot::Alegre.unstub(:matching_model_to_use)
  end

  test "should get_threshold_hash_from_threshold successfully" do
    assert_equal Bot::Alegre.get_threshold_hash_from_threshold([{value: 0.9}]), {:threshold=>0.9}
    assert_equal Bot::Alegre.get_threshold_hash_from_threshold([{model: "foo", value: 0.9}, {model: "bar", value: 0.7}]), {:per_model_threshold=>{"foo"=>0.9, "bar"=>0.7}}
  end

  test "should get_threshold_for_query successfully" do
    create_verification_status_stuff
    RequestStore.store[:skip_cached_field_update] = false
    pm = create_project_media quote: "Blah", team: @team
    pm.analysis = { title: 'Title 1' }
    pm.save!
    Bot::Alegre.stubs(:matching_model_to_use).with(pm.team_id).returns(Bot::Alegre::MEAN_TOKENS_MODEL)
    assert_equal Bot::Alegre.get_threshold_for_query("text", ProjectMedia.last), [{:value=>0.7, :key=>"text_elasticsearch_suggestion_threshold", :automatic=>false, :model=>"elasticsearch"}, {:value=>0.75, :key=>"text_vector_suggestion_threshold", :automatic=>false, :model=>"xlm-r-bert-base-nli-stsb-mean-tokens"}]
    Bot::Alegre.unstub(:matching_model_to_use)
  end

  test "should match imported report" do
    pm = create_project_media team: @team
    pm2 = create_project_media team: @team, media: Blank.create!, channel: { main: CheckChannels::ChannelCodes::FETCH }
    Bot::Alegre.stubs(:get_items_with_similar_description).returns({ pm2.id => {:score=>0.9, :context=>{"team_id"=>@team.id, "field"=>"original_description", "project_media_id"=>pm2.id, "has_custom_id"=>true}, :model=>"elasticsearch"}})
    assert_equal [pm2.id], Bot::Alegre.get_similar_items(pm).keys
    assert_no_difference 'ProjectMedia.count' do
      assert_difference 'Relationship.count' do
        Bot::Alegre.relate_project_media_to_similar_items(pm)
      end
    end
    Bot::Alegre.unstub(:get_items_with_similar_description)
  end

  test "should set cluster" do
    c1 = create_cluster
    c2 = create_cluster
    pm1 = create_project_media team: @team, cluster_id: c1.id
    pm2 = create_project_media team: @team, cluster_id: c2.id

    ProjectMedia.any_instance.stubs(:similar_items_ids_and_scores).returns({ pm1.id => { score: 0.9 }, pm2.id => { score: 0.8 } })
    pm3 = create_project_media team: @team
    Bot::Alegre.set_cluster(pm3)
    assert_equal c1.id, pm3.reload.cluster_id

    ProjectMedia.any_instance.stubs(:similar_items_ids_and_scores).returns({})
    pm4 = create_project_media team: @team
    assert_difference 'Cluster.count' do
      Bot::Alegre.set_cluster(pm4)
    end

    ProjectMedia.any_instance.unstub(:similar_items_ids_and_scores)
  end

  test "should get number of words" do
    assert_equal 4, Bot::Alegre.get_number_of_words('58 This   is a test !!! 123 😊')
    assert_equal 1, Bot::Alegre.get_number_of_words(random_url)
    # For Chinese characters we'll count the number of characters divied by 2 (rounded up)
    assert_equal 1, Bot::Alegre.get_number_of_words('中国')
    # For Japanese kana, we'll take the number of kana divided by 4 (rounded up)
    assert_equal 2, Bot::Alegre.get_number_of_words('にほんごがすきい')
    # Korean Hangul is generally space separated and should be counted as such
    assert_equal 2, Bot::Alegre.get_number_of_words('한국어가 멋지다')
    # All together - 10 words as below
    # '韓国語で'=>3, 'おいしい'=>1, 'は'=>1, '맛있는'=>1, 'です'=>1, 'Test'=>1, 'string'=>1
    assert_equal 9, Bot::Alegre.get_number_of_words('韓国語で「おいしい」は「맛있는」です。Test string!😊')
    # Test for nil string
    assert_equal 0, Bot::Alegre.get_number_of_words(nil)
  end

  test "should be able to request deletion from index for a media given specific field" do
    create_verification_status_stuff
    RequestStore.store[:skip_cached_field_update] = false
    p = create_project
    pm = create_project_media project: p, media: create_uploaded_video
    pm.media.type = "UploadedVideo"
    pm.media.save!
    pm.save!
    Bot::Alegre.stubs(:request_api).returns(true)
    assert Bot::Alegre.delete_from_index(pm)
    Bot::Alegre.unstub(:request_api)
  end

  test "should pass through the send audio to similarity index call" do
    create_verification_status_stuff
    RequestStore.store[:skip_cached_field_update] = false
    p = create_project
    pm = create_project_media project: p, media: create_uploaded_audio
    pm.media.type = "UploadedAudio"
    pm.media.save!
    pm.save!
    Bot::Alegre.stubs(:request_api).returns(true)
    assert Bot::Alegre.send_to_media_similarity_index(pm)
    Bot::Alegre.unstub(:request_api)
  end

  test "should pass through the send to description similarity index call" do
    create_verification_status_stuff
    RequestStore.store[:skip_cached_field_update] = false
    pm = create_project_media quote: "Blah", team: @team
    pm.analysis = { content: 'Description 1' }
    pm.save!
    Bot::Alegre.stubs(:request_api).returns(true)
    assert Bot::Alegre.send_field_to_similarity_index(pm, 'description')
    Bot::Alegre.unstub(:request_api)
  end

  test "should be able to request deletion from index for a text given specific field" do
    create_verification_status_stuff
    RequestStore.store[:skip_cached_field_update] = false
    pm = create_project_media quote: "Blah", team: @team
    pm.analysis = { content: 'Description 1' }
    pm.save!
    Bot::Alegre.stubs(:request_api).returns(true)
    assert Bot::Alegre.delete_from_index(pm, ['description'])
    Bot::Alegre.unstub(:request_api)
  end

end
