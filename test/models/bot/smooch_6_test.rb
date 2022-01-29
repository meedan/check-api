require_relative '../../test_helper'
require 'sidekiq/testing'

# Tests Smooch Bot v2

class Bot::Smooch5Test < ActiveSupport::TestCase
  def setup
    super
    setup_smooch_bot(true)
    @team.set_languages ['en', 'pt']
    @team.set_language 'en'
    @team.save!
    @installation = TeamBotInstallation.find(@installation.id)
    @installation.set_smooch_version = 'v2'
    @installation.set_smooch_disable_timeout = true
    @installation.save!
    Bot::Smooch.get_installation('smooch_webhook_secret', 'test')
    @uid = random_string
    @sm = CheckStateMachine.new(@uid)
    @sm.reset
    Bot::Smooch.clear_user_bundled_messages(@uid)
    Sidekiq::Testing.fake!

    # The test bot main menu looks like:
    # Hello! Send 9 to read the terms of service.
    #
    # MAIN
    # 1. Submit new content to...
    # 2. Subscribe to our news...
    #
    # SECONDARY
    # 3. Latest articles
    #
    # LANGUAGES AND PRIVACY
    # 4. English
    # 5. Português
    # 9. Privacy statement
  end

  def teardown
    super
    Sidekiq::Worker.drain_all
    Sidekiq::Testing.inline!
  end

  def send_message(*messages)
    [messages].flatten.each { |message| send_message_to_smooch_bot(message, @uid) }
  end

  def assert_state(expected)
    assert_equal expected, @sm.state.value
  end

  def assert_saved_query_type(type)
    assert_difference "DynamicAnnotation::Field.where('value LIKE ?', '%#{type}%').count" do
      Sidekiq::Worker.drain_all
    end
  end

  def assert_no_saved_query
    assert_no_difference "Dynamic.where(annotation_type: 'smooch').count" do
      Sidekiq::Worker.drain_all
    end
  end

  def assert_user_language(language)
    !Rails.cache.read("smooch:user_language:#{@uid}") == language
  end

  test "should use v2" do
    assert Bot::Smooch.is_v2?
  end

  test "should start on tipline bot v2" do
    assert_state 'waiting_for_message'
    send_message 'hello'
    assert_state 'main'
  end

  test "should get resource on tipline bot v2" do
    WebMock.stub_request(:get, 'http://test.com/feed.rss').to_return(body: '<rss></rss>')
    send_message 'hello', '1', '3'
    assert_saved_query_type 'resource_requests'
  end

  test "should submit query without details on tipline bot v2" do
    claim = 'This is a test claim'
    send_message 'hello', '1', '1', random_string, random_string, claim, random_string, random_string, '1'
    assert_saved_query_type 'default_requests'
    assert_equal claim, ProjectMedia.last.title
  end

  test "should subscribe and unsubscribe to newsletter on tipline bot v2" do
    assert_no_difference 'TiplineSubscription.count' do
      send_message 'hello', '1', '2', '2'
      assert_no_saved_query
    end
    assert_difference 'TiplineSubscription.count', 1 do
      send_message 'hello', '2', '1'
      assert_no_saved_query
    end
    assert_no_difference 'TiplineSubscription.count' do
      send_message 'hello', '2', '2'
      assert_no_saved_query
    end
    assert_difference 'TiplineSubscription.count', -1 do
      send_message 'hello', '2', '1'
      assert_no_saved_query
    end
    assert_no_difference 'TiplineSubscription.count' do
      send_message 'hello', '2', '2'
      assert_no_saved_query
    end
  end

  test "should change language on tipline bot v2" do
    send_message 'hello', '1', '4'
    assert_state 'main'
    assert_user_language 'en'

    send_message 'hello', '5'
    assert_state 'main'
    assert_user_language 'pt'
  end

  test "should get privacy statement on tipline bot v2" do
    send_message 'hello', '1', 9
    assert_state 'main'
    assert_no_saved_query
  end

  test "should confirm language as the first step on tipline bot v2" do
    send_message 'hello', '1'
    assert_user_language 'en'
  end

  test "should change language as the first step on tipline bot v2" do
    send_message 'hello', '2'
    assert_user_language 'pt'
  end

  test "should cancel submission on tipline bot v2" do
    send_message 'hello', '1', '1', '1'
    assert_state 'main'
    assert_no_saved_query
  end

  test "should cancel submission after sending some message on tipline bot v2" do
    send_message 'hello', '1', '1', random_string, '3'
    assert_state 'main'
    assert_no_saved_query
  end

  test "should submit query with details on tipline bot v2" do
    claim = 'This is a test claim'
    send_message 'hello', '1', '1', random_string, '2', random_string, claim, '1'
    assert_saved_query_type 'default_requests'
    assert_equal claim, ProjectMedia.last.title
  end

  test "should submit query and get relevant text keyword search results on tipline bot v2" do
    CheckSearch.any_instance.stubs(:medias).returns([create_project_media])
    Sidekiq::Testing.inline! do
      send_message 'hello', '1', '1', 'Foo bar', '1'
      assert_state 'search_result'
      assert_no_difference 'Dynamic.count + ProjectMedia.count' do
        send_message '1'
      end
      assert_state 'main'
    end
    CheckSearch.any_instance.unstub(:medias)
  end

  test "should submit query and get relevant text similarity search results on tipline bot v2" do
    ProjectMedia.any_instance.stubs(:report_status).returns('published')
    ProjectMedia.any_instance.stubs(:analysis_published_article_url).returns(random_url)
    Bot::Alegre.stubs(:get_similar_texts).returns({ create_project_media.id => { score: 0.9 } })
    Sidekiq::Testing.inline! do
      send_message 'hello', '1', '1', 'Foo bar foo bar', '1'
      assert_state 'search_result'
      assert_no_difference 'Dynamic.count + ProjectMedia.count' do
        send_message '1'
      end
      assert_state 'main'
    end
    Bot::Alegre.unstub(:get_similar_texts)
    ProjectMedia.any_instance.unstub(:report_status)
    ProjectMedia.any_instance.unstub(:analysis_published_article_url)
  end

  test "should submit query and get relevant image search results on tipline bot v2" do
    ProjectMedia.any_instance.stubs(:report_status).returns('published')
    ProjectMedia.any_instance.stubs(:analysis_published_article_url).returns(random_url)
    Bot::Alegre.stubs(:get_items_with_similar_media).returns({ create_project_media.id => { score: 0.9 } })
    Bot::Smooch.stubs(:bundle_list_of_messages).returns({ 'type' => 'image' })
    Sidekiq::Testing.inline! do
      send_message 'hello', '1', '1', 'Image here', '1'
      assert_state 'search_result'
      assert_no_difference 'Dynamic.count + ProjectMedia.count' do
        send_message '1'
      end
      assert_state 'main'
    end
    Bot::Alegre.unstub(:get_similar_texts)
    Bot::Smooch.unstub(:bundle_list_of_messages)
    ProjectMedia.any_instance.unstub(:report_status)
    ProjectMedia.any_instance.unstub(:analysis_published_article_url)
  end

  test "should submit query and handle search error on tipline bot v2" do
    CheckSearch.any_instance.stubs(:medias).raises(StandardError)
    Sidekiq::Testing.inline! do
      send_message 'hello', '1', '1', 'Foo bar', '1'
    end
    CheckSearch.any_instance.unstub(:medias)
  end

  test "should submit query and handle another search error on tipline bot v2" do
    Bot::Smooch.stubs(:get_search_results).raises(StandardError)
    Sidekiq::Testing.inline! do
      send_message 'hello', '1', '1', 'Foo bar', '1'
    end
    Bot::Smooch.unstub(:get_search_results)
  end

  test "should submit query and not get relevant text keyword search results on tipline bot v2" do
    CheckSearch.any_instance.stubs(:medias).returns([create_project_media])
    Sidekiq::Testing.inline! do
      send_message 'hello', '1', '1', 'Foo bar', '1'
      assert_state 'search_result'
      assert_difference 'Dynamic.count + ProjectMedia.count', 3 do
        send_message '2'
      end
      assert_state 'main'
    end
    CheckSearch.any_instance.unstub(:medias)
  end

  test "should skip language confirmation and get resource if there is only one language on tipline bot v2" do
    @team.set_languages ['en']
    @team.save!
    WebMock.stub_request(:get, 'http://test.com/feed.rss').to_return(body: '<rss></rss>')
    send_message 'hello', '3'
    assert_saved_query_type 'resource_requests'
  end

  test "should handle more than 3 supported languages on tipline bot v2" do
    @team.set_languages ['en', 'pt', 'es', 'fr']
    @team.save!
    settings = @installation.settings.clone
    ['es', 'fr'].each_with_index do |l, i|
      settings['smooch_workflows'][i + 2] = @settings['smooch_workflows'][0].clone.merge({ 'smooch_workflow_language' => l })
    end
    @installation.settings = settings
    @installation.save!
    Bot::Smooch.get_installation('smooch_webhook_secret', 'test')

    send_message 'hello', '1'
    assert_state 'main'
    assert_user_language 'en'

    send_message '4'
    assert_state 'main'
    assert_user_language 'en'

    send_message '5'
    assert_state 'main'
    assert_user_language 'pt'

    send_message '6'
    assert_state 'main'
    assert_user_language 'es'

    send_message '7'
    assert_state 'main'
    assert_user_language 'fr'
  end
end
