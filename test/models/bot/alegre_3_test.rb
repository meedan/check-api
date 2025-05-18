require_relative '../../test_helper'

class Bot::Alegre3Test < ActiveSupport::TestCase
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
    @bot.install_to!(p.team)
    @team = team
    m = create_claim_media quote: 'I like apples'
    @pm = create_project_media project: p, media: m
    create_flag_annotation_type
    create_extracted_text_annotation_type
    Sidekiq::Testing.inline!
  end

  def teardown
    super
    Bot::Alegre.unstub(:media_file_url)
  end

  test "should return language" do
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      WebMock.stub_request(:post, 'http://alegre/text/langid/').to_return(body: {
        'result': {
          'language': 'en',
          'confidence': 1.0
        }
      }.to_json)
      Bot::Alegre.stubs(:request).returns({
        'result' => {
          'language' => 'en',
          'confidence' => 1.0
        }
      })
      WebMock.disable_net_connect! allow: /#{CheckConfig.get('elasticsearch_host')}|#{CheckConfig.get('storage_endpoint')}/
      assert_difference 'Annotation.count' do
        assert_equal 'en', Bot::Alegre.get_language(@pm)
      end
      Bot::Alegre.unstub(:request)
    end
  end

  test "should return language und if there is an error" do
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      WebMock.stub_request(:post, 'http://alegre/text/langid/').to_return(body: {
        'foo': 'bar'
      }.to_json)
      Bot::Alegre.stubs(:request).raises(RuntimeError)
      WebMock.disable_net_connect! allow: /#{CheckConfig.get('elasticsearch_host')}|#{CheckConfig.get('storage_endpoint')}/
      assert_difference 'Annotation.count' do
        assert_equal 'und', Bot::Alegre.get_language(@pm)
      end
      Bot::Alegre.unstub(:request)
    end
  end

  test "should bypass untranscribable audio" do
    json_schema = {
      type: 'object',
      required: ['job_name'],
      properties: {
        text: { type: 'string' },
        job_name: { type: 'string' },
        last_response: { type: 'object' }
      }
    }
    create_annotation_type_and_fields('Transcription', {}, json_schema)
    tbi = Bot::Alegre.get_alegre_tbi(@team.id)
    tbi.set_transcription_similarity_enabled = false
    tbi.save!
    WebMock.stub_request(:post, 'http://alegre/text/langid/').to_return(body: { 'result' => { 'language' => 'es' }}.to_json)
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      WebMock.disable_net_connect! allow: /#{CheckConfig.get('elasticsearch_host')}|#{CheckConfig.get('storage_endpoint')}/
      WebMock.stub_request(:post, 'http://alegre/text/similarity/').to_return(body: 'success')
      WebMock.stub_request(:delete, 'http://alegre/text/similarity/').to_return(body: {success: true}.to_json)
      WebMock.stub_request(:post, 'http://alegre/text/similarity/search/').to_return(body: {success: true}.to_json)
      WebMock.stub_request(:post, 'http://alegre/audio/similarity/search/').to_return(body: {
        "result": []
      }.to_json)

      media_file_url = 'https://example.com/test/data/rails.mp3'
      s3_file_url = "s3://check-api-test/test/data/rails.mp3"
      WebMock.stub_request(:get, media_file_url).to_return(body: File.new(File.join(Rails.root, 'test', 'data', 'rails.mp3')))
      Bot::Alegre.stubs(:media_file_url).returns(media_file_url)

      pm1 = create_project_media team: @pm.team, media: create_uploaded_audio(file: 'rails.mp3')
      WebMock.stub_request(:post, "http://alegre/similarity/async/audio").with(body: {:content_hash=>Bot::Alegre.content_hash(pm1, nil), :doc_id=>Bot::Alegre.item_doc_id(pm1), :context=>{:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true, :temporary_media=>false}, :url=>media_file_url, :threshold=>0.9, :confirmed=> false}).to_return(body: {
        "result": []
      }.to_json)
      WebMock.stub_request(:post, "http://alegre/similarity/async/audio").with(body: {:content_hash=>Bot::Alegre.content_hash(pm1, nil), :doc_id=>Bot::Alegre.item_doc_id(pm1), :context=>{:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true, :temporary_media=>false}, :url=>media_file_url, :threshold=>0.9, :confirmed=> true}).to_return(body: {
        "result": []
      }.to_json)
      WebMock.stub_request(:post, 'http://alegre/audio/transcription/result/').with(body: {job_name: "0c481e87f2774b1bd41a0a70d9b70d11"}).to_return(body: { 'job_status' => 'DONE' }.to_json)
      WebMock.stub_request(:post, 'http://alegre/audio/transcription/').with({
        body: { url: s3_file_url, job_name: '0c481e87f2774b1bd41a0a70d9b70d11' }.to_json
      }).to_return(body: { 'job_status' => 'IN_PROGRESS' }.to_json)
      # Verify with transcription_similarity_enabled = false
      assert Bot::Alegre.run({ data: { dbid: pm1.id }, event: 'create_project_media' })
      a = pm1.annotations('transcription').last
      assert_nil a
      # Verify with transcription_similarity_enabled = true and duration less than transcription_maximum_duration
      tbi.set_transcription_similarity_enabled = true
      tbi.set_transcription_minimum_duration = 7
      tbi.set_transcription_maximum_duration = 10
      tbi.set_transcription_minimum_requests = 2
      tbi.save!
      assert Bot::Alegre.run({ data: { dbid: pm1.id }, event: 'create_project_media' })
      a = pm1.annotations('transcription').last
      assert_nil a
      # Verify that requests count less than transcription_minimum_requests
      tbi.set_transcription_maximum_duration = 30
      tbi.save!
      assert Bot::Alegre.run({ data: { dbid: pm1.id }, event: 'create_project_media' })
      a = pm1.annotations('transcription').last
      assert_nil a
      # Audio item match all required conditions by verify transcription_minimum_requests count
      RequestStore.store[:skip_cached_field_update] = false
      create_tipline_request team: @team.id, associated: pm1
      create_tipline_request team: @team.id, associated: pm1
      assert Bot::Alegre.run({ data: { dbid: pm1.id }, event: 'create_project_media' })
      a = pm1.annotations('transcription').last
      assert_equal "", a.data['text']
    end
  end

  test "should auto transcribe audio" do
    json_schema = {
      type: 'object',
      required: ['job_name'],
      properties: {
        text: { type: 'string' },
        job_name: { type: 'string' },
        last_response: { type: 'object' }
      }
    }
    create_annotation_type_and_fields('Transcription', {}, json_schema)
    tbi = Bot::Alegre.get_alegre_tbi(@team.id)
    tbi.set_transcription_similarity_enabled = false
    tbi.save!
    WebMock.stub_request(:post, 'http://alegre/text/langid/').to_return(body: { 'result' => { 'language' => 'es' }}.to_json)
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      WebMock.disable_net_connect! allow: /#{CheckConfig.get('elasticsearch_host')}|#{CheckConfig.get('storage_endpoint')}/
      WebMock.stub_request(:post, 'http://alegre/text/similarity/').to_return(body: 'success')
      WebMock.stub_request(:delete, 'http://alegre/text/similarity/').to_return(body: {success: true}.to_json)
      WebMock.stub_request(:post, 'http://alegre/similarity/sync/text').to_return(body: {success: true}.to_json)
      WebMock.stub_request(:post, 'http://alegre/audio/similarity/').to_return(body: {
        "success": true
      }.to_json)

      media_file_url = 'https://example.com/test/data/rails.mp3'
      s3_file_url = "s3://check-api-test/test/data/rails.mp3"
      WebMock.stub_request(:get, media_file_url).to_return(body: File.new(File.join(Rails.root, 'test', 'data', 'rails.mp3')))
      Bot::Alegre.stubs(:media_file_url).returns(media_file_url)

      pm1 = create_project_media team: @pm.team, media: create_uploaded_audio(file: 'rails.mp3')
      WebMock.stub_request(:post, "http://alegre/similarity/async/audio").with(body: {:content_hash=>Bot::Alegre.content_hash(pm1, nil), :doc_id=>Bot::Alegre.item_doc_id(pm1), :context=>{:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true, :temporary_media=>false}, :url=>media_file_url, :threshold=>0.9, :confirmed=>true}).to_return(body: {
        "result": []
      }.to_json)
      WebMock.stub_request(:post, "http://alegre/similarity/async/audio").with(body: {:content_hash=>Bot::Alegre.content_hash(pm1, nil), :doc_id=>Bot::Alegre.item_doc_id(pm1), :context=>{:team_id=>pm1.team_id, :project_media_id=>pm1.id, :has_custom_id=>true, :temporary_media=>false}, :url=>media_file_url, :threshold=>0.9, :confirmed=>false}).to_return(body: {
        "result": []
      }.to_json)
      WebMock.stub_request(:post, 'http://alegre/audio/transcription/').with({
        body: { url: s3_file_url, job_name: '0c481e87f2774b1bd41a0a70d9b70d11' }.to_json
      }).to_return(body: { 'job_status' => 'IN_PROGRESS' }.to_json)
      WebMock.stub_request(:post, 'http://alegre/audio/transcription/result/').with(body: {job_name: "0c481e87f2774b1bd41a0a70d9b70d11"}).to_return(body: { 'job_status' => 'COMPLETED', 'transcription' => 'Foo bar' }.to_json)
      # Verify with transcription_similarity_enabled = false
      assert Bot::Alegre.run({ data: { dbid: pm1.id }, event: 'create_project_media' })
      a = pm1.annotations('transcription').last
      assert_nil a
      # Verify with transcription_similarity_enabled = true and duration less than transcription_maximum_duration
      tbi.set_transcription_similarity_enabled = true
      tbi.set_transcription_minimum_duration = 7
      tbi.set_transcription_maximum_duration = 10
      tbi.set_transcription_minimum_requests = 2
      tbi.save!
      assert Bot::Alegre.run({ data: { dbid: pm1.id }, event: 'create_project_media' })
      a = pm1.annotations('transcription').last
      assert_nil a
      # Verify that requests count less than transcription_minimum_requests
      tbi.set_transcription_maximum_duration = 30
      tbi.save!
      assert Bot::Alegre.run({ data: { dbid: pm1.id }, event: 'create_project_media' })
      a = pm1.annotations('transcription').last
      assert_nil a
      # Audio item match all required conditions by verify transcription_minimum_requests count
      RequestStore.store[:skip_cached_field_update] = false
      create_tipline_request team_id: @pm.team_id, associated: pm1
      create_tipline_request team_id: @pm.team_id, associated: pm1
      assert Bot::Alegre.run({ data: { dbid: pm1.id }, event: 'create_project_media' })
      a = pm1.annotations('transcription').last
      expected_last_response = {"job_status"=>"COMPLETED", "transcription"=>"Foo bar"}
      assert_equal expected_last_response, a.data["last_response"]
      assert_equal 'Foo bar', a.data['text']
    end
  end

  test "should return true when bot is called successfully" do
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      WebMock.stub_request(:post, 'http://alegre/text/similarity/').to_return(body: 'success')
      WebMock.stub_request(:post, 'http://alegre/text/langid/').to_return(body: {
        'result': {
          'language': 'en',
          'confidence': 1.0
        }
      }.to_json)
      Bot::Alegre.stubs(:request).returns({
        'result' => {
          'language' => 'en',
          'confidence' => 1.0
        }
      })
      WebMock.disable_net_connect! allow: /#{CheckConfig.get('elasticsearch_host')}|#{CheckConfig.get('storage_endpoint')}/
      assert Bot::Alegre.run({ data: { dbid: @pm.id }, event: 'create_project_media' })
      Bot::Alegre.unstub(:request)
    end
  end

  test "should return false when bot cannot be called" do
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      assert !Bot::Alegre.run({ data: { dbid: @pm.id }, event: 'some_other_event' })
      assert !Bot::Alegre.run({ event: 'create_project_media' })
    end
    stub_configs({ 'alegre_host' => '' }) do
      assert !Bot::Alegre.run({ data: { dbid: @pm.id }, event: 'create_project_media' })
    end
  end

  test "should extract project medias from context as dict" do
    assert_equal Bot::Alegre.extract_project_medias_from_context({"_score" => 2, "_source" => {"context" => {"project_media_id" => 1}}}), {1=>{:score=>2, :context=>{"project_media_id"=>1}, :model=>nil}}
  end

  test "should extract project medias from context as array" do
    assert_equal Bot::Alegre.extract_project_medias_from_context({"_score" => 2, "_source" => {"context" => [{"project_media_id" => 1}]}}), {1=>{:score=>2, :context=>[{"project_media_id"=>1}], :model=>nil}}
  end

  test "should update on alegre" do
    create_verification_status_stuff
    RequestStore.store[:skip_cached_field_update] = false
    pm = create_project_media quote: "Blah", team: @team
    pm.analysis = { title: 'This is a long enough Title so as to allow an actual check of other titles' }
    assert_equal pm.save!, true
  end

  test "should delete from alegre" do
    create_verification_status_stuff
    RequestStore.store[:skip_cached_field_update] = false
    pm = create_project_media quote: "Blah", team: @team
    pm.analysis = { title: 'This is a long enough Title so as to allow an actual check of other titles' }
    pm.save!
    assert_equal pm.destroy, pm
  end

  test "should decode a doc_id" do
    assert_equal Bot::Alegre.decode_item_doc_id("Y2hlY2stcHJvamVjdF9tZWRpYS01NTQ1NzEtdmlkZW8"), ["check", "project_media", "554571", "video" ]
  end

  test "should not replace when parent is blank" do
    t = create_team
    pm1 = create_project_media team: t, is_image: true
    pm2 = create_project_media team: t, media: Blank.new
    pm3 = create_project_media team: t, media: Blank.new
    assert_no_difference 'ProjectMedia.count' do
      assert_difference 'Relationship.count' do
        Bot::Alegre.add_relationships(pm3, {pm2.id => {score: 1, relationship_type: Relationship.confirmed_type}})
      end
    end
  end

  test "should notify Sentry if there's a bad relationship" do
    CheckSentry.expects(:notify).once
    t = create_team
    pm1 = create_project_media team: t, is_image: true
    pm2 = create_project_media team: t, is_image: true
    pm3 = create_project_media team: t, is_image: true
    create_relationship source_id: pm3.id, target_id: pm2.id, relationship_type: Relationship.confirmed_type
    Bot::Alegre.report_exception_if_bad_relationship(Relationship.last, {ball: 1}, "boop")
  end

  test "should store relationship for lower-scoring match that's from a preferred model, but is latest ID" do
    t = create_team
    pm1 = create_project_media team: t, is_image: true
    pm2 = create_project_media team: t, media: Blank.new
    pm3 = create_project_media team: t, media: Blank.new
    pm4 = create_project_media team: t, media: Blank.new
    assert_no_difference 'ProjectMedia.count' do
      assert_difference 'Relationship.count' do
        Bot::Alegre.add_relationships(pm3, {pm2.id => {score: 100, model: Bot::Alegre::ELASTICSEARCH_MODEL, relationship_type: Relationship.confirmed_type}, pm1.id => {score: 1, model: Bot::Alegre::INDIAN_MODEL, relationship_type: Relationship.confirmed_type}, pm4.id => {score: 1, model: Bot::Alegre::INDIAN_MODEL, relationship_type: Relationship.confirmed_type}})
      end
    end
    assert_equal Relationship.last.source_id, pm1.id
  end

  test "should store relationship for highest-scoring match" do
    t = create_team
    pm1 = create_project_media team: t, is_image: true
    pm2 = create_project_media team: t, media: Blank.new
    pm3 = create_project_media team: t, media: Blank.new
    assert_no_difference 'ProjectMedia.count' do
      assert_difference 'Relationship.count' do
        Bot::Alegre.add_relationships(pm3, {pm2.id => {score: 100, relationship_type: Relationship.confirmed_type}, pm1.id => {score: 1, relationship_type: Relationship.confirmed_type}})
      end
    end
    assert_equal Relationship.last.source_id, pm2.id
  end

  test "should not create suggestion when parent is trashed" do
    t = create_team
    pm2 = create_project_media team: t, is_image: true, archived: CheckArchivedFlags::FlagCodes::TRASHED
    pm3 = create_project_media team: t, is_image: true
    assert_no_difference 'Relationship.count' do
      Bot::Alegre.add_relationships(pm3, {pm2.id => {score: 1, relationship_type: Relationship.suggested_type}})
    end
  end

  test "should not create suggestion when child is trashed" do
    t = create_team
    pm2 = create_project_media team: t, is_image: true
    pm3 = create_project_media team: t, is_image: true, archived: CheckArchivedFlags::FlagCodes::TRASHED
    assert_no_difference 'Relationship.count' do
      Bot::Alegre.add_relationships(pm3, {pm2.id => {score: 1, relationship_type: Relationship.suggested_type}})
    end
  end

  test "should return empty when shouldnt get similar items of certain type" do
    t = create_team
    pm1 = create_project_media team: t, quote: "Blah", team: @team
    pm1.analysis = { title: 'This is a long enough Title so as to allow an actual check of other titles' }
    pm1.save!
    pm2 = create_project_media team: t, quote: "Blah2", team: @team
    pm2.save!
    Bot::Alegre.get_merged_items_with_similar_text(pm2, Bot::Alegre.get_threshold_for_query('text', pm2))
    Bot::Alegre.stubs(:get_merged_items_with_similar_text).with(pm2, Bot::Alegre.get_threshold_for_query('text', pm2)).returns({pm1.id => 0.99})
    Bot::Alegre.stubs(:get_merged_items_with_similar_text).with(pm2, Bot::Alegre.get_threshold_for_query('text', pm2, true)).returns({})
    tbi = TeamBotInstallation.new
    tbi.set_text_similarity_enabled = false
    tbi.user = BotUser.alegre_user
    tbi.team = t
    tbi.save!
    TeamBotInstallation.stubs(:find_by_team_id_and_user_id).returns(tbi)
    assert_equal Bot::Alegre.get_similar_items(pm2), {}
    Bot::Alegre.unstub(:get_merged_items_with_similar_text)
    TeamBotInstallation.unstub(:find_by_team_id_and_user_id)
  end

  test "should return matches for non-blank cases" do
    t = create_team
    pm1 = create_project_media team: t, quote: "Blah", team: @team
    pm1.analysis = { title: 'This is a long enough Title so as to allow an actual check of other titles' }
    pm1.save!
    pm2 = create_project_media team: t, quote: "Blah2", team: @team
    pm2.save!
    Bot::Alegre.stubs(:get_merged_items_with_similar_text).with(pm2, Bot::Alegre.get_threshold_for_query('text', pm2)).returns({pm1.id => {score: 0.99, context: {"team_id" => pm1.team_id, "blah" => 1}}})
    Bot::Alegre.stubs(:get_merged_items_with_similar_text).with(pm2, Bot::Alegre.get_threshold_for_query('text', pm2, true)).returns({})
    assert_equal Bot::Alegre.get_similar_items(pm2), {pm1.id=>{:score=>0.99, :context => [{"team_id" => pm1.team_id, "blah" => 1}], :relationship_type=>{:source=>"suggested_sibling", :target=>"suggested_sibling"}}}
    Bot::Alegre.unstub(:get_merged_items_with_similar_text)
  end

  test "should not return matches for blank cases" do
    t = create_team
    pm1 = create_project_media team: t, quote: "Blah", team: @team
    pm1.analysis = { title: 'This is a long enough Title so as to allow an actual check of other titles' }
    pm1.save!
    pm2 = create_project_media team: t, quote: "Blah2", team: @team
    pm2.save!
    pm3 = create_project_media team: t, media: Blank.new
    pm3.save!
    Bot::Alegre.stubs(:get_merged_items_with_similar_text).with(pm3, Bot::Alegre.get_threshold_for_query('text', pm3)).returns({pm1.id => {score: 0.99, context: {"blah" => 1}}, pm2.id => {score: 0.99, context: {"blah" => 1}}})
    assert_equal Bot::Alegre.get_similar_items(pm3), {}
    Bot::Alegre.unstub(:get_merged_items_with_similar_text)
  end

  test "should add relationships" do
    t = create_team
    pm1 = create_project_media team: t, is_image: true
    pm2 = create_project_media team: t, is_image: true
    pm3 = create_project_media team: t, is_image: true
    assert_difference 'Relationship.count' do
      response = Bot::Alegre.add_relationships(pm3, {pm2.id => {score: 1, relationship_type: Relationship.confirmed_type}})
    end
    r = Relationship.last
    assert_equal pm3, r.target
    assert_equal pm2, r.source
    assert_equal r.weight, 1
  end

  test "should get similar items" do
    t = create_team
    pm1 = create_project_media team: t
    Bot::Alegre.stubs(:matching_model_to_use).with(pm1.team_id).returns(Bot::Alegre::ELASTICSEARCH_MODEL)
    response = Bot::Alegre.get_similar_items(pm1)
    assert_equal response.class, Hash
    Bot::Alegre.unstub(:matching_model_to_use)
  end

  test "should get empty similar items when not text or image" do
    t = create_team
    pm1 = create_project_media team: t
    pm1.media.type = "Bloop"
    response = Bot::Alegre.get_similar_items(pm1)
    assert_equal response.class, Hash
  end

  test "should not return a malformed hash" do
    Bot::Alegre.stubs(:request).returns({"result"=> [{
      "_index"=>"alegre_similarity",
      "_type"=>"_doc",
      "_id"=>"i8XY53UB36CYclMPF5wC",
      "_score"=>100,
      "_source"=> {
        "content"=>
          "Bautista began his wrestling career in 1999, and signed with the World Wrestling Federation (WWF, now WWE) in 2000. From 2002 to 2010, he gained fame under the ring name Batista and became a six-time world champion by winning the World Heavyweight Championship four times and the WWE Championship twice. He holds the record for the longest reign as World Heavyweight Champion at 282 days and has also won the World Tag Team Championship three times (twice with Ric Flair and once with John Cena) and the WWE Tag Team Championship once (with Rey Mysterio). He was the winner of the 2005 Royal Rumble match and went on to headline WrestleMania 21, one of the top five highest-grossing pay-per-view events in professional wrestling history",
        "context"=>{"team_id"=>1692, "field"=>"description", "project_media_id"=>1932}
      }
    }, {
      "_index"=>"alegre_similarity",
      "_type"=>"_doc",
      "_id"=>"tMXj53UB36CYclMPXp14",
      "_score"=>200,
      "_source"=>
       {
         "content"=>
           "Bautista began his wrestling career in 1999, and signed with the World Wrestling Federation (WWF, now WWE) in 2000. From 2002 to 2010, he gained fame under the ring name Batista and became a six-time world champion by winning the World Heavyweight Championship four times and the WWE Championship twice. He holds the record for the longest reign as World Heavyweight Champion at 282 days and has also won the World Tag Team Championship three times (twice with Ric Flair and once with John Cena) and the WWE Tag Team Championship once (with Rey Mysterio). He was the winner of the 2005 Royal Rumble match and went on to headline WrestleMania 21, one of the top five highest-grossing pay-per-view events in professional wrestling history",
         "context"=>{"team_id"=>1692, "field"=>"title", "project_media_id"=>1932}
    }}]})
    response = Bot::Alegre.get_similar_items_from_api("blah", {})
    assert_equal response.class, Hash
    assert_equal response, {1932=>{:score=>200, :context=>{"team_id"=>1692, "field"=>"title|description", "project_media_id"=>1932, "contexts_count"=>2}, :model=>nil}}
    Bot::Alegre.unstub(:request)
  end

  test "should generate correct text conditions for api request" do
    conditions = Bot::Alegre.similar_texts_from_api_conditions("blah", "elasticsearch", 'true', 1, 'original_title', [{value: 0.7, key: 'text_elasticsearch_suggestion_threshold', model: 'elasticsearch', automatic: false}])
    assert_equal conditions, {:text=>"blah", :models=>["elasticsearch"], :fuzzy=>true, :context=>{:has_custom_id=>true, :field=>"original_title", :team_id=>1}, :threshold=>0.7, :min_es_score=>10, :match_across_content_types=>true}
  end

  test "should generate correct media conditions for api request" do
    conditions = Bot::Alegre.similar_media_content_from_api_conditions(1, "https://upload.wikimedia.org/wikipedia/en/7/7d/Lenna_%28test_image%29.png", [{value: 0.7, key: 'image_hash_suggestion_threshold', model: 'elasticsearch', automatic: false}])
    assert_equal conditions, {:url=>"https://upload.wikimedia.org/wikipedia/en/7/7d/Lenna_%28test_image%29.png", :context=>{:has_custom_id=>true, :team_id=>1}, :threshold=>0.7, :match_across_content_types=>true}
  end

  test "should get similar items when they are text-based" do
    create_verification_status_stuff
    RequestStore.store[:skip_cached_field_update] = false
    pm = create_project_media quote: "Blah", team: @team
    pm.analysis = { title: 'This is a long enough Title so as to allow an actual check of other titles' }
    pm.save!
    pm2 = create_project_media quote: "Blah2", team: @team
    pm2.analysis = { title: 'This is also a long enough Title so as to allow an actual check of other titles' }
    pm2.save!
    Bot::Alegre.stubs(:matching_model_to_use).with([pm.team_id]).returns(Bot::Alegre::ELASTICSEARCH_MODEL)
    Bot::Alegre.stubs(:matching_model_to_use).with(pm2.team_id).returns(Bot::Alegre::ELASTICSEARCH_MODEL)
    Bot::Alegre.stubs(:request).returns({"result" => [{
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
    response = Bot::Alegre.get_similar_items(pm)
    assert_equal response.class, Hash
    Bot::Alegre.unstub(:request)
    Bot::Alegre.unstub(:matching_model_to_use)
  end

  test "should get items with similar text when they are text-based" do
    create_verification_status_stuff
    RequestStore.store[:skip_cached_field_update] = false
    pm = create_project_media quote: "Blah", team: @team
    pm.analysis = { title: 'This is a long enough Title so as to allow an actual check of other titles' }
    pm.save!
    pm2 = create_project_media quote: "Blah2", team: @team
    pm2.analysis = { title: 'This is also a long enough Title so as to allow an actual check of other titles' }
    pm2.save!
    Bot::Alegre.stubs(:request).returns({"result" => [{
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
    response = Bot::Alegre.get_items_with_similar_text(pm, ['title'], [{key: 'text_elasticsearch_suggestion_threshold', model: 'elasticsearch', value: 0.7, automatic: false}], 'blah')
    assert_equal response.class, Hash
    Bot::Alegre.unstub(:request)
  end

  test "should not get items with similar short text when they are text-based" do
    create_verification_status_stuff
    RequestStore.store[:skip_cached_field_update] = false
    pm = create_project_media quote: "Blah", team: @team
    pm.analysis = { title: 'This is a long enough Title so as to allow an actual check of other titles' }
    pm.save!
    pm2 = create_project_media quote: "Blah2", team: @team
    pm2.analysis = { title: 'This is also a long enough Title so as to allow an actual check of other titles' }
    pm2.save!
    Bot::Alegre.stubs(:request).returns({"result" => [{
        "_index" => "alegre_similarity",
        "_type" => "_doc",
        "_id" => "tMXj53UB36CYclMPXp14",
        "_score" => 0.9,
        "_source" => {
          "content" => "Bautista",
          "context" => {
            "team_id" => pm2.team.id.to_s,
            "field" => "title",
            "project_media_id" => pm2.id.to_s
          }
        }
      }
      ]
    })
    response = Bot::Alegre.get_items_with_similar_text(pm, ['title'], [{key: 'text_elasticsearch_matching_threshold', model: 'elasticsearch', value: 0.7, automatic: true}], 'blah foo bar')
    assert_equal response.class, Hash
    assert_not_empty response
    Bot::Alegre.unstub(:request)
  end


  test "should get items with similar text" do
    pm = create_project_media quote: "Blah"
    pm2 = create_project_media quote: "Blah"
    pm3 = create_project_media quote: "Blah"
    pm4 = create_project_media quote: "Blah"
    Bot::Alegre.stubs(:get_items_with_similar_title).returns({pm2.id => {score: 0.2, context: {"field" => "title", "blah" => 1}}, pm3.id => {score: 0.3, context: {"field" => "title", "blah" => 1}}})
    Bot::Alegre.stubs(:get_items_with_similar_description).returns({pm3.id => {score: 0.2, context: {"field" => "title", "blah" => 1}}, pm4.id => {score: 0.3, context: {"field" => "title", "blah" => 1}}})
    assert_equal Bot::Alegre.get_merged_items_with_similar_text(pm, 0.0), {pm2.id => {:score=>0.2, :context=>{"field"=>"title", "blah"=>1}, :source_field=>"original_title", :target_field=>"title"}, pm3.id => {:score=>0.3, :context=>{"field"=>"title", "blah"=>1}, :source_field=>"original_title", :target_field=>"title"}, pm4.id => {:score=>0.3, :context=>{"field"=>"title", "blah"=>1}, :source_field=>"original_description", :target_field=>"title"}}
    Bot::Alegre.unstub(:get_items_with_similar_title)
    Bot::Alegre.unstub(:get_items_with_similar_description)
  end

  test "should pass through the send video to similarity index call" do
    create_verification_status_stuff
    RequestStore.store[:skip_cached_field_update] = false
    t = create_team
    pm = create_project_media team: t, media: create_uploaded_video
    pm.media.type = "UploadedVideo"
    pm.media.save!
    pm.save!
    Bot::Alegre.stubs(:request).returns(true)
    assert Bot::Alegre.send_to_media_similarity_index(pm)
    Bot::Alegre.unstub(:request)
  end

  test "should not resort matches if format is unknown" do
    assert_equal 'Foo', Bot::Alegre.return_prioritized_matches('Foo')
  end
end
