require_relative '../../test_helper'

class Bot::AlegreTest < ActiveSupport::TestCase
  def setup
    super
    ft = DynamicAnnotation::FieldType.where(field_type: 'language').last || create_field_type(field_type: 'language', label: 'Language')
    at = create_annotation_type annotation_type: 'language', label: 'Language'
    create_field_instance annotation_type_object: at, name: 'language', label: 'Language', field_type_object: ft, optional: false
    @bot = create_alegre_bot(name: "alegre", login: "alegre")
    @bot.approve!
    p = create_project
    p.team.set_languages = ['en','pt','es']
    p.team.save!
    @bot.install_to!(p.team)
    @team = p.team
    m = create_claim_media quote: 'I like apples'
    @pm = create_project_media project: p, media: m
    create_flag_annotation_type
    create_extracted_text_annotation_type
    Sidekiq::Testing.inline!
    WebMock.disable_net_connect! allow: /#{CheckConfig.get('elasticsearch_host')}|#{CheckConfig.get('storage_endpoint')}/
  end

  def teardown
    super
  end

  test "should generate media file url" do
    pm1 = create_project_media team: @team, media: create_uploaded_audio
    assert_equal Bot::Alegre.media_file_url(pm1).class, String
  end

  test "should generate item_doc_id" do
    pm1 = create_project_media team: @team, media: create_uploaded_audio
    assert_equal Bot::Alegre.item_doc_id(pm1).class, String
  end

  test "should return proper types per object" do
    p = create_project team: @team
    pm1 = create_project_media project: p, team: @team, media: create_uploaded_audio
    assert_equal Bot::Alegre.get_type(pm1), "audio"
    pm2 = create_project_media project: p, team: @team, media: create_uploaded_video
    assert_equal Bot::Alegre.get_type(pm2), "video"
    pm3 = create_project_media project: p, team: @team, media: create_uploaded_image
    assert_equal Bot::Alegre.get_type(pm3), "image"
    pm4 = create_project_media project: p, quote: "testing short text", team: @team
    assert_equal Bot::Alegre.get_type(pm4), "text"
  end


  test "should have host and paths for audio" do
    pm1 = create_project_media team: @team, media: create_uploaded_audio
    assert_equal Bot::Alegre.host, CheckConfig.get('alegre_host')
    assert_equal Bot::Alegre.sync_path(pm1), "/similarity/sync/audio"
    assert_equal Bot::Alegre.async_path(pm1), "/similarity/async/audio"
    assert_equal Bot::Alegre.delete_path(pm1), "/audio/similarity/"
  end

  test "should have host and paths for image" do
    pm1 = create_project_media team: @team, media: create_uploaded_image
    assert_equal Bot::Alegre.host, CheckConfig.get('alegre_host')
    assert_equal Bot::Alegre.sync_path(pm1), "/similarity/sync/image"
    assert_equal Bot::Alegre.async_path(pm1), "/similarity/async/image"
    assert_equal Bot::Alegre.delete_path(pm1), "/image/similarity/"
  end

  test "should release and reconnect db" do
    RequestStore.store[:pause_database_connection] = true
    assert_equal Bot::Alegre.release_db.class, Thread::ConditionVariable
    assert_equal Bot::Alegre.reconnect_db[0].class, PG::Result
    RequestStore.store[:pause_database_connection] = false
  end

  test "should create a generic_package for audio" do
    pm1 = create_project_media team: @team, media: create_uploaded_audio
    assert_equal Bot::Alegre.generic_package(pm1, "audio"), {:doc_id=>Bot::Alegre.item_doc_id(pm1, "audio"), :context=>{:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true}}
  end

  test "should create a generic_package for image" do
    pm1 = create_project_media team: @team, media: create_uploaded_image
    assert_equal Bot::Alegre.generic_package(pm1, "image"), {:doc_id=>Bot::Alegre.item_doc_id(pm1, "image"), :context=>{:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true}}
  end

  test "should create a generic_package_audio" do
    pm1 = create_project_media team: @team, media: create_uploaded_audio
    assert_equal Bot::Alegre.generic_package_audio(pm1, {}), {:doc_id=>Bot::Alegre.item_doc_id(pm1, nil), :context=>{:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true}, :url=>Bot::Alegre.media_file_url(pm1)}
    assert_equal Bot::Alegre.store_package_audio(pm1, "audio", {}), {:doc_id=>Bot::Alegre.item_doc_id(pm1, nil), :context=>{:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true}, :url=>Bot::Alegre.media_file_url(pm1)}
    assert_equal Bot::Alegre.store_package(pm1, "audio", {}), {:doc_id=>Bot::Alegre.item_doc_id(pm1, nil), :context=>{:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true}, :url=>Bot::Alegre.media_file_url(pm1)}
  end

  test "should create a generic_package_image" do
    pm1 = create_project_media team: @team, media: create_uploaded_image
    assert_equal Bot::Alegre.generic_package_image(pm1, {}), {:doc_id=>Bot::Alegre.item_doc_id(pm1, nil), :context=>{:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true}, :url=>Bot::Alegre.media_file_url(pm1)}
    assert_equal Bot::Alegre.store_package_image(pm1, "image", {}), {:doc_id=>Bot::Alegre.item_doc_id(pm1, nil), :context=>{:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true}, :url=>Bot::Alegre.media_file_url(pm1)}
    assert_equal Bot::Alegre.store_package(pm1, "image", {}), {:doc_id=>Bot::Alegre.item_doc_id(pm1, nil), :context=>{:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true}, :url=>Bot::Alegre.media_file_url(pm1)}
  end

  test "should create a context for audio" do
    pm1 = create_project_media team: @team, media: create_uploaded_audio
    assert_equal Bot::Alegre.get_context(pm1, "audio"), {:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true}
  end

  test "should create a context for image" do
    pm1 = create_project_media team: @team, media: create_uploaded_image
    assert_equal Bot::Alegre.get_context(pm1, "image"), {:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true}
  end

  test "should create a delete_package for audio" do
    pm1 = create_project_media team: @team, media: create_uploaded_audio
    package = Bot::Alegre.delete_package(pm1, "audio")
    assert_equal package[:doc_id], Bot::Alegre.item_doc_id(pm1, nil)
    assert_equal package[:context], {:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true}
    assert_equal package[:url].class, String
    assert_equal package[:quiet], false
  end

  test "should create a delete_package for image" do
    pm1 = create_project_media team: @team, media: create_uploaded_image
    package = Bot::Alegre.delete_package(pm1, "image")
    assert_equal package[:doc_id], Bot::Alegre.item_doc_id(pm1, nil)
    assert_equal package[:context], {:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true}
    assert_equal package[:url].class, String
    assert_equal package[:quiet], false
  end

  test "should run audio async request" do
    pm1 = create_project_media team: @team, media: create_uploaded_audio
    response = {
      "message": "Message pushed successfully",
      "queue": "audio__Model",
      "body": {
        "callback_url": "http:\/\/alegre:3100\/presto\/receive\/add_item\/audio",
        "id": "f0d43d29-853d-4099-9e92-073203afa75b",
        "url": Bot::Alegre.media_file_url(pm1),
        "text": nil,
        "raw": {
          "limit": 200,
          "url": Bot::Alegre.media_file_url(pm1),
          "callback_url": "http:\/\/example.com\/search_results",
          "doc_id": Bot::Alegre.item_doc_id(pm1, "audio"),
          "context": Bot::Alegre.get_context(pm1, "audio"),
          "created_at": "2023-10-27T22:40:14.205586",
          "command": "search",
          "threshold": 0.0,
          "per_model_threshold": {},
          "match_across_content_types": false,
          "requires_callback": true,
          "final_task": "search"
        }
      }
    }
    WebMock.stub_request(:post, "#{CheckConfig.get('alegre_host')}/similarity/async/audio").with(body: {:doc_id=>Bot::Alegre.item_doc_id(pm1), :context=>{:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true}, :url=>Bot::Alegre.media_file_url(pm1)}).to_return(body: response.to_json)
    assert_equal JSON.parse(Bot::Alegre.get_async(pm1).to_json), JSON.parse(response.to_json)
  end

  test "should isolate relevant_context for audio" do
    pm1 = create_project_media team: @team, media: create_uploaded_audio
    assert_equal Bot::Alegre.isolate_relevant_context(pm1, {"context"=>[{"team_id"=>pm1.team_id}]}), {"team_id"=>pm1.team_id}
  end

  test "should isolate relevant_context for image" do
    pm1 = create_project_media team: @team, media: create_uploaded_image
    assert_equal Bot::Alegre.isolate_relevant_context(pm1, {"context"=>[{"team_id"=>pm1.team_id}]}), {"team_id"=>pm1.team_id}
  end

  test "should return field or type on get_target_field for audio" do
    pm1 = create_project_media team: @team, media: create_uploaded_audio
    Bot::Alegre.stubs(:get_type).returns(nil)
    assert_equal Bot::Alegre.get_target_field(pm1, "blah"), "blah"
    Bot::Alegre.unstub(:get_type)
  end

  test "should return field or type on get_target_field for image" do
    pm1 = create_project_media team: @team, media: create_uploaded_image
    Bot::Alegre.stubs(:get_type).returns(nil)
    assert_equal Bot::Alegre.get_target_field(pm1, "blah"), "blah"
    Bot::Alegre.unstub(:get_type)
  end

  test "should generate per model threshold for text" do
    p = create_project team: @team
    pm1 = create_project_media project: p, quote: "testing short text", team: @team
    sample = [{:value=>0.9, :key=>"vector_hash_suggestion_threshold", :automatic=>false, :model=>"vector"}]
    assert_equal Bot::Alegre.get_per_model_threshold(pm1, sample), {:per_model_threshold=>[{:model=>"vector", :value=>0.9}]}
  end

  test "should generate per model threshold for audio" do
    pm1 = create_project_media team: @team, media: create_uploaded_audio
    sample = [{:value=>0.9, :key=>"audio_hash_suggestion_threshold", :automatic=>false, :model=>"hash"}]
    assert_equal Bot::Alegre.get_per_model_threshold(pm1, sample), {:threshold=>0.9}
  end

  test "should generate per model threshold for image" do
    pm1 = create_project_media team: @team, media: create_uploaded_image
    sample = [{:value=>0.9, :key=>"image_hash_suggestion_threshold", :automatic=>false, :model=>"hash"}]
    assert_equal Bot::Alegre.get_per_model_threshold(pm1, sample), {:threshold=>0.9}
  end

  test "should get target field for audio" do
    pm1 = create_project_media team: @team, media: create_uploaded_audio
    assert_equal Bot::Alegre.get_target_field(pm1, nil), "audio"
  end

  test "should get target field for image" do
    pm1 = create_project_media team: @team, media: create_uploaded_image
    assert_equal Bot::Alegre.get_target_field(pm1, nil), "image"
  end

  test "should parse similarity results" do
    pm1 = create_project_media team: @team, media: create_uploaded_audio
    results = [
      {
        "id"=>15346,
        "doc_id"=>"Y2hlY2stcHJvamVjdF9tZWRpYS0yMzE4MC1hdWRpbw",
        "chromaprint_fingerprint"=>[
          -714426431,
          -731146431,
          -731138797,
          -597050061
        ],
        "url"=>"https://qa-assets.checkmedia.org/uploads/uploaded_audio/47237/51845f9bbf47bcfc47e90ab2083f94c1.mp3",
        "context"=>[{"team_id"=>pm1.team_id, "has_custom_id"=>true, "project_media_id"=>pm1.id}],
        "score"=>1.0,
        "model"=>"audio"},
      {
        "id"=>15347,
        "doc_id"=>"Y2hlY2stcHJvamVjdF9tZWRpYS0yMzE4MS1hdWRpbw",
        "chromaprint_fingerprint"=>[
          -546788830,
          -566629838,
          -29630958,
          -29638141
        ],
        "url"=>"https://qa-assets.checkmedia.org/uploads/uploaded_audio/47238/e6cd55fd06742929124cdeaeebfa58d6.mp3",
        "context"=>[{"team_id"=>pm1.team_id, "has_custom_id"=>true, "project_media_id"=>23181}],
        "score"=>0.915364583333333,
        "model"=>"audio"
      }
    ]
    assert_equal Bot::Alegre.parse_similarity_results(pm1, nil, results, Relationship.suggested_type), {23181=>{:score=>0.915364583333333, :context=>{"team_id"=>pm1.team_id, "has_custom_id"=>true, "project_media_id"=>23181}, :model=>"audio", :source_field=>"audio", :target_field=>"audio", :relationship_type=>Relationship.suggested_type}}
  end

  test "should run audio sync request" do
    pm1 = create_project_media team: @team, media: create_uploaded_audio
    response = {
      "result": [
        {
          "id": 1,
          "doc_id": "f0d43d29-853d-4099-9e92-073203afa75b",
          "chromaprint_fingerprint": [
            377259661,
            376226445,
            305001149,
            306181093,
            1379918309,
            1383899364,
            1995219172,
            1974379732,
            1957603396,
            1961789696,
            1416464641,
            1429048627,
            1999429922,
            1999380774,
            2100043878,
            2083467494,
            -59895634,
            -118617698,
            -122811506
          ],
          "url": "http:\/\/devingaffney.com\/files\/audio.ogg",
          "context": [
            {
              "team_id": 1
            }
          ],
          "score": 1.0,
          "model": "audio"
        }
      ]
    }
    WebMock.stub_request(:post, "#{CheckConfig.get('alegre_host')}/similarity/sync/audio").with(body: {:doc_id=>Bot::Alegre.item_doc_id(pm1), :context=>{:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true}, :url=>Bot::Alegre.media_file_url(pm1)}).to_return(body: response.to_json)
    assert_equal JSON.parse(Bot::Alegre.get_sync(pm1).to_json), JSON.parse(response.to_json)
  end

  test "should run delete request" do
    pm1 = create_project_media team: @team, media: create_uploaded_audio
    response = {"requested"=>
      {"limit"=>200,
       "url"=>"https://qa-assets.checkmedia.org/uploads/uploaded_audio/47237/51845f9bbf47bcfc47e90ab2083f94c1.mp3",
       "callback_url"=>nil,
       "doc_id"=>"Y2hlY2stcHJvamVjdF9tZWRpYS0yMzE4MC1hdWRpbw",
       "context"=>{"team_id"=>183, "project_media_id"=>23180, "has_custom_id"=>true},
       "created_at"=>nil,
       "command"=>"delete",
       "threshold"=>0.0,
       "per_model_threshold"=>{},
       "match_across_content_types"=>false,
       "requires_callback"=>false},
     "result"=>{"url"=>"https://qa-assets.checkmedia.org/uploads/uploaded_audio/47237/51845f9bbf47bcfc47e90ab2083f94c1.mp3", "deleted"=>1}
   }
   WebMock.stub_request(:delete, Bot::Alegre.host+Bot::Alegre.delete_path(pm1)).to_return(body: response.to_json)
   assert_equal JSON.parse(Bot::Alegre.delete(pm1).to_json), JSON.parse(response.to_json)
  end

  test "should get_items" do
    pm1 = create_project_media team: @team, media: create_uploaded_audio
    response = {
      "result": [
        {
          "id": 1,
          "doc_id": "f0d43d29-853d-4099-9e92-073203afa75b",
          "chromaprint_fingerprint": [
            377259661,
            376226445,
            305001149,
            306181093,
            1379918309,
            1383899364,
            1995219172,
            1974379732,
            1957603396,
            1961789696,
            1416464641,
            1429048627,
            1999429922,
            1999380774,
            2100043878,
            2083467494,
            -59895634,
            -118617698,
            -122811506
          ],
          "url": "http:\/\/devingaffney.com\/files\/audio.ogg",
          "context": [
            {
              "team_id": pm1.team_id,
              "project_media_id": pm1.id,
              "has_custom_id": true,
            }
          ],
          "score": 1.0,
          "model": "audio"
        },
        {
          "id": 2,
          "doc_id": "f0d43d29-853d-4099-9e92-073203afa75c",
          "chromaprint_fingerprint": [
            377259661,
            376226445,
            305001149,
            306181093,
            1379918309,
            1383899364,
            1995219172,
            1974379732,
            1957603396,
            1961789696,
            1416464641,
            1429048627,
            1999429922,
            1999380774,
            2100043878,
            2083467494,
            -59895634,
            -118617698,
            -122811506
          ],
          "url": "http:\/\/devingaffney.com\/files\/audio.mp3",
          "context": [
            {
              "team_id": pm1.team_id,
              "project_media_id": pm1.id+1,
              "has_custom_id": true,
            }
          ],
          "score": 1.0,
          "model": "audio"
        }
      ]
    }
    WebMock.stub_request(:post, "#{CheckConfig.get('alegre_host')}/similarity/sync/audio").with(body: {:doc_id=>Bot::Alegre.item_doc_id(pm1), :context=>{:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true}, :url=>Bot::Alegre.media_file_url(pm1), :threshold=>0.9}).to_return(body: response.to_json)
    assert_equal Bot::Alegre.get_items(pm1, nil), {(pm1.id+1)=>{:score=>1.0, :context=>{"team_id"=>pm1.team_id, "has_custom_id"=>true, "project_media_id"=>(pm1.id+1)}, :model=>"audio", :source_field=>"audio", :target_field=>"audio", :relationship_type=>Relationship.suggested_type}}
  end

  test "should get_suggested_items" do
    pm1 = create_project_media team: @team, media: create_uploaded_audio
    response = {
      "result": [
        {
          "id": 1,
          "doc_id": "f0d43d29-853d-4099-9e92-073203afa75b",
          "chromaprint_fingerprint": [
            377259661,
            376226445,
            305001149,
            306181093,
            1379918309,
            1383899364,
            1995219172,
            1974379732,
            1957603396,
            1961789696,
            1416464641,
            1429048627,
            1999429922,
            1999380774,
            2100043878,
            2083467494,
            -59895634,
            -118617698,
            -122811506
          ],
          "url": "http:\/\/devingaffney.com\/files\/audio.ogg",
          "context": [
            {
              "team_id": pm1.team_id,
              "project_media_id": pm1.id,
              "has_custom_id": true,
            }
          ],
          "score": 1.0,
          "model": "audio"
        },
        {
          "id": 2,
          "doc_id": "f0d43d29-853d-4099-9e92-073203afa75c",
          "chromaprint_fingerprint": [
            377259661,
            376226445,
            305001149,
            306181093,
            1379918309,
            1383899364,
            1995219172,
            1974379732,
            1957603396,
            1961789696,
            1416464641,
            1429048627,
            1999429922,
            1999380774,
            2100043878,
            2083467494,
            -59895634,
            -118617698,
            -122811506
          ],
          "url": "http:\/\/devingaffney.com\/files\/audio.mp3",
          "context": [
            {
              "team_id": pm1.team_id,
              "project_media_id": pm1.id+1,
              "has_custom_id": true,
            }
          ],
          "score": 0.91,
          "model": "audio"
        }
      ]
    }
    WebMock.stub_request(:post, "#{CheckConfig.get('alegre_host')}/similarity/sync/audio").with(body: {:doc_id=>Bot::Alegre.item_doc_id(pm1), :context=>{:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true}, :url=>Bot::Alegre.media_file_url(pm1), :threshold=>0.9}).to_return(body: response.to_json)
    assert_equal Bot::Alegre.get_items(pm1, nil), {(pm1.id+1)=>{:score=>0.91, :context=>{"team_id"=>pm1.team_id, "has_custom_id"=>true, "project_media_id"=>(pm1.id+1)}, :model=>"audio", :source_field=>"audio", :target_field=>"audio", :relationship_type=>Relationship.suggested_type}}
  end

  test "should get_confirmed_items zzz" do
    pm1 = create_project_media team: @team, media: create_uploaded_audio
    response = {
      "result": [
        {
          "id": 1,
          "doc_id": "f0d43d29-853d-4099-9e92-073203afa75b",
          "chromaprint_fingerprint": [
            377259661,
            376226445,
            305001149,
            306181093,
            1379918309,
            1383899364,
            1995219172,
            1974379732,
            1957603396,
            1961789696,
            1416464641,
            1429048627,
            1999429922,
            1999380774,
            2100043878,
            2083467494,
            -59895634,
            -118617698,
            -122811506
          ],
          "url": "http:\/\/devingaffney.com\/files\/audio.ogg",
          "context": [
            {
              "team_id": pm1.team_id,
              "project_media_id": pm1.id,
              "has_custom_id": true,
            }
          ],
          "score": 1.0,
          "model": "audio"
        },
        {
          "id": 2,
          "doc_id": "f0d43d29-853d-4099-9e92-073203afa75c",
          "chromaprint_fingerprint": [
            377259661,
            376226445,
            305001149,
            306181093,
            1379918309,
            1383899364,
            1995219172,
            1974379732,
            1957603396,
            1961789696,
            1416464641,
            1429048627,
            1999429922,
            1999380774,
            2100043878,
            2083467494,
            -59895634,
            -118617698,
            -122811506
          ],
          "url": "http:\/\/devingaffney.com\/files\/audio.mp3",
          "context": [
            {
              "team_id": pm1.team_id,
              "project_media_id": pm1.id+1,
              "has_custom_id": true,
            }
          ],
          "score": 0.91,
          "model": "audio"
        }
      ]
    }
    WebMock.stub_request(:post, "#{CheckConfig.get('alegre_host')}/similarity/sync/audio").with(body: {:doc_id=>Bot::Alegre.item_doc_id(pm1), :context=>{:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true}, :url=>Bot::Alegre.media_file_url(pm1), :threshold=>0.9}).to_return(body: response.to_json)
    assert_equal Bot::Alegre.get_confirmed_items(pm1, nil), {(pm1.id+1)=>{:score=>0.91, :context=>{"team_id"=>pm1.team_id, "has_custom_id"=>true, "project_media_id"=>(pm1.id+1)}, :model=>"audio", :source_field=>"audio", :target_field=>"audio", :relationship_type=>Relationship.confirmed_type}}
  end

  test "should get_similar_items_v2" do
    pm1 = create_project_media team: @team, media: create_uploaded_audio
    response = {
      "result": [
        {
          "id": 1,
          "doc_id": "f0d43d29-853d-4099-9e92-073203afa75b",
          "chromaprint_fingerprint": [
            377259661,
            376226445,
            305001149,
            306181093,
            1379918309,
            1383899364,
            1995219172,
            1974379732,
            1957603396,
            1961789696,
            1416464641,
            1429048627,
            1999429922,
            1999380774,
            2100043878,
            2083467494,
            -59895634,
            -118617698,
            -122811506
          ],
          "url": "http:\/\/devingaffney.com\/files\/audio.ogg",
          "context": [
            {
              "team_id": pm1.team_id,
              "project_media_id": pm1.id,
              "has_custom_id": true,
            }
          ],
          "score": 1.0,
          "model": "audio"
        },
        {
          "id": 2,
          "doc_id": "f0d43d29-853d-4099-9e92-073203afa75c",
          "chromaprint_fingerprint": [
            377259661,
            376226445,
            305001149,
            306181093,
            1379918309,
            1383899364,
            1995219172,
            1974379732,
            1957603396,
            1961789696,
            1416464641,
            1429048627,
            1999429922,
            1999380774,
            2100043878,
            2083467494,
            -59895634,
            -118617698,
            -122811506
          ],
          "url": "http:\/\/devingaffney.com\/files\/audio.mp3",
          "context": [
            {
              "team_id": pm1.team_id,
              "project_media_id": pm1.id+1,
              "has_custom_id": true,
            }
          ],
          "score": 0.91,
          "model": "audio"
        }
      ]
    }
    WebMock.stub_request(:post, "#{CheckConfig.get('alegre_host')}/similarity/sync/audio").with(body: {:doc_id=>Bot::Alegre.item_doc_id(pm1), :context=>{:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true}, :url=>Bot::Alegre.media_file_url(pm1), :threshold=>0.9}).to_return(body: response.to_json)
    assert_equal Bot::Alegre.get_similar_items_v2(pm1, nil), {}
  end

  test "should relate project media for audio" do
    pm1 = create_project_media team: @team, media: create_uploaded_audio
    pm2 = create_project_media team: @team, media: create_uploaded_audio
    Bot::Alegre.stubs(:get_similar_items_v2).returns({pm2.id=>{:score=>0.91, :context=>{"team_id"=>pm2.team_id, "has_custom_id"=>true, "project_media_id"=>pm2.id}, :model=>"audio", :source_field=>"audio", :target_field=>"audio", :relationship_type=>Relationship.suggested_type}})
    relationship = nil
    assert_difference 'Relationship.count' do
      relationship = Bot::Alegre.relate_project_media(pm1)
    end
    assert_equal relationship.source, pm2
    assert_equal relationship.target, pm1
    assert_equal relationship.relationship_type, Relationship.suggested_type
    Bot::Alegre.unstub(:get_similar_items_v2)
  end

  test "should relate project media for image" do
    pm1 = create_project_media team: @team, media: create_uploaded_image
    pm2 = create_project_media team: @team, media: create_uploaded_image
    Bot::Alegre.stubs(:get_similar_items_v2).returns({pm2.id=>{:score=>0.91, :context=>{"team_id"=>pm2.team_id, "has_custom_id"=>true, "project_media_id"=>pm2.id}, :model=>"audio", :source_field=>"audio", :target_field=>"audio", :relationship_type=>Relationship.suggested_type}})
    relationship = nil
    assert_difference 'Relationship.count' do
      relationship = Bot::Alegre.relate_project_media(pm1)
    end
    assert_equal relationship.source, pm2
    assert_equal relationship.target, pm1
    assert_equal relationship.relationship_type, Relationship.suggested_type
    Bot::Alegre.unstub(:get_similar_items_v2)
  end

  test "should not relate project media for audio if disabled on workspace" do
    tbi = @team.team_bot_installations.select{ |x| x.user_id == @bot.id }
    tbi.set_audio_similarity_enabled = false
    tbi.save!
    Bot::Alegre.stubs(:merge_suggested_and_confirmed).never
    pm = create_project_media team: @team, media: create_uploaded_audio
    assert_equal {}, Bot::Alegre.get_similar_items_v2(pm)
  end

  test "should not relate project media for image if disabled on workspace" do
    tbi = @team.team_bot_installations.select{ |x| x.user_id == @bot.id }
    tbi.set_image_similarity_enabled = false
    tbi.save!
    Bot::Alegre.stubs(:merge_suggested_and_confirmed).never
    pm = create_project_media team: @team, media: create_uploaded_image
    assert_equal {}, Bot::Alegre.get_similar_items_v2(pm)
  end
end