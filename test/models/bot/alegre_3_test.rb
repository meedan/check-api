require_relative '../../test_helper'

class Bot::Alegre3Test < ActiveSupport::TestCase
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
  end

  def teardown
    super
    Bot::Alegre.unstub(:media_file_url)
  end

  test "should return language" do
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      WebMock.stub_request(:get, 'http://alegre/text/langid/').to_return(body: {
        'result': {
          'language': 'en',
          'confidence': 1.0
        }
      }.to_json)
      Bot::Alegre.stubs(:request_api).returns({
        'result' => {
          'language' => 'en',
          'confidence' => 1.0
        }
      })
      WebMock.disable_net_connect! allow: /#{CheckConfig.get('elasticsearch_host')}|#{CheckConfig.get('storage_endpoint')}/
      assert_difference 'Annotation.count' do
        assert_equal 'en', Bot::Alegre.get_language(@pm)
      end
      Bot::Alegre.unstub(:request_api)
    end
  end

  test "should return language und if there is an error" do
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      WebMock.stub_request(:get, 'http://alegre/text/langid/').to_return(body: {
        'foo': 'bar'
      }.to_json)
      Bot::Alegre.stubs(:request_api).raises(RuntimeError)
      WebMock.disable_net_connect! allow: /#{CheckConfig.get('elasticsearch_host')}|#{CheckConfig.get('storage_endpoint')}/
      assert_difference 'Annotation.count' do
        assert_equal 'und', Bot::Alegre.get_language(@pm)
      end
      Bot::Alegre.unstub(:request_api)
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
    create_annotation_type_and_fields('Smooch', { 'Data' => ['JSON', true] })
    Bot::Alegre.unstub(:request_api)
    tbi = Bot::Alegre.get_alegre_tbi(@team.id)
    tbi.set_transcription_similarity_enabled = false
    tbi.save!
    WebMock.stub_request(:post, 'http://alegre/text/langid/').to_return(body: { 'result' => { 'language' => 'es' }}.to_json)
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      WebMock.disable_net_connect! allow: /#{CheckConfig.get('elasticsearch_host')}|#{CheckConfig.get('storage_endpoint')}/
      WebMock.stub_request(:post, 'http://alegre/text/similarity/').to_return(body: 'success')
      WebMock.stub_request(:delete, 'http://alegre/text/similarity/').to_return(body: {success: true}.to_json)
      WebMock.stub_request(:get, 'http://alegre/text/similarity/').to_return(body: {success: true}.to_json)
      WebMock.stub_request(:post, 'http://alegre/audio/similarity/').to_return(body: {
        "success": true
      }.to_json)
      WebMock.stub_request(:get, 'http://alegre/audio/similarity/').to_return(body: {
        "result": []
      }.to_json)
      pm1 = create_project_media team: @pm.team, media: create_uploaded_audio(file: 'rails.mp3')
      url = File.join(Rails.root, 'test', 'data', 'rails.mp3')
      WebMock.stub_request(:post, 'http://alegre/audio/transcription/').with({
        body: { url: url, job_name: '0c481e87f2774b1bd41a0a70d9b70d11' }.to_json
      }).to_return(body: { 'job_status' => 'IN_PROGRESS' }.to_json)
      WebMock.stub_request(:get, 'http://alegre/audio/transcription/').with(
        body: { job_name: '0c481e87f2774b1bd41a0a70d9b70d11' }
      ).to_return(body: { 'job_status' => 'COMPLETED', 'transcription' => 'Foo bar' }.to_json)
      Bot::Alegre.stubs(:media_file_url).returns(url)
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
      create_dynamic_annotation annotation_type: 'smooch', annotated: pm1
      create_dynamic_annotation annotation_type: 'smooch', annotated: pm1
      assert Bot::Alegre.run({ data: { dbid: pm1.id }, event: 'create_project_media' })
      a = pm1.annotations('transcription').last
      assert_equal 'Foo bar', a.data['text']
      Bot::Alegre.unstub(:media_file_url)
    end
  end

  test "should return true when bot is called successfully" do
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      WebMock.stub_request(:post, 'http://alegre/text/similarity/').to_return(body: 'success')
      WebMock.stub_request(:get, 'http://alegre/text/langid/').to_return(body: {
        'result': {
          'language': 'en',
          'confidence': 1.0
        }
      }.to_json)
      Bot::Alegre.stubs(:request_api).returns({
        'result' => {
          'language' => 'en',
          'confidence' => 1.0
        }
      })
      WebMock.disable_net_connect! allow: /#{CheckConfig.get('elasticsearch_host')}|#{CheckConfig.get('storage_endpoint')}/
      assert Bot::Alegre.run({ data: { dbid: @pm.id }, event: 'create_project_media' })
      Bot::Alegre.unstub(:request_api)
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

  def self.extract_project_medias_from_context(search_result)
    # We currently have two cases of context:
    # - a straight hash with project_media_id
    # - an array of hashes, each with project_media_id
    context = search_result.dig('_source', 'context')
    pms = []
    if context.kind_of?(Array)
      context.each{ |c| pms.push(c.with_indifferent_access.dig('project_media_id')) }
    elsif context.kind_of?(Hash)
      pms.push(context.with_indifferent_access.dig('project_media_id'))
    end
    Hash[pms.flatten.collect{|pm| [pm.to_i, search_result.with_indifferent_access.dig('_score')]}]
  end

  test "should extract project medias from context" do
    assert_equal Bot::Alegre.extract_project_medias_from_context({"_score" => 2, "_source" => {"context" => {"project_media_id" => 1}}}), {1=>{:score=>2, :context=>{"project_media_id"=>1}, :model=>nil}}
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
    p = create_project
    pm1 = create_project_media project: p, is_image: true
    pm2 = create_project_media project: p, media: Blank.new
    pm3 = create_project_media project: p, media: Blank.new
    assert_no_difference 'ProjectMedia.count' do
      assert_difference 'Relationship.count' do
        Bot::Alegre.add_relationships(pm3, {pm2.id => {score: 1, relationship_type: Relationship.confirmed_type}})
      end
    end
  end

  test "should notify Airbrake if there's a bad relationship" do
    Airbrake.stubs(:configured?).returns(true)
    Airbrake.expects(:notify).once
    p = create_project
    pm1 = create_project_media project: p, is_image: true
    pm2 = create_project_media project: p, is_image: true
    pm3 = create_project_media project: p, is_image: true
    create_relationship source_id: pm3.id, target_id: pm2.id, relationship_type: Relationship.confirmed_type
    Bot::Alegre.throw_airbrake_notify_if_bad_relationship(Relationship.last, {ball: 1}, "boop")
    Airbrake.unstub(:configured?)
    Airbrake.unstub(:notify)
  end

  test "should store relationship for lower-scoring match that's from a preferred model, but is latest ID" do
    p = create_project
    pm1 = create_project_media project: p, is_image: true
    pm2 = create_project_media project: p, media: Blank.new
    pm3 = create_project_media project: p, media: Blank.new
    pm4 = create_project_media project: p, media: Blank.new
    assert_no_difference 'ProjectMedia.count' do
      assert_difference 'Relationship.count' do
        Bot::Alegre.add_relationships(pm3, {pm2.id => {score: 100, model: Bot::Alegre::ELASTICSEARCH_MODEL, relationship_type: Relationship.confirmed_type}, pm1.id => {score: 1, model: Bot::Alegre::INDIAN_MODEL, relationship_type: Relationship.confirmed_type}, pm4.id => {score: 1, model: Bot::Alegre::INDIAN_MODEL, relationship_type: Relationship.confirmed_type}})
      end
    end
    assert_equal Relationship.last.source_id, pm1.id
  end

  test "should store relationship for highest-scoring match" do
    p = create_project
    pm1 = create_project_media project: p, is_image: true
    pm2 = create_project_media project: p, media: Blank.new
    pm3 = create_project_media project: p, media: Blank.new
    assert_no_difference 'ProjectMedia.count' do
      assert_difference 'Relationship.count' do
        Bot::Alegre.add_relationships(pm3, {pm2.id => {score: 100, relationship_type: Relationship.confirmed_type}, pm1.id => {score: 1, relationship_type: Relationship.confirmed_type}})
      end
    end
    assert_equal Relationship.last.source_id, pm2.id
  end

  test "should not create suggestion when parent is trashed" do
    p = create_project
    pm2 = create_project_media project: p, is_image: true, archived: CheckArchivedFlags::FlagCodes::TRASHED
    pm3 = create_project_media project: p, is_image: true
    assert_no_difference 'Relationship.count' do
      Bot::Alegre.add_relationships(pm3, {pm2.id => {score: 1, relationship_type: Relationship.suggested_type}})
    end
  end

  test "should not create suggestion when child is trashed" do
    p = create_project
    pm2 = create_project_media project: p, is_image: true
    pm3 = create_project_media project: p, is_image: true, archived: CheckArchivedFlags::FlagCodes::TRASHED
    assert_no_difference 'Relationship.count' do
      Bot::Alegre.add_relationships(pm3, {pm2.id => {score: 1, relationship_type: Relationship.suggested_type}})
    end
  end

  test "should return empty when shouldnt get similar items of certain type" do
    p = create_project
    pm1 = create_project_media project: p, quote: "Blah", team: @team
    pm1.analysis = { title: 'This is a long enough Title so as to allow an actual check of other titles' }
    pm1.save!
    pm2 = create_project_media project: p, quote: "Blah2", team: @team
    pm2.save!
    Bot::Alegre.get_merged_items_with_similar_text(pm2, Bot::Alegre.get_threshold_for_query('text', pm2))
    Bot::Alegre.stubs(:get_merged_items_with_similar_text).with(pm2, Bot::Alegre.get_threshold_for_query('text', pm2)).returns({pm1.id => 0.99})
    Bot::Alegre.stubs(:get_merged_items_with_similar_text).with(pm2, Bot::Alegre.get_threshold_for_query('text', pm2, true)).returns({})
    tbi = TeamBotInstallation.new
    tbi.set_text_similarity_enabled = false
    tbi.user = BotUser.alegre_user
    tbi.team = p.team
    tbi.save!
    TeamBotInstallation.stubs(:find_by_team_id_and_user_id).returns(tbi)
    assert_equal Bot::Alegre.get_similar_items(pm2), {}
    Bot::Alegre.unstub(:get_merged_items_with_similar_text)
    TeamBotInstallation.unstub(:find_by_team_id_and_user_id)
  end

  test "should return matches for non-blank cases" do
    p = create_project
    pm1 = create_project_media project: p, quote: "Blah", team: @team
    pm1.analysis = { title: 'This is a long enough Title so as to allow an actual check of other titles' }
    pm1.save!
    pm2 = create_project_media project: p, quote: "Blah2", team: @team
    pm2.save!
    Bot::Alegre.stubs(:get_merged_items_with_similar_text).with(pm2, Bot::Alegre.get_threshold_for_query('text', pm2)).returns({pm1.id => {score: 0.99, context: {"blah" => 1}}})
    Bot::Alegre.stubs(:get_merged_items_with_similar_text).with(pm2, Bot::Alegre.get_threshold_for_query('text', pm2, true)).returns({})
    assert_equal Bot::Alegre.get_similar_items(pm2), {pm1.id=>{:score=>0.99, :context => {"blah" => 1}, :relationship_type=>{:source=>"suggested_sibling", :target=>"suggested_sibling"}}}
    Bot::Alegre.unstub(:get_merged_items_with_similar_text)
  end

  test "should not return matches for blank cases" do
    p = create_project
    pm1 = create_project_media project: p, quote: "Blah", team: @team
    pm1.analysis = { title: 'This is a long enough Title so as to allow an actual check of other titles' }
    pm1.save!
    pm2 = create_project_media project: p, quote: "Blah2", team: @team
    pm2.save!
    pm3 = create_project_media project: p, media: Blank.new
    pm3.save!
    Bot::Alegre.stubs(:get_merged_items_with_similar_text).with(pm3, Bot::Alegre.get_threshold_for_query('text', pm3)).returns({pm1.id => {score: 0.99, context: {"blah" => 1}}, pm2.id => {score: 0.99, context: {"blah" => 1}}})
    assert_equal Bot::Alegre.get_similar_items(pm3), {}
    Bot::Alegre.unstub(:get_merged_items_with_similar_text)
  end

  test "should add relationships" do
    p = create_project
    pm1 = create_project_media project: p, is_image: true
    pm2 = create_project_media project: p, is_image: true
    pm3 = create_project_media project: p, is_image: true
    assert_difference 'Relationship.count' do
      response = Bot::Alegre.add_relationships(pm3, {pm2.id => {score: 1, relationship_type: Relationship.confirmed_type}})
    end
    r = Relationship.last
    assert_equal pm3, r.target
    assert_equal pm2, r.source
    assert_equal r.weight, 1
  end

  test "should fail to add relationships" do
    p = create_project
    pm1 = create_project_media project: p, is_image: true
    pm2 = create_project_media project: p, is_image: true
    pm3 = create_project_media project: p, is_image: true
    Relationship.all.class.any_instance.stubs(:all).returns([Relationship.new(source_id: 1), Relationship.new(source_id: 2)])
    response = Bot::Alegre.add_relationships(pm3, {pm2.id => {score: 1, relationship_type: Relationship.confirmed_type}})
    assert_equal response, false
    Relationship.all.class.any_instance.unstub(:all)
  end

  test "resets relationship transitively" do
    p = create_project
    pm1 = create_project_media project: p, is_image: true
    pm2 = create_project_media project: p, is_image: true
    pm3 = create_project_media project: p, is_image: true
    Relationship.all.class.any_instance.stubs(:all).returns([Relationship.new(source_id: 1), Relationship.new(source_id: 2)])
    response = Bot::Alegre.add_relationships(pm3, {pm2.id => {score: 1, relationship_type: Relationship.confirmed_type}})
    assert_equal response, false
    Relationship.all.class.any_instance.unstub(:all)
  end

  test "should get similar items" do
    p = create_project
    pm1 = create_project_media project: p
    Bot::Alegre.stubs(:matching_model_to_use).with(pm1.team_id).returns(Bot::Alegre::ELASTICSEARCH_MODEL)
    response = Bot::Alegre.get_similar_items(pm1)
    assert_equal response.class, Hash
    Bot::Alegre.unstub(:matching_model_to_use)
  end

  test "should get empty similar items when not text or image" do
    p = create_project
    pm1 = create_project_media project: p
    pm1.media.type = "Bloop"
    response = Bot::Alegre.get_similar_items(pm1)
    assert_equal response.class, Hash
  end

  test "should not return a malformed hash" do
    Bot::Alegre.stubs(:request_api).returns({"result"=> [{
      "_index"=>"alegre_similarity",
      "_type"=>"_doc",
      "_id"=>"i8XY53UB36CYclMPF5wC",
      "_score"=>100.60148,
      "_source"=> {
        "content"=>
          "Bautista began his wrestling career in 1999, and signed with the World Wrestling Federation (WWF, now WWE) in 2000. From 2002 to 2010, he gained fame under the ring name Batista and became a six-time world champion by winning the World Heavyweight Championship four times and the WWE Championship twice. He holds the record for the longest reign as World Heavyweight Champion at 282 days and has also won the World Tag Team Championship three times (twice with Ric Flair and once with John Cena) and the WWE Tag Team Championship once (with Rey Mysterio). He was the winner of the 2005 Royal Rumble match and went on to headline WrestleMania 21, one of the top five highest-grossing pay-per-view events in professional wrestling history",
        "context"=>{"team_id"=>1692, "field"=>"title", "project_media_id"=>1932}
      }
    }, {
      "_index"=>"alegre_similarity",
      "_type"=>"_doc",
      "_id"=>"tMXj53UB36CYclMPXp14",
      "_score"=>100.60148,
      "_source"=>
       {
         "content"=>
           "Bautista began his wrestling career in 1999, and signed with the World Wrestling Federation (WWF, now WWE) in 2000. From 2002 to 2010, he gained fame under the ring name Batista and became a six-time world champion by winning the World Heavyweight Championship four times and the WWE Championship twice. He holds the record for the longest reign as World Heavyweight Champion at 282 days and has also won the World Tag Team Championship three times (twice with Ric Flair and once with John Cena) and the WWE Tag Team Championship once (with Rey Mysterio). He was the winner of the 2005 Royal Rumble match and went on to headline WrestleMania 21, one of the top five highest-grossing pay-per-view events in professional wrestling history",
         "context"=>{"team_id"=>1692, "field"=>"title", "project_media_id"=>1932}
    }}]})
    response = Bot::Alegre.get_similar_items_from_api("blah", {})
    assert_equal response.class, Hash
    assert_equal response, {1932=>{:score=>100.60148, :context=>{"team_id"=>1692, "field"=>"title", "project_media_id"=>1932}, :model=>nil}}
    Bot::Alegre.unstub(:request_api)
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
    response = Bot::Alegre.get_similar_items(pm)
    assert_equal response.class, Hash
    Bot::Alegre.unstub(:request_api)
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
    response = Bot::Alegre.get_items_with_similar_text(pm, ['title'], [{key: 'text_elasticsearch_suggestion_threshold', model: 'elasticsearch', value: 0.7, automatic: false}], 'blah')
    assert_equal response.class, Hash
    Bot::Alegre.unstub(:request_api)
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
    Bot::Alegre.stubs(:request_api).returns({"result" => [{
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
    Bot::Alegre.unstub(:request_api)
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
    p = create_project
    pm = create_project_media project: p, media: create_uploaded_video
    pm.media.type = "UploadedVideo"
    pm.media.save!
    pm.save!
    Bot::Alegre.stubs(:request_api).returns(true)
    assert Bot::Alegre.send_to_media_similarity_index(pm)
    Bot::Alegre.unstub(:request_api)
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

  test "should return an alegre indexing model" do
    create_verification_status_stuff
    RequestStore.store[:skip_cached_field_update] = false
    pm = create_project_media quote: "Blah", team: @team
    pm.analysis = { content: 'Description 1' }
    pm.save!
    BotUser.stubs(:alegre_user).returns(User.new)
    TeamBotInstallation.stubs(:find_by_team_id_and_user_id).returns(TeamBotInstallation.new)
    assert_equal Bot::Alegre.indexing_model_to_use(pm), Bot::Alegre.default_model
    BotUser.unstub(:alegre_user)
    TeamBotInstallation.unstub(:find_by_team_id_and_user_id)
  end



end