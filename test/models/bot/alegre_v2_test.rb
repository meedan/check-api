require_relative '../../test_helper'

class Bot::AlegreTest < ActiveSupport::TestCase
  def setup
    super
    ft = DynamicAnnotation::FieldType.where(field_type: 'language').last || create_field_type(field_type: 'language', label: 'Language')
    at = create_annotation_type annotation_type: 'language', label: 'Language'
    create_field_instance annotation_type_object: at, name: 'language', label: 'Language', field_type_object: ft, optional: false
    @bot = create_alegre_bot(name: "alegre", login: "alegre")
    @bot.approve!
    team = create_team
    team.set_languages = ['en','pt','es']
    team.save!
    @bot.install_to!(team)
    @team = team
    m = create_claim_media quote: 'I like apples'
    @pm = create_project_media team: team, media: m
    create_flag_annotation_type
    create_extracted_text_annotation_type
    Sidekiq::Testing.inline!
    WebMock.disable_net_connect! allow: /#{CheckConfig.get('elasticsearch_host')}|#{CheckConfig.get('storage_endpoint')}/
  end

  def teardown
    super
  end

  test "should tap-test all TemporaryProjectMedia variations" do
    media_type_map = {
      "claim" => "Claim",
      "link" => "Link",
      "image" => "UploadedImage",
      "video" => "UploadedVideo",
      "audio" => "UploadedAudio",
    }
    media_type_map.each do |k,v|
      tpm = TemporaryProjectMedia.new
      tpm.type = k
      assert_equal tpm.media.type, v
      [:is_blank?, :is_link?, :is_text?, :is_image?, :is_video?, :is_audio?, :is_uploaded_media?].each do |meth|
        assert_equal [true, false].include?(tpm.send(meth)), true
      end
    end
  end

  test "should generate media file url" do
    pm1 = create_project_media team: @team, media: create_uploaded_audio
    assert_equal Bot::Alegre.media_file_url(pm1).class, String
  end

  test "should generate media file url for temporary object" do
    project_media = TemporaryProjectMedia.new
    project_media.url = "http://example.com"
    project_media.id = Digest::MD5.hexdigest(project_media.url).to_i(16)
    project_media.team_id = [1,2,3]
    project_media.type = "audio"
    assert_equal Bot::Alegre.media_file_url(project_media).class, String
  end

  test "should generate item_doc_id" do
    pm1 = create_project_media team: @team, media: create_uploaded_audio
    assert_equal Bot::Alegre.item_doc_id(pm1).class, String
  end

  test "should return proper types per object" do
    pm1 = create_project_media team: @team, media: create_uploaded_audio
    assert_equal Bot::Alegre.get_type(pm1), "audio"
    pm2 = create_project_media team: @team, media: create_uploaded_video
    assert_equal Bot::Alegre.get_type(pm2), "video"
    pm3 = create_project_media team: @team, media: create_uploaded_image
    assert_equal Bot::Alegre.get_type(pm3), "image"
    pm4 = create_project_media quote: "testing short text", team: @team
    assert_equal Bot::Alegre.get_type(pm4), "text"
  end

  test "should have host and paths for text" do
    pm1 = create_project_media team: @team, quote: 'This is a long text that creates a text-based item'
    assert_equal Bot::Alegre.host, CheckConfig.get('alegre_host')
    assert_equal Bot::Alegre.sync_path(pm1), "/similarity/sync/text"
    assert_equal Bot::Alegre.async_path(pm1), "/similarity/async/text"
    assert_equal Bot::Alegre.delete_path(pm1), "/text/similarity/"
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

  test "should have host and paths for video" do
    pm1 = create_project_media team: @team, media: create_uploaded_video
    assert_equal Bot::Alegre.host, CheckConfig.get('alegre_host')
    assert_equal Bot::Alegre.sync_path(pm1), "/similarity/sync/video"
    assert_equal Bot::Alegre.async_path(pm1), "/similarity/async/video"
    assert_equal Bot::Alegre.delete_path(pm1), "/video/similarity/"
  end

  test "should release and reconnect db" do
    RequestStore.store[:pause_database_connection] = true
    assert_equal Bot::Alegre.release_db.class, Thread::ConditionVariable
    assert_equal Bot::Alegre.reconnect_db[0].class, PG::Result
    RequestStore.store[:pause_database_connection] = false
  end

  test "should create a generic_package for text" do
    pm1 = create_project_media team: @team, quote: 'This is a long text that creates a text-based item'
    assert_equal Bot::Alegre.generic_package(pm1, "quote"), {:content_hash=>Bot::Alegre.content_hash(pm1, "quote"), :doc_id=>Bot::Alegre.item_doc_id(pm1, "quote"), :context=>{:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true, :field=>"quote", :temporary_media=>false}}
  end

  test "should create a generic_package for audio" do
    pm1 = create_project_media team: @team, media: create_uploaded_audio
    assert_equal Bot::Alegre.generic_package(pm1, "audio"), {:content_hash=>Bot::Alegre.content_hash(pm1, nil), :doc_id=>Bot::Alegre.item_doc_id(pm1, "audio"), :context=>{:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true, :temporary_media=>false}}
  end

  test "should create a generic_package for image" do
    pm1 = create_project_media team: @team, media: create_uploaded_image
    assert_equal Bot::Alegre.generic_package(pm1, "image"), {:content_hash=>Bot::Alegre.content_hash(pm1, nil), :doc_id=>Bot::Alegre.item_doc_id(pm1, "image"), :context=>{:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true, :temporary_media=>false}}
  end

  test "should create a generic_package for video" do
    pm1 = create_project_media team: @team, media: create_uploaded_video
    assert_equal Bot::Alegre.generic_package(pm1, "video"), {:content_hash=>Bot::Alegre.content_hash(pm1, nil), :doc_id=>Bot::Alegre.item_doc_id(pm1, "video"), :context=>{:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true, :temporary_media=>false}}
  end

  test "should create a generic_package_text" do
    pm1 = create_project_media team: @team, quote: 'This is a long text that creates a text-based item'
    assert_equal Bot::Alegre.generic_package_text(pm1, "quote", {}), {:content_hash=>Bot::Alegre.content_hash(pm1, "quote"), :doc_id=>Bot::Alegre.item_doc_id(pm1, "quote"), :context=>{:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true, :field=>"quote", :temporary_media=>false}, :models=>["elasticsearch"], :text=>pm1.text, :fuzzy=>false, :match_across_content_types=>true, :min_es_score=>10}
    assert_equal Bot::Alegre.store_package_text(pm1, "quote", {}), {:content_hash=>Bot::Alegre.content_hash(pm1, "quote"), :doc_id=>Bot::Alegre.item_doc_id(pm1, "quote"), :context=>{:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true, :field=>"quote", :temporary_media=>false}, :models=>["elasticsearch"], :text=>pm1.text, :fuzzy=>false, :match_across_content_types=>true, :min_es_score=>10}
    assert_equal Bot::Alegre.store_package(pm1, "quote", {}), {:content_hash=>Bot::Alegre.content_hash(pm1, "quote"), :doc_id=>Bot::Alegre.item_doc_id(pm1, "quote"), :context=>{:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true, :field=>"quote", :temporary_media=>false}, :models=>["elasticsearch"], :text=>pm1.text, :fuzzy=>false, :match_across_content_types=>true, :min_es_score=>10}
  end

  test "should create a generic_package_audio" do
    pm1 = create_project_media team: @team, media: create_uploaded_audio
    assert_equal Bot::Alegre.generic_package_audio(pm1, {}), {:content_hash=>Bot::Alegre.content_hash(pm1, nil), :doc_id=>Bot::Alegre.item_doc_id(pm1, nil), :context=>{:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true, :temporary_media=>false}, :url=>Bot::Alegre.media_file_url(pm1)}
    assert_equal Bot::Alegre.store_package_audio(pm1, "audio", {}), {:content_hash=>Bot::Alegre.content_hash(pm1, nil), :doc_id=>Bot::Alegre.item_doc_id(pm1, nil), :context=>{:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true, :temporary_media=>false}, :url=>Bot::Alegre.media_file_url(pm1)}
    assert_equal Bot::Alegre.store_package(pm1, "audio", {}), {:content_hash=>Bot::Alegre.content_hash(pm1, nil), :doc_id=>Bot::Alegre.item_doc_id(pm1, nil), :context=>{:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true, :temporary_media=>false}, :url=>Bot::Alegre.media_file_url(pm1)}
  end

  test "should create a generic_package_image" do
    pm1 = create_project_media team: @team, media: create_uploaded_image
    assert_equal Bot::Alegre.generic_package_image(pm1, {}), {:content_hash=>Bot::Alegre.content_hash(pm1, nil), :doc_id=>Bot::Alegre.item_doc_id(pm1, nil), :context=>{:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true, :temporary_media=>false}, :url=>Bot::Alegre.media_file_url(pm1)}
    assert_equal Bot::Alegre.store_package_image(pm1, "image", {}), {:content_hash=>Bot::Alegre.content_hash(pm1, nil), :doc_id=>Bot::Alegre.item_doc_id(pm1, nil), :context=>{:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true, :temporary_media=>false}, :url=>Bot::Alegre.media_file_url(pm1)}
    assert_equal Bot::Alegre.store_package(pm1, "image", {}), {:content_hash=>Bot::Alegre.content_hash(pm1, nil), :doc_id=>Bot::Alegre.item_doc_id(pm1, nil), :context=>{:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true, :temporary_media=>false}, :url=>Bot::Alegre.media_file_url(pm1)}
  end

  test "should create a generic_package_video" do
    pm1 = create_project_media team: @team, media: create_uploaded_video
    assert_equal Bot::Alegre.generic_package_image(pm1, {}), {:content_hash=>Bot::Alegre.content_hash(pm1, nil), :doc_id=>Bot::Alegre.item_doc_id(pm1, nil), :context=>{:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true, :temporary_media=>false}, :url=>Bot::Alegre.media_file_url(pm1)}
    assert_equal Bot::Alegre.store_package_image(pm1, "video", {}), {:content_hash=>Bot::Alegre.content_hash(pm1, nil), :doc_id=>Bot::Alegre.item_doc_id(pm1, nil), :context=>{:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true, :temporary_media=>false}, :url=>Bot::Alegre.media_file_url(pm1)}
    assert_equal Bot::Alegre.store_package(pm1, "video", {}), {:content_hash=>Bot::Alegre.content_hash(pm1, nil), :doc_id=>Bot::Alegre.item_doc_id(pm1, nil), :context=>{:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true, :temporary_media=>false}, :url=>Bot::Alegre.media_file_url(pm1)}
  end

  test "should create a context for text" do
    pm1 = create_project_media team: @team, quote: 'This is a long text that creates a text-based item'
    assert_equal Bot::Alegre.get_context(pm1, "quote"), {:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true, :field=>"quote", :temporary_media=>false}
  end

  test "should create a context for audio" do
    pm1 = create_project_media team: @team, media: create_uploaded_audio
    assert_equal Bot::Alegre.get_context(pm1, "audio"), {:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true, :temporary_media=>false}
  end

  test "should create a context for image" do
    pm1 = create_project_media team: @team, media: create_uploaded_image
    assert_equal Bot::Alegre.get_context(pm1, "image"), {:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true, :temporary_media=>false}
  end

  test "should create a context for video" do
    pm1 = create_project_media team: @team, media: create_uploaded_video
    assert_equal Bot::Alegre.get_context(pm1, "video"), {:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true, :temporary_media=>false}
  end

  test "should create a delete_package for text" do
    pm1 = create_project_media team: @team, quote: 'This is a long text that creates a text-based item'
    package = Bot::Alegre.delete_package(pm1, "quote")
    assert_equal package[:doc_id], Bot::Alegre.item_doc_id(pm1, "quote")
    assert_equal package[:context], {:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true, :field=>"quote", :temporary_media=>false}
    assert_equal package[:text].class, String
    assert_equal package[:quiet], false
  end

  test "should create a delete_package for audio" do
    pm1 = create_project_media team: @team, media: create_uploaded_audio
    package = Bot::Alegre.delete_package(pm1, "audio")
    assert_equal package[:doc_id], Bot::Alegre.item_doc_id(pm1, nil)
    assert_equal package[:context], {:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true, :temporary_media=>false}
    assert_equal package[:url].class, String
    assert_equal package[:quiet], false
  end

  test "should create a delete_package for image" do
    pm1 = create_project_media team: @team, media: create_uploaded_image
    package = Bot::Alegre.delete_package(pm1, "image")
    assert_equal package[:doc_id], Bot::Alegre.item_doc_id(pm1, nil)
    assert_equal package[:context], {:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true, :temporary_media=>false}
    assert_equal package[:url].class, String
    assert_equal package[:quiet], false
  end

  test "should create a delete_package for video" do
    pm1 = create_project_media team: @team, media: create_uploaded_video
    package = Bot::Alegre.delete_package(pm1, "video")
    assert_equal package[:doc_id], Bot::Alegre.item_doc_id(pm1, nil)
    assert_equal package[:context], {:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true, :temporary_media=>false}
    assert_equal package[:url].class, String
    assert_equal package[:quiet], false
  end

  test "should run text async request" do
    pm1 = create_project_media team: @team, quote: 'This is a long text that creates a text-based item'
    response = {
      "message": "Message pushed successfully",
      "queue": "text__Model",
      "body": {
        "callback_url": "http:\/\/alegre:3100\/presto\/receive\/add_item\/text",
        "id": "f0d43d29-853d-4099-9e92-073203afa75b",
        "url": nil,
        "text": 'This is a long text that creates a text-based item',
        "raw": {
          "limit": 200,
          "url": nil,
          "text": 'This is a long text that creates a text-based item',
          "callback_url": "http:\/\/example.com\/search_results",
          "doc_id": Bot::Alegre.item_doc_id(pm1, "quote"),
          "context": Bot::Alegre.get_context(pm1, "quote"),
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
    WebMock.stub_request(:post, "#{CheckConfig.get('alegre_host')}/similarity/async/text").with(body: {:content_hash=>Bot::Alegre.content_hash(pm1, "quote"), :doc_id=>Bot::Alegre.item_doc_id(pm1, "quote"), :context=>{:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true, :field=>"quote", :temporary_media=>false}, :models=>["elasticsearch"], :text=>pm1.quote, :fuzzy=>false, :match_across_content_types=>true, :min_es_score=>10}).to_return(body: response.to_json)
    assert_equal JSON.parse(Bot::Alegre.get_async(pm1, "quote").to_json), JSON.parse(response.to_json)
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
    WebMock.stub_request(:post, "#{CheckConfig.get('alegre_host')}/similarity/async/audio").with(body: {:content_hash=>Bot::Alegre.content_hash(pm1, nil), :doc_id=>Bot::Alegre.item_doc_id(pm1), :context=>{:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true, :temporary_media=>false}, :url=>Bot::Alegre.media_file_url(pm1)}).to_return(body: response.to_json)
    assert_equal JSON.parse(Bot::Alegre.get_async(pm1).to_json), JSON.parse(response.to_json)
  end

  test "should isolate relevant_context for text" do
    pm1 = create_project_media team: @team, quote: 'This is a long text that creates a text-based item'
    assert_equal Bot::Alegre.isolate_relevant_context(pm1, {"context"=>[{"team_id"=>pm1.team_id}]}), {"team_id"=>pm1.team_id}
  end

  test "should isolate relevant_context for audio" do
    pm1 = create_project_media team: @team, media: create_uploaded_audio
    assert_equal Bot::Alegre.isolate_relevant_context(pm1, {"context"=>[{"team_id"=>pm1.team_id}]}), {"team_id"=>pm1.team_id}
  end

  test "should isolate relevant_context for image" do
    pm1 = create_project_media team: @team, media: create_uploaded_image
    assert_equal Bot::Alegre.isolate_relevant_context(pm1, {"context"=>[{"team_id"=>pm1.team_id}]}), {"team_id"=>pm1.team_id}
  end

  test "should isolate relevant_context for video" do
    pm1 = create_project_media team: @team, media: create_uploaded_video
    assert_equal Bot::Alegre.isolate_relevant_context(pm1, {"context"=>[{"team_id"=>pm1.team_id}]}), {"team_id"=>pm1.team_id}
  end

  test "should return field or type on get_target_field for text" do
    pm1 = create_project_media team: @team, quote: 'This is a long text that creates a text-based item'
    Bot::Alegre.stubs(:get_type).returns(nil)
    assert_equal Bot::Alegre.get_target_field(pm1, "quote"), "quote"
    Bot::Alegre.unstub(:get_type)
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

  test "should return field or type on get_target_field for video" do
    pm1 = create_project_media team: @team, media: create_uploaded_video
    Bot::Alegre.stubs(:get_type).returns(nil)
    assert_equal Bot::Alegre.get_target_field(pm1, "blah"), "blah"
    Bot::Alegre.unstub(:get_type)
  end

  test "should generate per model threshold for text" do
    pm1 = create_project_media quote: "testing short text", team: @team
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

  test "should generate per model threshold for video" do
    pm1 = create_project_media team: @team, media: create_uploaded_video
    sample = [{:value=>0.9, :key=>"video_hash_suggestion_threshold", :automatic=>false, :model=>"hash"}]
    assert_equal Bot::Alegre.get_per_model_threshold(pm1, sample), {:threshold=>0.9}
  end

  test "should get target field for text" do
    pm1 = create_project_media team: @team, quote: 'This is a long text that creates a text-based item'
    assert_equal Bot::Alegre.get_target_field(pm1, "quote"), "quote"
  end

  test "should get target field for audio" do
    pm1 = create_project_media team: @team, media: create_uploaded_audio
    assert_equal Bot::Alegre.get_target_field(pm1, nil), "audio"
  end

  test "should get target field for image" do
    pm1 = create_project_media team: @team, media: create_uploaded_image
    assert_equal Bot::Alegre.get_target_field(pm1, nil), "image"
  end

  test "should get target field for video" do
    pm1 = create_project_media team: @team, media: create_uploaded_video
    assert_equal Bot::Alegre.get_target_field(pm1, nil), "video"
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
    WebMock.stub_request(:post, "#{CheckConfig.get('alegre_host')}/similarity/sync/audio").with(body: {:content_hash=>Bot::Alegre.content_hash(pm1, nil), :doc_id=>Bot::Alegre.item_doc_id(pm1), :context=>{:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true, :temporary_media=>false}, :url=>Bot::Alegre.media_file_url(pm1)}).to_return(body: response.to_json)
    assert_equal JSON.parse(Bot::Alegre.get_sync(pm1).to_json), JSON.parse(response.to_json)
  end

  test "should safe_get_sync" do
    pm1 = create_project_media team: @team, media: create_uploaded_audio
    WebMock.stub_request(:post, "#{CheckConfig.get('alegre_host')}/similarity/sync/audio").to_return(body: '{}')
    expected = {}
    actual = Bot::Alegre.safe_get_sync(pm1, "audio", {})
    assert_equal expected, actual
  end

  test "should safe_get_async" do
    pm1 = create_project_media team: @team, media: create_uploaded_audio
    WebMock.stub_request(:post, "#{CheckConfig.get('alegre_host')}/similarity/async/audio").to_return(body: 'null')
    expected = nil
    actual = Bot::Alegre.safe_get_async(pm1, "audio", {})
    assert_equal expected, actual
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

  test "should return false and log error during delete request" do
    pm1 = create_project_media team: @team, media: create_uploaded_audio
    Bot::Alegre.stubs(:request_delete).raises(StandardError)
    Rails.logger.expects(:error).with("[Alegre Bot] Exception on Delete for ProjectMedia ##{pm1.id}: Bot::Alegre::Error - StandardError").returns(nil)
    CheckSentry.expects(:notify).with(instance_of(Bot::Alegre::Error), bot: "alegre", project_media: pm1, params: {}, field: nil).returns(false)
    result = Bot::Alegre.delete(pm1)
    assert_equal false, result
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
    WebMock.stub_request(:post, "#{CheckConfig.get('alegre_host')}/similarity/sync/audio").with(body: {:content_hash=>Bot::Alegre.content_hash(pm1, nil), :doc_id=>Bot::Alegre.item_doc_id(pm1), :context=>{:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true, :temporary_media=>false}, :url=>Bot::Alegre.media_file_url(pm1), :threshold=>0.9}).to_return(body: response.to_json)
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
              "temporary_media": false,
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
              "temporary_media": false,
            }
          ],
          "score": 0.91,
          "model": "audio"
        }
      ]
    }
    WebMock.stub_request(:post, "#{CheckConfig.get('alegre_host')}/similarity/sync/audio").with(body: {:content_hash=>Bot::Alegre.content_hash(pm1, nil), :doc_id=>Bot::Alegre.item_doc_id(pm1), :context=>{:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true, :temporary_media=>false}, :url=>Bot::Alegre.media_file_url(pm1), :threshold=>0.9}).to_return(body: response.to_json)
    assert_equal Bot::Alegre.get_items(pm1, nil), {(pm1.id+1)=>{:score=>0.91, :context=>{"team_id"=>pm1.team_id, "has_custom_id"=>true, "project_media_id"=>(pm1.id+1), "temporary_media"=>false}, :model=>"audio", :source_field=>"audio", :target_field=>"audio", :relationship_type=>Relationship.suggested_type}}
  end

  test "should get_confirmed_items" do
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
              "temporary_media": false,
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
              "temporary_media": false,
            }
          ],
          "score": 0.91,
          "model": "audio"
        }
      ]
    }
    WebMock.stub_request(:post, "#{CheckConfig.get('alegre_host')}/similarity/sync/audio").with(body: {:content_hash=>Bot::Alegre.content_hash(pm1, nil), :doc_id=>Bot::Alegre.item_doc_id(pm1), :context=>{:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true, :temporary_media=>false}, :url=>Bot::Alegre.media_file_url(pm1), :threshold=>0.9}).to_return(body: response.to_json)
    assert_equal Bot::Alegre.get_confirmed_items(pm1, nil), {(pm1.id+1)=>{:score=>0.91, :context=>{"team_id"=>pm1.team_id, "has_custom_id"=>true, "project_media_id"=>(pm1.id+1), "temporary_media"=>false}, :model=>"audio", :source_field=>"audio", :target_field=>"audio", :relationship_type=>Relationship.confirmed_type}}
  end

  test "should get_similar_items_v2_async with false" do
    pm1 = create_project_media team: @team, media: create_uploaded_audio
    Bot::Alegre.stubs(:should_get_similar_items_of_type?).returns(false)
    assert_equal Bot::Alegre.get_similar_items_v2_async(pm1, nil), false
  end

  test "should get_similar_items_v2_callback with false" do
    pm1 = create_project_media team: @team, media: create_uploaded_audio
    Bot::Alegre.stubs(:should_get_similar_items_of_type?).returns(false)
    assert_equal Bot::Alegre.get_similar_items_v2_callback(pm1, nil), {}
  end

  test "should get_similar_items_v2_async" do
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
    WebMock.stub_request(:post, "#{CheckConfig.get('alegre_host')}/similarity/async/audio").with(body: {:content_hash=>Bot::Alegre.content_hash(pm1, nil), :doc_id => Bot::Alegre.item_doc_id(pm1),:context => {:team_id => pm1.team_id, :project_media_id => pm1.id, :has_custom_id => true, :temporary_media => false}, :url => Bot::Alegre.media_file_url(pm1), :threshold => 0.9, :confirmed => false}).to_return(body: response.to_json)
    WebMock.stub_request(:post, "#{CheckConfig.get('alegre_host')}/similarity/async/audio").with(body: {:content_hash=>Bot::Alegre.content_hash(pm1, nil), :doc_id => Bot::Alegre.item_doc_id(pm1),:context => {:team_id => pm1.team_id, :project_media_id => pm1.id, :has_custom_id => true, :temporary_media => false}, :url => Bot::Alegre.media_file_url(pm1), :threshold => 0.9, :confirmed => true}).to_return(body: response.to_json)
    assert_equal Bot::Alegre.get_similar_items_v2_async(pm1, nil), true
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
              "temporary_media": false,
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
              "temporary_media": false,
            }
          ],
          "score": 0.91,
          "model": "audio"
        }
      ]
    }
    WebMock.stub_request(:post, "#{CheckConfig.get('alegre_host')}/similarity/sync/audio").with(body: {:content_hash=>Bot::Alegre.content_hash(pm1, nil), :doc_id=>Bot::Alegre.item_doc_id(pm1), :context=>{:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true, :temporary_media=>false}, :url=>Bot::Alegre.media_file_url(pm1), :threshold=>0.9}).to_return(body: response.to_json)
    assert_equal Bot::Alegre.get_similar_items_v2(pm1, nil), {}
  end

  test "should relate project media async for audio" do
    pm1 = create_project_media team: @team, media: create_uploaded_audio
    pm2 = create_project_media team: @team, media: create_uploaded_audio
    WebMock.stub_request(:post, "#{CheckConfig.get('alegre_host')}/similarity/async/audio").to_return(body: '{}')
    relationship = nil
    params = {
        "model_type": "image",
        "data": {
            "item": {
                "id": "Y2hlY2stcHJvamVjdF9tZWRpYS0yMTQt",
                "callback_url": "http://alegre:3100/presto/receive/add_item/image",
                "url": "http://minio:9000/check-api-dev/uploads/uploaded_image/55/09572dedf610aad68090214303c14829.png",
                "text": nil,
                "raw": {
                    "doc_id": "Y2hlY2stcHJvamVjdF9tZWRpYS0yMTQt",
                    "context": {
                        "team_id": pm1.team_id,
                        "project_media_id": pm1.id,
                        "has_custom_id": true,
                        "temporary_media": false,
                    },
                    "url": "http://minio:9000/check-api-dev/uploads/uploaded_image/55/09572dedf610aad68090214303c14829.png",
                    "threshold": 0.73,
                    "confirmed": true,
                    "created_at": "2024-03-14T22:05:47.588975",
                    "limit": 200,
                    "requires_callback": true,
                    "final_task": "search"
                },
                "hash_value": "1110101010001011110100000011110010101000000010110101101010100101101111110101101001011010100001011111110101011010010000101010010110101101010110100000001010100101101010111110101000010101011100001110101010101111100001010101001011101010101011010001010101010010"
            },
            "results": {
                "result": [
                    {
                        "id": "Y2hlY2stcHJvamVjdF9tZWRpYS0yMTQt",
                        "doc_id": "Y2hlY2stcHJvamVjdF9tZWRpYS0yMTQt",
                        "pdq": "1110101010001011110100000011110010101000000010110101101010100101101111110101101001011010100001011111110101011010010000101010010110101101010110100000001010100101101010111110101000010101011100001110101010101111100001010101001011101010101011010001010101010010",
                        "url": "http://minio:9000/check-api-dev/uploads/uploaded_image/55/09572dedf610aad68090214303c14829.png",
                        "context": [
                            {
                                "team_id": pm2.team_id,
                                "has_custom_id": true,
                                "project_media_id": pm2.id,
                                "temporary_media": false,
                            }
                        ],
                        "score": 1.0,
                        "model": "image/pdq"
                    }
                ]
            }
        }
    }
    unconfirmed_params = {
        "model_type": "image",
        "data": {
            "item": {
                "id": "Y2hlY2stcHJvamVjdF9tZWRpYS0yMTQt",
                "callback_url": "http://alegre:3100/presto/receive/add_item/image",
                "url": "http://minio:9000/check-api-dev/uploads/uploaded_image/55/09572dedf610aad68090214303c14829.png",
                "text": nil,
                "raw": {
                    "doc_id": "Y2hlY2stcHJvamVjdF9tZWRpYS0yMTQt",
                    "context": {
                        "team_id": pm1.team_id,
                        "project_media_id": pm1.id,
                        "has_custom_id": true,
                        "temporary_media": false,
                    },
                    "url": "http://minio:9000/check-api-dev/uploads/uploaded_image/55/09572dedf610aad68090214303c14829.png",
                    "threshold": 0.63,
                    "confirmed": false,
                    "created_at": "2024-03-14T22:05:47.588975",
                    "limit": 200,
                    "requires_callback": true,
                    "final_task": "search"
                },
                "hash_value": "1110101010001011110100000011110010101000000010110101101010100101101111110101101001011010100001011111110101011010010000101010010110101101010110100000001010100101101010111110101000010101011100001110101010101111100001010101001011101010101011010001010101010010"
            },
            "results": {
                "result": [
                    {
                        "id": "Y2hlY2stcHJvamVjdF9tZWRpYS0yMTQt",
                        "doc_id": "Y2hlY2stcHJvamVjdF9tZWRpYS0yMTQt",
                        "pdq": "1110101010001011110100000011110010101000000010110101101010100101101111110101101001011010100001011111110101011010010000101010010110101101010110100000001010100101101010111110101000010101011100001110101010101111100001010101001011101010101011010001010101010010",
                        "url": "http://minio:9000/check-api-dev/uploads/uploaded_image/55/09572dedf610aad68090214303c14829.png",
                        "context": [
                            {
                                "team_id": pm2.team_id,
                                "has_custom_id": true,
                                "project_media_id": pm2.id,
                                "temporary_media": false,
                            }
                        ],
                        "score": 1.0,
                        "model": "image/pdq"
                    }
                ]
            }
        }
    }
    assert_difference 'Relationship.count' do
      # Simulate the webhook hitting the server and being executed....
      Bot::Alegre.process_alegre_callback(JSON.parse(unconfirmed_params.to_json))
      relationship = Bot::Alegre.process_alegre_callback(JSON.parse(params.to_json)) #hack to force into stringed keys
    end
    assert_equal relationship.source, pm2
    assert_equal relationship.target, pm1
    assert_equal relationship.relationship_type, Relationship.confirmed_type
  end

  test "should relate project media async for audio when getting a canned response" do
    pm1 = create_project_media team: @team, media: create_uploaded_audio
    pm2 = create_project_media team: @team, media: create_uploaded_audio
    WebMock.stub_request(:post, "#{CheckConfig.get('alegre_host')}/similarity/async/audio").to_return(body: '{}')
    relationship = nil
    params = {
        "model_type": "image",
        "data": {
            "is_shortcircuited_search_result_callback": true,
            "item": {
                "callback_url": "http://alegre:3100/presto/receive/add_item/image",
                "url": "http://minio:9000/check-api-dev/uploads/uploaded_image/55/09572dedf610aad68090214303c14829.png",
                "text": nil,
                "raw": {
                    "doc_id": "Y2hlY2stcHJvamVjdF9tZWRpYS0yMTQt",
                    "context": {
                        "team_id": pm1.team_id,
                        "project_media_id": pm1.id,
                        "has_custom_id": true,
                        "temporary_media": false,
                    },
                    "url": "http://minio:9000/check-api-dev/uploads/uploaded_image/55/09572dedf610aad68090214303c14829.png",
                    "threshold": 0.85,
                    "confirmed": true,
                    "created_at": "2024-03-14T22:05:47.588975",
                    "limit": 200,
                    "requires_callback": true,
                    "final_task": "search"
                },
                "hash_value": "1110101010001011110100000011110010101000000010110101101010100101101111110101101001011010100001011111110101011010010000101010010110101101010110100000001010100101101010111110101000010101011100001110101010101111100001010101001011101010101011010001010101010010"
            },
            "results": {
                "result": [
                    {
                        "id": "Y2hlY2stcHJvamVjdF9tZWRpYS0yMTQt",
                        "doc_id": "Y2hlY2stcHJvamVjdF9tZWRpYS0yMTQt",
                        "pdq": "1110101010001011110100000011110010101000000010110101101010100101101111110101101001011010100001011111110101011010010000101010010110101101010110100000001010100101101010111110101000010101011100001110101010101111100001010101001011101010101011010001010101010010",
                        "url": "http://minio:9000/check-api-dev/uploads/uploaded_image/55/09572dedf610aad68090214303c14829.png",
                        "context": [
                            {
                                "team_id": pm2.team_id,
                                "has_custom_id": true,
                                "project_media_id": pm2.id,
                                "temporary_media": false,
                            }
                        ],
                        "score": 1.0,
                        "model": "image/pdq"
                    }
                ]
            }
        }
    }
    unconfirmed_params = {
        "model_type": "image",
        "data": {
            "is_shortcircuited_search_result_callback": true,
            "item": {
                "callback_url": "http://alegre:3100/presto/receive/add_item/image",
                "url": "http://minio:9000/check-api-dev/uploads/uploaded_image/55/09572dedf610aad68090214303c14829.png",
                "text": nil,
                "raw": {
                    "doc_id": "Y2hlY2stcHJvamVjdF9tZWRpYS0yMTQt",
                    "context": {
                        "team_id": pm1.team_id,
                        "project_media_id": pm1.id,
                        "has_custom_id": true,
                        "temporary_media": false,
                    },
                    "url": "http://minio:9000/check-api-dev/uploads/uploaded_image/55/09572dedf610aad68090214303c14829.png",
                    "threshold": 0.73,
                    "confirmed": false,
                    "created_at": "2024-03-14T22:05:47.588975",
                    "limit": 200,
                    "requires_callback": true,
                    "final_task": "search"
                },
                "hash_value": "1110101010001011110100000011110010101000000010110101101010100101101111110101101001011010100001011111110101011010010000101010010110101101010110100000001010100101101010111110101000010101011100001110101010101111100001010101001011101010101011010001010101010010"
            },
            "results": {
                "result": [
                    {
                        "id": "Y2hlY2stcHJvamVjdF9tZWRpYS0yMTQt",
                        "doc_id": "Y2hlY2stcHJvamVjdF9tZWRpYS0yMTQt",
                        "pdq": "1110101010001011110100000011110010101000000010110101101010100101101111110101101001011010100001011111110101011010010000101010010110101101010110100000001010100101101010111110101000010101011100001110101010101111100001010101001011101010101011010001010101010010",
                        "url": "http://minio:9000/check-api-dev/uploads/uploaded_image/55/09572dedf610aad68090214303c14829.png",
                        "context": [
                            {
                                "team_id": pm2.team_id,
                                "has_custom_id": true,
                                "project_media_id": pm2.id,
                                "temporary_media": false,
                            }
                        ],
                        "score": 1.0,
                        "model": "image/pdq"
                    }
                ]
            }
        }
    }
    assert_difference 'Relationship.count' do
      # Simulate the webhook hitting the server and being executed....
      Bot::Alegre.process_alegre_callback(JSON.parse(unconfirmed_params.to_json)) #hack to force into stringed keys
      relationship = Bot::Alegre.process_alegre_callback(JSON.parse(params.to_json)) #hack to force into stringed keys
    end
    assert_equal relationship.source, pm2
    assert_equal relationship.target, pm1
    assert_equal relationship.relationship_type, Relationship.confirmed_type
  end

  test "should not relate project media async for audio when temporary" do
    pm1 = create_project_media team: @team, media: create_uploaded_audio
    pm2 = create_project_media team: @team, media: create_uploaded_audio
    WebMock.stub_request(:post, "#{CheckConfig.get('alegre_host')}/similarity/async/audio").to_return(body: '{}')
    relationship = nil
    params = {
        "model_type": "image",
        "data": {
            "item": {
                "id": "Y2hlY2stcHJvamVjdF9tZWRpYS0yMTQt",
                "callback_url": "http://alegre:3100/presto/receive/add_item/image",
                "url": "http://minio:9000/check-api-dev/uploads/uploaded_image/55/09572dedf610aad68090214303c14829.png",
                "text": nil,
                "raw": {
                    "doc_id": "Y2hlY2stcHJvamVjdF9tZWRpYS0yMTQt",
                    "context": {
                        "team_id": pm1.team_id,
                        "project_media_id": 123456789,
                        "has_custom_id": true,
                        "temporary_media": true,
                    },
                    "url": "http://minio:9000/check-api-dev/uploads/uploaded_image/55/09572dedf610aad68090214303c14829.png",
                    "threshold": 0.73,
                    "confirmed": true,
                    "created_at": "2024-03-14T22:05:47.588975",
                    "limit": 200,
                    "requires_callback": true,
                    "final_task": "search"
                },
                "hash_value": "1110101010001011110100000011110010101000000010110101101010100101101111110101101001011010100001011111110101011010010000101010010110101101010110100000001010100101101010111110101000010101011100001110101010101111100001010101001011101010101011010001010101010010"
            },
            "results": {
                "result": [
                    {
                        "id": "Y2hlY2stcHJvamVjdF9tZWRpYS0yMTQt",
                        "doc_id": "Y2hlY2stcHJvamVjdF9tZWRpYS0yMTQt",
                        "pdq": "1110101010001011110100000011110010101000000010110101101010100101101111110101101001011010100001011111110101011010010000101010010110101101010110100000001010100101101010111110101000010101011100001110101010101111100001010101001011101010101011010001010101010010",
                        "url": "http://minio:9000/check-api-dev/uploads/uploaded_image/55/09572dedf610aad68090214303c14829.png",
                        "context": [
                            {
                                "team_id": pm2.team_id,
                                "has_custom_id": true,
                                "project_media_id": pm2.id,
                                "temporary_media": false,
                            }
                        ],
                        "score": 1.0,
                        "model": "image/pdq"
                    }
                ]
            }
        }
    }
    assert_no_difference 'Relationship.count' do
      # Simulate the webhook hitting the server and being executed....
      relationship = Bot::Alegre.process_alegre_callback(JSON.parse(params.to_json)) #hack to force into stringed keys
    end
  end

  test "should handle a call to get_items_with_similar_media_v2 with a temporary request" do
    keys = {
      confirmed_results: "alegre:async_results:blah_nil_true",
      suggested_or_confirmed_results: "alegre:async_results:blah_nil_false"
    }
    sequence = sequence('get_cached_data_sequence')
    Bot::Alegre.stubs(:get_similar_items_v2_async).returns(true)
    Bot::Alegre.stubs(:get_cached_data).in_sequence(sequence).returns({blah: nil}).then.returns({})
    Bot::Alegre.stubs(:get_required_keys).returns(keys)
    Bot::Alegre.stubs(:get_similar_items_v2_callback).returns({})
    Bot::Alegre.stubs(:delete).returns(true)
    assert_equal Bot::Alegre.get_items_with_similar_media_v2(type: "audio", media_url: "http://example.com", timeout: 1), {}
    Bot::Alegre.unstub(:get_similar_items_v2_async)
    Bot::Alegre.unstub(:get_cached_data)
    Bot::Alegre.unstub(:get_required_keys)
    Bot::Alegre.unstub(:get_similar_items_v2_callback)
    Bot::Alegre.unstub(:delete)
  end

  test "should get_cached_data with right fallbacks" do
    pm1 = create_project_media team: @team, media: create_uploaded_audio
    assert_equal Bot::Alegre.get_cached_data(Bot::Alegre.get_required_keys(pm1, nil)), {confirmed_results: nil, suggested_or_confirmed_results: nil}
  end

  test "should relate project media for text" do
    pm1 = create_project_media team: @team, quote: 'This is a long text that creates a text-based item'
    pm2 = create_project_media team: @team, quote: 'This is another long text that creates a text-based item'
    Bot::Alegre.stubs(:get_similar_items_v2).returns({pm2.id=>{:score=>0.91, :context=>{"team_id"=>pm2.team_id, "has_custom_id"=>true, "project_media_id"=>pm2.id, "temporary_media"=>false}, :model=>"audio", :source_field=>"audio", :target_field=>"audio", :relationship_type=>Relationship.suggested_type}})
    relationship = nil
    assert_difference 'Relationship.count' do
      relationship = Bot::Alegre.relate_project_media(pm1)
    end
    assert_equal relationship.source, pm2
    assert_equal relationship.target, pm1
    assert_equal relationship.relationship_type, Relationship.suggested_type
    Bot::Alegre.unstub(:get_similar_items_v2)
  end

  test "should relate project media for audio" do
    pm1 = create_project_media team: @team, media: create_uploaded_audio
    pm2 = create_project_media team: @team, media: create_uploaded_audio
    Bot::Alegre.stubs(:get_similar_items_v2).returns({pm2.id=>{:score=>0.91, :context=>{"team_id"=>pm2.team_id, "has_custom_id"=>true, "project_media_id"=>pm2.id, "temporary_media"=>false}, :model=>"audio", :source_field=>"audio", :target_field=>"audio", :relationship_type=>Relationship.suggested_type}})
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
    Bot::Alegre.stubs(:get_similar_items_v2).returns({pm2.id=>{:score=>0.91, :context=>{"team_id"=>pm2.team_id, "has_custom_id"=>true, "project_media_id"=>pm2.id, "temporary_media"=>false}, :model=>"image", :source_field=>"image", :target_field=>"image", :relationship_type=>Relationship.suggested_type}})
    relationship = nil
    assert_difference 'Relationship.count' do
      relationship = Bot::Alegre.relate_project_media(pm1)
    end
    assert_equal relationship.source, pm2
    assert_equal relationship.target, pm1
    assert_equal relationship.relationship_type, Relationship.suggested_type
    Bot::Alegre.unstub(:get_similar_items_v2)
  end

  test "should relate project media for video" do
    pm1 = create_project_media team: @team, media: create_uploaded_video
    pm2 = create_project_media team: @team, media: create_uploaded_video
    Bot::Alegre.stubs(:get_similar_items_v2).returns({pm2.id=>{:score=>0.91, :context=>{"team_id"=>pm2.team_id, "has_custom_id"=>true, "project_media_id"=>pm2.id, "temporary_media"=>false}, :model=>"video", :source_field=>"video", :target_field=>"video", :relationship_type=>Relationship.suggested_type}})
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
    tbi = TeamBotInstallation.where(team: @team, user: @bot).last
    tbi.set_audio_similarity_enabled = false
    tbi.save!
    Bot::Alegre.stubs(:merge_suggested_and_confirmed).never
    pm = create_project_media team: @team, media: create_uploaded_audio
    assert_equal({}, Bot::Alegre.get_similar_items_v2(pm, nil))
  end

  test "should not relate project media for image if disabled on workspace" do
    tbi = TeamBotInstallation.where(team: @team, user: @bot).last
    tbi.set_image_similarity_enabled = false
    tbi.save!
    Bot::Alegre.stubs(:merge_suggested_and_confirmed).never
    pm = create_project_media team: @team, media: create_uploaded_image
    assert_equal({}, Bot::Alegre.get_similar_items_v2(pm, nil))
  end

  test "should return a similarity_disabled_for_project_media? of true for a disabled workspace" do
    tbi = TeamBotInstallation.where(team: @team, user: @bot).last
    tbi.set_image_similarity_enabled = false
    tbi.save!
    Bot::Alegre.stubs(:merge_suggested_and_confirmed).never
    pm = create_project_media team: @team, media: create_uploaded_image
    assert_equal(true, Bot::Alegre.similarity_disabled_for_project_media?(pm))
  end

  test "should return a similarity_disabled_for_project_media? of true for an enabled workspace" do
    tbi = TeamBotInstallation.where(team: @team, user: @bot).last
    tbi.set_image_similarity_enabled = true
    tbi.save!
    Bot::Alegre.stubs(:merge_suggested_and_confirmed).never
    pm = create_project_media team: @team, media: create_uploaded_image
    assert_equal(false, Bot::Alegre.similarity_disabled_for_project_media?(pm))
  end

  test "should not wait for a response when disabled" do
    tbi = TeamBotInstallation.where(team: @team, user: @bot).last
    tbi.set_image_similarity_enabled = false
    tbi.save!
    Bot::Alegre.stubs(:merge_suggested_and_confirmed).never
    pm = create_project_media team: @team, media: create_uploaded_image
    assert_equal({}, Bot::Alegre.wait_for_results(pm, {}))
  end

  test "should not relate project media for video if disabled on workspace" do
    tbi = TeamBotInstallation.where(team: @team, user: @bot).last
    tbi.set_video_similarity_enabled = false
    tbi.save!
    Bot::Alegre.stubs(:merge_suggested_and_confirmed).never
    pm = create_project_media team: @team, media: create_uploaded_video
    assert_equal({}, Bot::Alegre.get_similar_items_v2(pm, nil))
  end

  test "should generate content_hash for named field on text types" do
    pm = create_project_media
    data = {
      title: 'Report text title',
      text: 'Report text content',
      headline: 'Visual card title',
      description: 'Visual card content'
    }
    publish_report(pm, {}, nil, data)
    pm = ProjectMedia.find(pm.id).reload
    assert_equal("eb02b714673c8af17b108836ce750070", Bot::Alegre.content_hash(pm, "report_text_title"))
  end

  test "should generate content_hash for link types" do
    url = "http://example.com/newslink"
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    raw = {"json+ld": {}}
    response = {'type':'media','data': {'url': url, 'type': 'item', 'raw': raw}}.to_json
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    pm = create_project_media url: url
    assert_equal("7621482de494568a442bfac13b1ceeb2", Bot::Alegre.content_hash(pm, nil))
  end

  test "should generate content_hash for media types" do
    pm = create_project_media media: create_uploaded_image
    assert_equal("110c700b3c4b02286cbfa3b700af8a57", Bot::Alegre.content_hash(pm, nil))
  end

  test "should generate content_hash for temporary types" do
    pm = TemporaryProjectMedia.new
    pm.url = "http://example.com/asset.mp3"
    pm.id = Digest::MD5.hexdigest(pm.url).to_i(16)
    pm.team_id = [1]
    pm.type = "audio"
    assert_equal(nil, Bot::Alegre.content_hash(pm, nil))
    Rails.cache.write("url_sha:#{pm.url}", Digest::MD5.hexdigest("blah"), expires_in: 60*3)
    assert_equal("6f1ed002ab5595859014ebf0951522d9", Bot::Alegre.content_hash(pm, nil))
  end

  test "should not get similar items for one-word text field values" do
    # Test data
    t = create_team
    pm = create_project_media team: t
    WebMock.stub_request(:post, "#{CheckConfig.get('alegre_host')}/similarity/sync/text").with { |request|
      json = JSON.parse(request.body)
      json['text'] == 'Foo Bar'
    }.to_return(body: { result: [{ id: pm.id, context: { team_id: t.id } }] }.to_json)
    WebMock.stub_request(:post, "#{CheckConfig.get('alegre_host')}/similarity/async/text").with { |request|
      json = JSON.parse(request.body)
      json['text'] == 'Foo Bar'
    }.to_return(body: { message: 'Test', queue: 'test', body: {} }.to_json)
    url = random_url
    pm1 = create_project_media quote: url, team: t
    pm2 = create_project_media quote: 'Foo Bar', team: t
    assert_equal url, pm1.title
    assert_equal 'Foo Bar', pm2.title

    # Testing sync method
    assert_equal({}, Bot::Alegre.get_items(pm1, 'title'))
    assert_not_equal({}, Bot::Alegre.get_items(pm2, 'title'))

    # Testing async method
    assert_equal({}, Bot::Alegre.get_items_async(pm1, 'title'))
    assert_not_equal({}, Bot::Alegre.get_items_async(pm2, 'title'))
  end
end
