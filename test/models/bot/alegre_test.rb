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
    Bot::Alegre.unstub(:media_file_url)
  end

  test "should return an alegre matching model" do
    create_verification_status_stuff
    RequestStore.store[:skip_cached_field_update] = false
    pm = create_project_media quote: "Blah", team: @team
    pm.analysis = { content: 'Description 1' }
    pm.save!
    BotUser.stubs(:alegre_user).returns(User.new)
    TeamBotInstallation.stubs(:find_by_team_id_and_user_id).returns(TeamBotInstallation.new)
    assert_equal Bot::Alegre.matching_model_to_use(pm.team_id), Bot::Alegre.default_matching_model
    BotUser.unstub(:alegre_user)
    TeamBotInstallation.unstub(:find_by_team_id_and_user_id)
  end

  test "should capture error when failing to call service" do
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
       WebMock.stub_request(:post, 'http://alegre/text/langid/').to_return(body: 'bad JSON response')
       WebMock.stub_request(:post, 'http://alegre/text/langid/').to_return(body: 'bad JSON response')
       WebMock.stub_request(:post, 'http://alegre/text/similarity/').to_return(body: 'success')
       WebMock.stub_request(:post, 'http://alegre/similarity/sync/text').to_return(body: 'success')
       WebMock.stub_request(:post, 'http://alegre/similarity/async/text').to_return(body: 'success')
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
    Bot::Alegre.add_relationships(pm1, {pm3.id => {score: 1, relationship_type: Relationship.confirmed_type, context: {"blah" => 1}, source_field: pm1.media.type, target_field: pm2.media.type}})
    r = Relationship.last
    assert_equal pm1, r.target
    assert_equal pm3, r.source
    assert_not_nil r.user_id
    assert_equal @bot.id, r.user_id
  end

  test "should add relationships as confirmed when parent and score are confirmed" do
    p = create_project
    pm1 = create_project_media project: p, is_image: true
    pm2 = create_project_media project: p, is_image: true
    pm3 = create_project_media project: p, is_image: true
    
    create_relationship source_id: pm3.id, target_id: pm2.id, relationship_type: Relationship.confirmed_type
    assert_difference 'Relationship.count' do
      Bot::Alegre.add_relationships(pm1, {pm2.id => {score: 1, relationship_type: Relationship.confirmed_type, context: {"blah" => 1}, source_field: pm1.media.type, target_field: pm2.media.type}, pm3.id => {score: 1, relationship_type: Relationship.suggested_type, context: {"blah" => 1}, source_field: pm1.media.type, target_field: pm3.media.type}})
    end
    r = Relationship.last
    assert_equal pm1, r.target
    assert_equal pm3, r.source
    assert_equal r.weight, 1
    assert_equal Relationship.confirmed_type, r.relationship_type
    # should confirm/restore target if source is confirmed
    pm4 = create_project_media project: p
    pm5 = create_project_media project: p, archived: CheckArchivedFlags::FlagCodes::UNCONFIRMED
    assert_difference 'Relationship.count' do
      Bot::Alegre.add_relationships(pm5, {pm4.id => {score: 1, relationship_type: Relationship.suggested_type, context: {"blah" => 1}, source_field: pm5.media.type, target_field: pm4.media.type}})
    end
    assert_equal CheckArchivedFlags::FlagCodes::NONE, pm5.reload.archived
  end

  test "should unarchive item after running" do
    WebMock.stub_request(:delete, 'http://alegre/text/similarity/').to_return(body: {success: true}.to_json)
    WebMock.stub_request(:post, 'http://alegre/similarity/async/text').to_return(body: {results: []}.to_json)
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      WebMock.stub_request(:delete, 'http://alegre/text/similarity/').to_return(status: 200, body: '{}')
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
    pm1 = create_project_media quote: "for testing short text", team: @team
    pm2 = create_project_media quote: "testing short text", team: @team
    pm2.analysis = { content: 'short text' }
    Bot::Alegre.stubs(:request).returns({
      "result" => [
        {
          "_score" => 26.493948,
          "_source" => {
            "context"=> { "field" => "title", "team_id"=> pm1.team_id.to_s, "project_media_id" => pm1.id.to_s, "has_custom_id" => true }
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
    Bot::Alegre.stubs(:request).returns({
      "result" => [
        {
          "_score" => 26.493948,
          "_source" => {
            "context"=> { "field" => "title", "team_id" => pm3.team_id.to_s, "project_media_id" => pm3.id.to_s, "has_custom_id" => true }
          }
        }
      ]
    })
    assert_difference 'Relationship.count' do
      result = Bot::Alegre.relate_project_media_to_similar_items(pm4)
    end
    r = Relationship.last
    assert_equal Relationship.confirmed_type, r.relationship_type
    Bot::Alegre.unstub(:request)
  end

  test "should set similarity relationship based on date threshold" do
    RequestStore.store[:skip_cached_field_update] = false
    create_verification_status_stuff
    pm1 = create_project_media quote: "This is also a long enough Title so as to allow an actual check of other titles", team: @team
    pm2 = create_project_media quote: "This is also a long enough Title so as to allow an actual check of other titles 2", team: @team
    Bot::Alegre.stubs(:request).returns({
      "result" => [
        {
          "_score" => 26.493948,
          "_source" => {
            "context"=> { "field" => "title", "team_id"=> pm1.team_id.to_s, "project_media_id" => pm1.id.to_s, "has_custom_id" => true }
          }
        }
      ]
    })
    # Set the TeamBotInstallation (tbi) for Alegre so that a query
    # matched to an item seen more than 1 month ago is downgraded to suggestion
    tbi = Bot::Alegre.get_alegre_tbi(@team.id)
    tbi.set_date_similarity_threshold_enabled = true
    tbi.set_similarity_date_threshold("1")
    tbi.save!

    # First verify a confirmed_type relationship is not downgraded.
    # because last_seen will be now and not more than one month ago.
    assert_difference 'Relationship.count' do
      result = Bot::Alegre.relate_project_media_to_similar_items(pm2)
    end
    r = Relationship.last
    assert_equal Relationship.confirmed_type, r.relationship_type
    r.destroy!

    # Now stub last_seen so that confirmed_type is downgraded to suggest_type
    # because it is more than tbi.similarity_date_threshold months old
    ProjectMedia.any_instance.stubs(:last_seen).returns(Time.now - 2.months)
    assert_difference 'Relationship.count' do
      result = Bot::Alegre.relate_project_media_to_similar_items(pm2)
    end
    r = Relationship.last
    assert_equal Relationship.suggested_type, r.relationship_type
    Bot::Alegre.unstub(:request)
    ProjectMedia.any_instance.unstub(:last_seen)
  end

  test "should index report data" do
    WebMock.stub_request(:delete, 'http://alegre:3100/text/similarity/').to_return(body: {success: true}.to_json)
    WebMock.stub_request(:post, 'http://alegre:3100/similarity/sync/text').to_return(body: {}.to_json)
    pm = create_project_media team: @team
    assert_nothing_raised do
      publish_report(pm)
    end
  end

  test "should use OCR data for similarity matching" do
    WebMock.stub_request(:post, 'http://alegre:3100/text/langid/').with(body: { text: 'Foo bar' }.to_json).to_return(status: 200, body: '{}')
    WebMock.stub_request(:post, 'http://alegre:3100/similarity/sync/text').to_return(status: 200, body: '{}')
    pm = create_project_media team: @team
    pm2 = create_project_media team: @team
    Bot::Alegre.stubs(:get_items_with_similar_description).returns({ pm2.id => {:score=>0.9, :context=>{"team_id"=>@team.id, "field"=>"original_description", "project_media_id"=>pm2.id, "has_custom_id"=>true}, :model=>"elasticsearch"} })
    assert_difference 'Relationship.count' do
      create_dynamic_annotation annotation_type: 'extracted_text', annotated: pm, set_fields: { text: 'Foo bar' }.to_json
    end
    Bot::Alegre.unstub(:get_items_with_similar_description)
  end

  test "should use OCR data for similarity matching 2" do
    pm = create_project_media team: @team, media: create_uploaded_image
    pm2 = create_project_media team: @team, media: create_uploaded_image
    Bot::Alegre.stubs(:request).returns({"result"=> [{
      "_index"=>"alegre_similarity",
      "_type"=>"_doc",
      "_id"=>"i8XY53UB36CYclMPF5wC",
      "_score"=>100.60148,
      "_source"=> {
        "content"=>
          "Bautista began his wrestling career in 1999, and signed with the World Wrestling Federation (WWF, now WWE) in 2000. From 2002 to 2010, he gained fame under the ring name Batista and became a six-time world champion by winning the World Heavyweight Championship four times and the WWE Championship twice. He holds the record for the longest reign as World Heavyweight Champion at 282 days and has also won the World Tag Team Championship three times (twice with Ric Flair and once with John Cena) and the WWE Tag Team Championship once (with Rey Mysterio). He was the winner of the 2005 Royal Rumble match and went on to headline WrestleMania 21, one of the top five highest-grossing pay-per-view events in professional wrestling history",
        "context"=>{"team_id"=>@team.id, "field"=>"title", "project_media_id"=>pm2.id}
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
         "context"=>{"team_id"=>@team.id, "field"=>"title", "extracted_text"=>pm2.id}
    }}]})
    assert_difference 'Relationship.count' do
      create_dynamic_annotation annotation_type: 'extracted_text', annotated: pm, set_fields: { text: 'Foo bar test' }.to_json
    end
    r = Relationship.last
    assert_equal r.model, "elasticsearch"
    assert_equal Bot::Alegre.get_pm_type(r.source), "image"
    assert_equal Bot::Alegre.get_pm_type(r.target), "image"
    Bot::Alegre.unstub(:request)
  end


  # This test to reproduce errbit error CHECK-1218
  test "should match to existing parent" do
    WebMock.stub_request(:post, 'http://alegre:3100/text/langid/').with(body: { text: 'Foo bar' }.to_json).to_return(status: 200, body: '{}')
    WebMock.stub_request(:post, 'http://alegre:3100/similarity/sync/text').to_return(status: 200, body: '{}')
    pm_s = create_project_media team: @team
    pm = create_project_media team: @team
    pm2 = create_project_media team: @team
    create_relationship source_id: pm_s.id, target_id: pm2.id, relationship_type: Relationship.confirmed_type
    Bot::Alegre.stubs(:get_items_with_similar_description).returns({ pm2.id => {:score=>0.9, :context=>{"team_id"=>@team.id, "field"=>"original_description", "project_media_id"=>pm2.id, "has_custom_id"=>true}, :model=>"elasticsearch"} })
    assert_difference 'Relationship.count' do
      create_dynamic_annotation annotation_type: 'extracted_text', annotated: pm, set_fields: { text: 'Foo bar' }.to_json
    end
    relationship = Relationship.last
    assert_equal pm_s.id, relationship.source_id
    assert_equal pm2.id, relationship.original_source_id
    Bot::Alegre.unstub(:get_items_with_similar_description)
  end

  test "should use transcription data for similarity matching" do
    WebMock.stub_request(:post, 'http://alegre:3100/text/langid/').with(body: { text: 'Foo bar' }.to_json).to_return(status: 200, body: '{}')
    WebMock.stub_request(:delete, 'http://alegre:3100/text/similarity/').to_return(status: 200, body: '{}')
    WebMock.stub_request(:post, 'http://alegre:3100/similarity/sync/text').to_return(status: 200, body: '{}')
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
    pm = create_project_media team: @team
    pm2 = create_project_media team: @team
    Bot::Alegre.stubs(:get_items_with_similar_description).returns({ pm2.id => {:score=>0.9, :context=>{"team_id"=>@team.id, "field"=>"original_description", "project_media_id"=>pm2.id, "has_custom_id"=>true}, :model=>"elasticsearch"}})
    data = { 'job_status' => 'COMPLETED', 'transcription' => 'Foo bar' }
    a = create_dynamic_annotation annotation_type: 'transcription', annotated: pm, set_fields: { job_name: '0c481e87f2774b1bd41a0a70d9b70d11', last_response: data }.to_json
    assert_difference 'Relationship.count' do
      a = Dynamic.find(a.id)
      a.set_fields = { text: data['transcription'] }.to_json
      a.save!
    end
    Bot::Alegre.unstub(:get_items_with_similar_description)
  end

  test "should check existing relationship before create a new one" do
    WebMock.stub_request(:post, 'http://alegre:3100/similarity/sync/text').to_return(status: 200, body: '{}')
    WebMock.stub_request(:post, 'http://alegre:3100/text/langid/').with(body: { text: 'Foo bar' }.to_json).to_return(status: 200, body: '{}')
    pm = create_project_media team: @team
    pm2 = create_project_media team: @team
    pm3 = create_project_media team: @team
    pm4 = create_project_media team: @team
    r = create_relationship source_id: pm2.id, target_id: pm.id, relationship_type: Relationship.suggested_type
    Bot::Alegre.stubs(:get_items_with_similar_description).returns({pm2.id => {:score=>700, :context=>{"team_id"=>@team.id, "field"=>"original_description", "project_media_id"=>pm2.id, "has_custom_id"=>true}, :model=>"elasticsearch"}, 779761 => {:score=>602.4235, :context=>{"team_id"=>2080, "field"=>"original_description", "project_media_id"=>pm2.id, "has_custom_id"=>true}, :model=>"elasticsearch"}})
    assert_no_difference 'Relationship.count' do
      create_dynamic_annotation annotation_type: 'extracted_text', annotated: pm, set_fields: { text: 'Foo bar' }.to_json
    end
    r = Relationship.where(source_id: pm2.id, target_id: pm.id).last
    assert_equal r.relationship_type, Relationship.suggested_type
    assert_nothing_raised do
      r.relationship_type = Relationship.confirmed_type
      r.save!
    end
    r2 = create_relationship source_id: pm4.id, target_id: pm3.id, relationship_type: Relationship.confirmed_type
    Bot::Alegre.stubs(:get_items_with_similar_description).returns({ pm4.id => {:score=>0.9, :context=>{"team_id"=>@team.id, "field"=>"original_description", "project_media_id"=>pm2.id, "has_custom_id"=>true}, :model=>"elasticsearch"} })
    assert_no_difference 'Relationship.count' do
      create_dynamic_annotation annotation_type: 'extracted_text', annotated: pm3, set_fields: { text: 'Foo bar' }.to_json
    end
    r = Relationship.where(source_id: pm4.id, target_id: pm3.id).last
    assert_equal r.relationship_type, Relationship.confirmed_type
    Bot::Alegre.unstub(:get_items_with_similar_description)
    # should confirm existing relation if the new one type == confirmed
    pm = create_project_media team: @team
    pm2 = create_project_media team: @team
    r = create_relationship source_id: pm2.id, target_id: pm.id, relationship_type: Relationship.suggested_type
    assert_no_difference 'Relationship.count' do
      Bot::Alegre.create_relationship(pm2, pm, {pm2.id => {score: 0.9, context: {"blah" => 1}}}, Relationship.confirmed_type)
    end
    assert_equal r.reload.relationship_type, Relationship.confirmed_type
  end

end
