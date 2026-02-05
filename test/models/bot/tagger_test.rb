require_relative '../../test_helper'

class Bot::TaggerTest < ActiveSupport::TestCase
  def setup
    super
    @TaggerBot = create_tagger_bot(name: "tagger", login: "tagger")
    @AlegreBot = create_alegre_bot(name: "alegre", login: "alegre")
    @TaggerBot.approve!
    @AlegreBot.approve!
    team = create_team
    @AlegreBot.install_to!(team)
    @TaggerBot.install_to!(team)
    @team = team
    m = create_claim_media quote: 'I like apples'
    @pm = create_project_media team: team, media: m
    create_flag_annotation_type
    create_extracted_text_annotation_type
    Sidekiq::Testing.inline!
    @auto_tag_prefix = "!"
  end

  def teardown
    super
  end

  def create_tagger_bot(_options = {})
    Bot::Tagger.new(_options)
  end

  test "should get tag text" do
    # Method signature
    # get_tag_text(tag_id,auto_tag_prefix,ignore_autotags)
    pm1 = create_project_media quote: "Rain", team: @team
    tag1 = Tag.create!(annotated:pm1, annotator: BotUser.get_user('tagger'), tag: @auto_tag_prefix+"test")

    pm2 = create_project_media quote: "Rain", team: @team
    tag2 = Tag.create!(annotated:pm2, annotator: BotUser.get_user('tagger'), tag: "test")

    # Get tag text keeping autotags
    # Should return tag with prefix stripped
    assert_equal "test", Bot::Tagger.get_tag_text(tag1[:data][:tag], @auto_tag_prefix, false)

    # Get tag text ignoring autotags
    assert_nil Bot::Tagger.get_tag_text(tag1[:data][:tag], @auto_tag_prefix, true)
    assert_equal "test", Bot::Tagger.get_tag_text(tag2[:data][:tag], @auto_tag_prefix, true)

    # Get tag text for invalid id
    # Should return nil
    assert_nil Bot::Tagger.get_tag_text(-999, @auto_tag_prefix, false)
  end

  test "should tag item" do

  pm1 = create_project_media quote: "rain", team: @team
  Tag.create!(annotated:pm1, annotator: BotUser.get_user('tagger'), tag: "nature")
  pm2 = create_project_media quote: "snow", team: @team
  Tag.create!(annotated:pm2, annotator: BotUser.get_user('tagger'), tag: @auto_tag_prefix+"nature")
  pm3 = create_project_media quote: "soccer", team: @team
  Tag.create!(annotated:pm3, annotator: BotUser.get_user('tagger'), tag: "sport")

  #Stub alegre to return pm1, pm2, and pm3 for any request
  Bot::Alegre.stubs(:get_items_with_similar_text).returns({pm1.id=>pm1,pm2.id=>pm2,pm3.id=>pm3})
  
  #Default settings
  settings = {
    event: "create_project_media",
    team: @team,
    time: Time.now,
    data: {"dbid"=>nil, "title"=>"test", "description"=>"test", "type"=>"Claim"},
    user_id: 5,
    settings: nil
  }

  pm_q1 = create_project_media quote: "test", team: @team
  assert_equal [], pm_q1.get_annotations('tag')
  # Should return nature as the most prominent tag when counting autotags
  settings[:data][:dbid]=pm_q1.id
  settings[:settings]="{\"auto_tag_prefix\":\""+@auto_tag_prefix+"\",\"threshold\":70,\"ignore_autotags\":false,\"minimum_count\":0}"
  Bot::Tagger.run(settings)
  tags = pm_q1.get_annotations('tag').map{|t| Bot::Tagger.get_tag_text(t[:data][:tag], "", false)}
  assert_equal true, tags.include?(@auto_tag_prefix+"nature")
  assert_equal false, tags.include?(@auto_tag_prefix+"sport")

  pm_q2 = create_project_media quote: "test2", team: @team
  assert_equal [], pm_q2.get_annotations('tag')
  # Should return nature and sport as the most prominent tags when ignoring autotags
  settings[:data][:dbid]=pm_q2.id
  settings[:settings]="{\"auto_tag_prefix\":\""+@auto_tag_prefix+"\",\"threshold\":70,\"ignore_autotags\":true,\"minimum_count\":0}"
  Bot::Tagger.run(settings)
  tags = pm_q2.get_annotations('tag').map{|t| Bot::Tagger.get_tag_text(t[:data][:tag], "", false)}
  assert_equal true, tags.include?(@auto_tag_prefix+"nature")
  assert_equal true, tags.include?(@auto_tag_prefix+"sport")
  
  pm_q3 = create_project_media quote: "test3", team: @team
  assert_equal [], pm_q3.get_annotations('tag')
  # No tags should be added when minimum count is above 2
  settings[:data][:dbid]=pm_q3.id
  settings[:settings]="{\"auto_tag_prefix\":\""+@auto_tag_prefix+"\",\"threshold\":70,\"ignore_autotags\":false,\"minimum_count\":3}"
  Bot::Tagger.run(settings) 
  assert_equal [], pm_q3.get_annotations('tag')

  # Restub to not return anything
  Bot::Alegre.unstub(:get_items_with_similar_text)
  Bot::Alegre.stubs(:get_items_with_similar_text).returns({})

  # No tags should be added when there are no neighbours
  settings[:data][:dbid]=pm_q3.id
  settings[:settings]="{\"auto_tag_prefix\":\""+@auto_tag_prefix+"\",\"threshold\":70,\"ignore_autotags\":false,\"minimum_count\":0}"
  Bot::Tagger.run(settings) 
  assert_equal [], pm_q3.get_annotations('tag')

  # Final unstub
  Bot::Alegre.unstub(:get_items_with_similar_text)
  end

  test "should not do anything if Alegre is not configured" do
    stub_configs({ 'alegre_host' => nil }) do
      assert !Bot::Tagger.run('test')
    end
  end

  test "should notify Sentry if an unexpected error happens" do
    CheckSentry.expects(:notify).once
    Bot::Tagger.run('invalid payload')
  end
end
