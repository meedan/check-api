require_relative '../../test_helper'

class Bot::Alegre4Test < ActiveSupport::TestCase
  def setup
    super
    ft = DynamicAnnotation::FieldType.where(field_type: 'language').last || create_field_type(field_type: 'language', label: 'Language')
    at = create_annotation_type annotation_type: 'language', label: 'Language'
    @field = create_field_instance annotation_type_object: at, name: 'language', label: 'Language', field_type_object: ft, optional: false
    @bot = create_alegre_bot(name: "alegre", login: "alegre")
    @bot.approve!
    p = create_project
    p.team.set_languages = ['en','pt','es']
    p.team.save!
    @bot.install_to!(p.team)
    @team = p.team
  end

  def teardown
    super
  end

  test "should not send bad text for langid" do
    text = "platform-team-2023-25562003"
    pm1 = create_project_media team: @team, quote: text
    Bot::Alegre.stubs(:get_language_from_alegre).returns("en")
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

  test "/text/similarity/ request should be called for good title" do
    text = "platform-team-2023-25562003 with more should pass"
    pm1 = create_project_media team: @team, quote: text
    Bot::Alegre.stubs(:request).raises("Request method called when it should not be")
    assert_raises do
        Bot::Alegre.send_to_text_similarity_index(pm1, create_field_instance, text, Bot::Alegre.item_doc_id(pm1, create_field_instance))
    end
    Bot::Alegre.unstub.stubs(:request)
  end

  test "should send text for langid" do
    text = "platform-team-2023-25562003 with more should pass"
    pm1 = create_project_media team: @team, quote: text
    Bot::Alegre.stubs(:get_language_from_alegre).returns("en")
    assert_equal Bot::Alegre.get_language_from_text(pm1, text), "en"
    Bot::Alegre.unstub(:get_language_from_alegre)
  end

  test "/text/similarity/ request should not be called for bad title" do
    text = "platform-team-2023-25562003"
    pm1 = create_project_media team: @team, quote: text
    Bot::Alegre.stubs(:request).raises("Request method called when it should not be")
    assert_nothing_raised do
        Bot::Alegre.send_to_text_similarity_index(pm1, create_field_instance, text, Bot::Alegre.item_doc_id(pm1, create_field_instance))
    end
    Bot::Alegre.unstub.stubs(:request)
  end

  test "/text/similarity/ request should not be called for URL title" do
    text = "http://meedan.com/@fun/thing?abc=def&hij=123"
    pm1 = create_project_media team: @team, quote: text
    Bot::Alegre.stubs(:request).raises("Request method called when it should not be")
    assert_nothing_raised do
        Bot::Alegre.send_to_text_similarity_index(pm1, create_field_instance, text, Bot::Alegre.item_doc_id(pm1, create_field_instance))
    end
    Bot::Alegre.unstub.stubs(:request)
  end

  test "/text/similarity/ request should not be called for blank title" do
    text = ""
    pm1 = create_project_media team: @team, quote: text
    Bot::Alegre.stubs(:request).raises("Request method called when it should not be")
    assert_nothing_raised do
        Bot::Alegre.send_to_text_similarity_index(pm1, create_field_instance, text, Bot::Alegre.item_doc_id(pm1, create_field_instance))
    end
    Bot::Alegre.unstub.stubs(:request)
  end

  test "should not try to store package for blank item" do
    pm = create_project_media media: Blank.create!
    assert_nothing_raised do
      Bot::Alegre.store_package(pm, 'title')
    end
  end
end
