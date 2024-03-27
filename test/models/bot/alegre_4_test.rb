require_relative '../../test_helper'

class Bot::Alegre4Test < ActiveSupport::TestCase
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
#     create_flag_annotation_type
#     create_extracted_text_annotation_type
#     Sidekiq::Testing.inline!
  end

  def teardown
    super
  end

  test "should not send bad text for langid" do
    text = "platform~1234"
    pm1 = create_project_media team: @team, quote: text
    Bot::Alegre.stubs(:get_language_from_alegre).returns("und")
    assert_equal Bot::Alegre.get_language_from_text(pm1, text), "und"
    Bot::Alegre.unstub(:get_language_from_alegre)
  end

  test "should not send blank text for langid" do
    text = ""
    pm1 = create_project_media team: @team, quote: text
    Bot::Alegre.stubs(:get_language_from_alegre).returns("en")
    assert_equal Bot::Alegre.get_language_from_text(pm1, text), "und"
    Bot::Alegre.unstub(:get_language_from_alegre)
  end

  test "should send text for langid" do
    text = "anything else"
    pm1 = create_project_media team: @team, quote: text
    Bot::Alegre.stubs(:get_language_from_alegre).returns("en")
    assert_equal Bot::Alegre.get_language_from_text(pm1, text), "en"
    Bot::Alegre.unstub(:get_language_from_alegre)
  end

#   test "request should not be called for bad title"
#     Bot::Alegre.stubs(:request).raise("Request method called when it should not be")
#     assert_nothing_raised send_to_text_similarity_index(....) #TODO
#     Bot::Alegre.unstub.stubs(:request)
#   end

   #Also for blank and valid

   #Tests for get_items_from_similar_text
end