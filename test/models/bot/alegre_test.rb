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

  test "should link similar images, get flags and extract text" do
    ft = create_field_type field_type: 'image_path', label: 'Image Path'
    at = create_annotation_type annotation_type: 'reverse_image', label: 'Reverse Image'
    create_field_instance annotation_type_object: at, name: 'reverse_image_path', label: 'Reverse Image', field_type_object: ft, optional: false
    Bot::Alegre.unstub(:request_api)
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      WebMock.disable_net_connect! allow: /#{CheckConfig.get('elasticsearch_host')}|#{CheckConfig.get('storage_endpoint')}/
      WebMock.stub_request(:post, 'http://alegre/text/similarity/').to_return(body: 'success')
      WebMock.stub_request(:delete, 'http://alegre/text/similarity/').to_return(body: {success: true}.to_json)
      WebMock.stub_request(:get, 'http://alegre/text/similarity/').to_return(body: {success: true}.to_json)
      WebMock.stub_request(:post, 'http://alegre/image/similarity/').to_return(body: {
        "success": true
      }.to_json)
      WebMock.stub_request(:get, 'http://alegre/image/similarity/').to_return(body: {
        "result": []
      }.to_json)
      WebMock.stub_request(:get, 'http://alegre/image/classification/').with({ query: { uri: 'some/path' } }).to_return(body: {
        "result": valid_flags_data
      }.to_json)
      WebMock.stub_request(:get, 'http://alegre/image/ocr/').with({ query: { url: 'some/path' } }).to_return(body: {
        "text": "Foo bar"
      }.to_json)
      WebMock.stub_request(:post, 'http://alegre/image/similarity/').to_return(body: 'success')

      # Similarity
      pm1 = create_project_media team: @pm.team, media: create_uploaded_image
      Bot::Alegre.stubs(:media_file_url).with(pm1).returns("some/path")
      assert Bot::Alegre.run({ data: { dbid: pm1.id }, event: 'create_project_media' })
      Bot::Alegre.unstub(:media_file_url)
      WebMock.stub_request(:get, 'http://alegre/image/similarity/').to_return(body: {
        "result": [
          {
            "id": 1,
            "sha256": "1782b1d1993fcd9f6fd8155adc6009a9693a8da7bb96d20270c4bc8a30c97570",
            "phash": 17399941807326929,
            "url": "https:\/\/www.gstatic.com\/webp\/gallery3\/1.png",
            "context": [{
              "team_id": pm1.team.id.to_s,
              "project_media_id": pm1.id.to_s
            }],
            "score": 0
          }
        ]
      }.to_json)
      pm2 = create_project_media team: @pm.team, media: create_uploaded_image
      response = {pm1.id => 0}
      Bot::Alegre.stubs(:media_file_url).with(pm2).returns("some/path")
      assert_equal response, Bot::Alegre.get_items_with_similarity('image', pm2, Bot::Alegre.get_threshold_for_query('image', pm2))

      # Flags
      Bot::Alegre.unstub(:media_file_url)
      WebMock.stub_request(:get, 'http://alegre/image/classification/').to_return(body: {
        "result": valid_flags_data
      }.to_json)
      pm3 = create_project_media team: @pm.team, media: create_uploaded_image
      Bot::Alegre.stubs(:media_file_url).with(pm3).returns("some/path")
      assert Bot::Alegre.run({ data: { dbid: pm3.id }, event: 'create_project_media' })
      assert_not_nil pm3.get_annotations('flag').last
      Bot::Alegre.unstub(:media_file_url)

      # Text extraction
      Bot::Alegre.unstub(:media_file_url)
      pm4 = create_project_media team: @pm.team, media: create_uploaded_image
      Bot::Alegre.stubs(:media_file_url).with(pm4).returns("some/path")
      assert Bot::Alegre.run({ data: { dbid: pm4.id }, event: 'create_project_media' })
      extracted_text_annotation = pm4.get_annotations('extracted_text').last
      assert_equal 'Foo bar', extracted_text_annotation.data['text']
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
    assert_equal Bot::Alegre.extract_project_medias_from_context({"_score" => 2, "_source" => {"context" => {"project_media_id" => 1}}}), {1=>2}
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

  test "should relate project media to similar items as video" do
    p = create_project
    pm1 = create_project_media team: @pm.team
    pm1 = create_project_media project: p, media: create_uploaded_video
    pm2 = create_project_media project: p, media: create_uploaded_video
    pm3 = create_project_media project: p, media: create_uploaded_video
    create_relationship source_id: pm2.id, target_id: pm1.id
    Bot::Alegre.stubs(:request_api).returns({
      "result" => [
        {
          "context"=>[
            {"team_id"=>pm1.team.id.to_s, "project_media_id"=>pm1.id.to_s}
          ],
          "score"=>"0.983167",
          "filename"=>"/app/persistent_disk/blah/12342.tmk"
        },
        {
          "context"=>[
            {"team_id"=>pm2.team.id.to_s, "project_media_id"=>pm2.id.to_s}
          ],
          "score"=>"0.983167",
          "filename"=>"/app/persistent_disk/blah/12343.tmk"
        }
      ]
    })
    Bot::Alegre.stubs(:media_file_url).with(pm3).returns("some/path")
    assert_difference 'Relationship.count' do
      Bot::Alegre.relate_project_media_to_similar_items(pm3)
    end
    r = Relationship.last
    assert_equal pm3, r.target
    assert_equal pm1, r.source
    assert_equal r.weight, 0.983167
    Bot::Alegre.unstub(:request_api)
    Bot::Alegre.unstub(:media_file_url)
  end

  test "should relate project media to similar items as audio" do
    p = create_project
    pm1 = create_project_media team: @pm.team
    pm1 = create_project_media project: p, media: create_uploaded_audio
    pm2 = create_project_media project: p, media: create_uploaded_audio
    pm3 = create_project_media project: p, media: create_uploaded_audio
    create_relationship source_id: pm2.id, target_id: pm1.id
    Bot::Alegre.stubs(:request_api).returns({
      "result" => [
        {
          "id" => 1,
          "doc_id" => "blah",
          "hash_value" => "0101",
          "url" => "https://foo.com/bar.wav",
          "context"=>[
            {"team_id"=>pm1.team.id.to_s, "project_media_id"=>pm1.id.to_s}
          ],
          "score"=>"0.983167",
        },
        {
          "id" => 2,
          "doc_id" => "blah2",
          "hash_value" => "0111",
          "url" => "https://foo.com/baz.wav",
          "context"=>[
            {"team_id"=>pm2.team.id.to_s, "project_media_id"=>pm2.id.to_s}
          ],
          "score"=>"0.983167",
        }
      ]
    })
    Bot::Alegre.stubs(:media_file_url).with(pm3).returns("some/path")
    assert_difference 'Relationship.count' do
      Bot::Alegre.relate_project_media_to_similar_items(pm3)
    end
    r = Relationship.last
    assert_equal pm3, r.target
    assert_equal pm1, r.source
    assert_equal r.weight, 0.983167
    Bot::Alegre.unstub(:request_api)
    Bot::Alegre.unstub(:media_file_url)
  end

  test "should relate project media to similar items" do
    p = create_project
    pm1 = create_project_media project: p, media: create_uploaded_image
    pm2 = create_project_media project: p, media: create_uploaded_image
    pm3 = create_project_media project: p, media: create_uploaded_image
    create_relationship source_id: pm2.id, target_id: pm1.id
    Bot::Alegre.stubs(:request_api).returns({
      "result" => [
        {
          "id" => 1,
          "sha256" => "1782b1d1993fcd9f6fd8155adc6009a9693a8da7bb96d20270c4bc8a30c97570",
          "phash" => 17399941807326929,
          "url" => "https:\/\/www.gstatic.com\/webp\/gallery3\/1.png",
          "context" => [{
            "team_id" => pm2.team.id.to_s,
            "project_media_id" => pm2.id.to_s
          }],
          "score" => 1.0
        }
      ]
    })
    Bot::Alegre.stubs(:media_file_url).with(pm3).returns("some/path")
    assert_difference 'Relationship.count' do
      Bot::Alegre.relate_project_media_to_similar_items(pm3)
    end
    r = Relationship.last
    assert_equal pm3, r.target
    assert_equal pm2, r.source
    assert_equal r.weight, 1
    Bot::Alegre.unstub(:request_api)
    Bot::Alegre.unstub(:media_file_url)
  end

  test "should replace_by when parent is blank" do
    p = create_project
    pm1 = create_project_media project: p, is_image: true
    pm2 = create_project_media project: p, media: Blank.new
    pm3 = create_project_media project: p, media: Blank.new
    response = Bot::Alegre.add_relationships(pm3, {pm2.id => {score: 1, relationship_type: Relationship.confirmed_type}})
    assert_equal response, true
  end

  test "should return matches for non-blank cases" do
    p = create_project
    pm1 = create_project_media project: p, quote: "Blah", team: @team
    pm1.analysis = { title: 'This is a long enough Title so as to allow an actual check of other titles' }
    pm1.save!
    pm2 = create_project_media project: p, quote: "Blah2", team: @team
    pm2.save!
    Bot::Alegre.get_merged_items_with_similar_text(pm2, Bot::Alegre.get_threshold_for_query('text', pm2))
    Bot::Alegre.stubs(:get_merged_items_with_similar_text).with(pm2, Bot::Alegre.get_threshold_for_query('text', pm2)).returns({pm1.id => 0.99})
    Bot::Alegre.stubs(:get_merged_items_with_similar_text).with(pm2, Bot::Alegre.get_threshold_for_query('text', pm2, true)).returns({})
    assert_equal Bot::Alegre.get_similar_items(pm2), {pm1.id=>{:score=>0.99, :relationship_type=>{:source=>"suggested_sibling", :target=>"suggested_sibling"}}}
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
    Bot::Alegre.get_merged_items_with_similar_text(pm3, Bot::Alegre.get_threshold_for_query('text', pm3))
    Bot::Alegre.stubs(:get_merged_items_with_similar_text).with(pm3, Bot::Alegre.get_threshold_for_query('text', pm3)).returns({pm1.id => 0.99, pm2.id => 0.99})
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
    Relationship::ActiveRecord_Relation.any_instance.stubs(:all).returns([Relationship.new(source_id: 1), Relationship.new(source_id: 2)])
    response = Bot::Alegre.add_relationships(pm3, {pm2.id => {score: 1, relationship_type: Relationship.confirmed_type}})
    assert_equal response, false
    Relationship::ActiveRecord_Relation.any_instance.unstub(:all)
  end

  test "resets relationship transitively" do
    p = create_project
    pm1 = create_project_media project: p, is_image: true
    pm2 = create_project_media project: p, is_image: true
    pm3 = create_project_media project: p, is_image: true
    Relationship::ActiveRecord_Relation.any_instance.stubs(:all).returns([Relationship.new(source_id: 1, relationship_type: Relationship.confirmed_type), Relationship.new(source_id: 2)])
    response = Bot::Alegre.add_relationships(pm3, {pm2.id => {score: 1, relationship_type: Relationship.confirmed_type}})
    assert_equal response, false
    Relationship::ActiveRecord_Relation.any_instance.unstub(:all)
  end

  test "should get similar items" do
    p = create_project
    pm1 = create_project_media project: p
    Bot::Alegre.stubs(:matching_model_to_use).with(pm1).returns(Bot::Alegre::ELASTICSEARCH_MODEL)
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
    assert_equal response, {1932=>100.60148}
    Bot::Alegre.unstub(:request_api)
  end

  test "should generate correct text conditions for api request" do
    conditions = Bot::Alegre.similar_texts_from_api_conditions("blah", "elasticsearch", 'true', 1, 'original_title', {value: 0.7, key: 'text_elasticsearch_suggestion_threshold', automatic: false})
    assert_equal conditions, {:text=>"blah", :model=>"elasticsearch", :fuzzy=>true, :context=>{:has_custom_id=>true, :field=>"original_title", :team_id=>1}, :threshold=>0.7}
  end

  test "should generate correct media conditions for api request" do
    conditions = Bot::Alegre.similar_media_content_from_api_conditions(1, "https://upload.wikimedia.org/wikipedia/en/7/7d/Lenna_%28test_image%29.png", {value: 0.7, key: 'image_hash_suggestion_threshold', automatic: false})
    assert_equal conditions, {:url=>"https://upload.wikimedia.org/wikipedia/en/7/7d/Lenna_%28test_image%29.png", :context=>{:has_custom_id=>true, :team_id=>1}, :threshold=>0.7}
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
    Bot::Alegre.stubs(:matching_model_to_use).with(pm).returns(Bot::Alegre::ELASTICSEARCH_MODEL)
    Bot::Alegre.stubs(:matching_model_to_use).with(pm2).returns(Bot::Alegre::ELASTICSEARCH_MODEL)
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
    response = Bot::Alegre.get_items_with_similar_text(pm, 'title', {key: 'text_elasticsearch_suggestion_threshold', value: 0.7, automatic: false}, 'blah')
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
    response = Bot::Alegre.get_items_with_similar_text(pm, 'title', {key: 'text_elasticsearch_matching_threshold', value: 0.7, automatic: true}, 'blah')
    assert_equal response.class, Hash
    assert_not_empty response
    Bot::Alegre.unstub(:request_api)
  end


  test "should get items with similar text" do
    pm = create_project_media quote: "Blah"
    Bot::Alegre.stubs(:get_items_with_similar_title).returns({1 => 0.2, 2 => 0.3})
    Bot::Alegre.stubs(:get_items_with_similar_description).returns({2 => 0.2, 3 => 0.3})
    assert_equal Bot::Alegre.get_merged_items_with_similar_text(pm, 0.0), {1 => 0.2, 2 => 0.3, 3 => 0.3}
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
  end

  test "should pass through the send to description similarity index call" do
    create_verification_status_stuff
    RequestStore.store[:skip_cached_field_update] = false
    pm = create_project_media quote: "Blah", team: @team
    pm.analysis = { content: 'Description 1' }
    pm.save!
    Bot::Alegre.stubs(:request_api).returns(true)
    assert Bot::Alegre.send_field_to_similarity_index(pm, 'description')
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
    Bot::Alegre.stubs(:matching_model_to_use).with(pm).returns(Bot::Alegre::MEAN_TOKENS_MODEL)
    response = Bot::Alegre.get_items_with_similar_title(pm, {key: 'text_elasticsearch_suggestion_threshold', value: 0.1, automatic: false})
    assert_equal response.class, Hash
    Bot::Alegre.unstub(:request_api)
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

  test "should return an alegre matching model" do
    create_verification_status_stuff
    RequestStore.store[:skip_cached_field_update] = false
    pm = create_project_media quote: "Blah", team: @team
    pm.analysis = { content: 'Description 1' }
    pm.save!
    BotUser.stubs(:alegre_user).returns(User.new)
    TeamBotInstallation.stubs(:find_by_team_id_and_user_id).returns(TeamBotInstallation.new)
    assert_equal Bot::Alegre.matching_model_to_use(pm), Bot::Alegre.default_matching_model
    BotUser.unstub(:alegre_user)
    TeamBotInstallation.unstub(:find_by_team_id_and_user_id)
  end

  test "should capture error when failing to call service" do
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
       WebMock.stub_request(:get, 'http://alegre/text/langid/').to_return(body: 'bad JSON response')
       WebMock.stub_request(:post, 'http://alegre/text/similarity/').to_return(body: 'success')
       WebMock.disable_net_connect! allow: /#{CheckConfig.get('elasticsearch_host')}|#{CheckConfig.get('storage_endpoint')}/
       Bot::Alegre.any_instance.stubs(:get_language).raises(RuntimeError)
       assert_nothing_raised do
         Bot::Alegre.run('test')
       end
       Bot::Alegre.any_instance.unstub(:get_language)
       assert_nothing_raised do
         assert Bot::Alegre.run({ data: { dbid: @pm.id }, event: 'create_project_media' })
       end
       Net::HTTP.any_instance.stubs(:request).raises(StandardError)
       assert_nothing_raised do
         assert Bot::Alegre.run({ data: { dbid: @pm.id }, event: 'create_project_media' })
       end
       Net::HTTP.any_instance.unstub(:request)
     end
  end

  test "should set user_id on relationships" do
    p = create_project
    pm1 = create_project_media project: p
    pm2 = create_project_media project: p
    pm3 = create_project_media project: p
    create_relationship source_id: pm3.id, target_id: pm2.id
    Bot::Alegre.add_relationships(pm1, {pm3.id => {score: 1, relationship_type: Relationship.confirmed_type}})
    r = Relationship.last
    assert_equal pm1, r.target
    assert_equal pm3, r.source
    assert_not_nil r.user_id
    assert_equal @bot.id, r.user_id
  end

  test "should unarchive item after running" do
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      pm = create_project_media
      pm.archived = CheckArchivedFlags::FlagCodes::PENDING_SIMILARITY_ANALYSIS
      pm.save!
      assert_equal CheckArchivedFlags::FlagCodes::PENDING_SIMILARITY_ANALYSIS, pm.reload.archived
      Bot::Alegre.run({ data: { dbid: pm.id }, event: 'create_project_media' })
      assert_equal CheckArchivedFlags::FlagCodes::NONE, pm.reload.archived
    end
  end

  test "should correctly assert has alegre bot installed" do
    t = create_team
    TeamUser.where(team_id: t.id).delete_all
    assert !Bot::Alegre.team_has_alegre_bot_installed?(t)
    @bot.install_to!(t)
    assert Bot::Alegre.team_has_alegre_bot_installed?(t)
  end

  test "should not add relationship" do
    assert !Bot::Alegre.add_relationship(create_project_media, {}, create_project_media)
  end

  test "should add short text as suggestions" do
    create_verification_status_stuff
    # Relation should be suggested if all fields size <= threshold
    p = create_project team: @team
    pm1 = create_project_media project: p, quote: "for testing short text", team: @team
    pm2 = create_project_media project: p, quote: "testing short text", team: @team
    pm2.analysis = { content: 'short text' }
    Bot::Alegre.stubs(:request_api).returns({
      "result" => [
        {
          "_score" => 26.493948,
          "_source" => {
            "context"=> { "team_id"=> pm1.team_id.to_s, "project_media_id" => pm1.id.to_s, "has_custom_id" => true }
          }
        }
      ]
    })
    assert_difference 'Relationship.count' do
      result = Bot::Alegre.relate_project_media_to_similar_items(pm2)
    end
    r = Relationship.last
    assert_equal Relationship.suggested_type, r.relationship_type
    # Relation should be confirmed if at least one field size > threshold
    pm3 = create_project_media project: p, quote: 'This is also a long enough title', team: @team
    pm4 = create_project_media project: p, quote: 'This is also a long enough title so as to allow an actual check of other titles', team: @team
    Bot::Alegre.stubs(:request_api).returns({
      "result" => [
        {
          "_score" => 26.493948,
          "_source" => {
            "context"=> { "team_id"=> pm3.team_id.to_s, "project_media_id" => pm3.id.to_s, "has_custom_id" => true }
          }
        }
      ]
    })
    assert_difference 'Relationship.count' do
      result = Bot::Alegre.relate_project_media_to_similar_items(pm4)
    end
    r = Relationship.last
    assert_equal Relationship.confirmed_type, r.relationship_type
    Bot::Alegre.unstub(:request_api)
  end

  test "should set similarity relationship based on date threshold" do
    create_verification_status_stuff
    p = create_project team: @team
    pm1 = create_project_media project: p, quote: "This is also a long enough Title so as to allow an actual check of other titles", team: @team
    pm2 = create_project_media project: p, quote: "This is also a long enough Title so as to allow an actual check of other titles 2", team: @team
    Bot::Alegre.stubs(:request_api).returns({
      "result" => [
        {
          "_score" => 26.493948,
          "_source" => {
            "context"=> { "team_id"=> pm1.team_id.to_s, "project_media_id" => pm1.id.to_s, "has_custom_id" => true }
          }
        }
      ]
    })
    assert_difference 'Relationship.count' do
      result = Bot::Alegre.relate_project_media_to_similar_items(pm2)
    end
    r = Relationship.last
    assert_equal Relationship.confirmed_type, r.relationship_type
    pm1.created_at = Time.now - 2.months
    pm1.save!
    tbi = Bot::Alegre.get_alegre_tbi(@team.id)
    tbi.set_date_similarity_threshold_enabled = true
    tbi.set_similarity_date_threshold("1")
    tbi.save!
    r.destroy
    assert_difference 'Relationship.count' do
      result = Bot::Alegre.relate_project_media_to_similar_items(pm2)
    end
    r = Relationship.last
    assert_equal Relationship.suggested_type, r.relationship_type
    Bot::Alegre.unstub(:request_api)
  end

  test "should index report data" do
    WebMock.disable_net_connect! allow: /#{CheckConfig.get('elasticsearch_host')}|#{CheckConfig.get('storage_endpoint')}/
    pm = create_project_media team: @team
    assert_nothing_raised do
      publish_report(pm)
    end
  end

  test "should use OCR data for similarity matching" do
    pm = create_project_media team: @team
    pm2 = create_project_media team: @team
    Bot::Alegre.stubs(:get_items_with_similar_description).returns({ pm2.id => 0.9 })
    assert_difference 'Relationship.count' do
      create_dynamic_annotation annotation_type: 'extracted_text', annotated: pm, set_fields: { text: 'Foo bar' }.to_json
    end
    Bot::Alegre.unstub(:get_items_with_similar_description)
  end
end
