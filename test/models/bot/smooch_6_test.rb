require_relative '../../test_helper'
require 'sidekiq/testing'

# Tests Smooch Bot v2

class Bot::Smooch6Test < ActiveSupport::TestCase
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
    Bot::Smooch.reset_user_language(@uid)
    Sidekiq::Testing.fake!
    @search_result = create_project_media team: @team

    # The test bot main menu looks like:
    # Hello! Send 9 to read the terms of service.
    #
    # MAIN
    # 1. Submit new content to...
    # 2. Subscribe to our news...
    #
    # SECONDARY
    # 3. Query
    # 4. Latest articles
    # 5. Subscription
    #
    # LANGUAGES AND PRIVACY
    # 6. English
    # 7. Português
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
    send_message 'hello', '1', '4'
    assert_saved_query_type 'resource_requests'
  end

  test "should submit query without details on tipline bot v2" do
    WebMock.stub_request(:get, 'http://alegre:5000/text/similarity/').to_return(body: {}.to_json)
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
    send_message 'hello', '1', '6'
    assert_state 'main'
    assert_user_language 'en'

    send_message 'hello', '7'
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
    WebMock.stub_request(:get, 'http://alegre:5000/text/similarity/').to_return(body: {}.to_json)
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
      assert_difference 'Dynamic.count + ProjectMedia.count' do
        send_message '1'
      end
      assert_state 'main'
    end
    CheckSearch.any_instance.unstub(:medias)
  end

  test "should submit query and get relevant text similarity search results on tipline bot v2" do
    ProjectMedia.any_instance.stubs(:report_status).returns('published')
    ProjectMedia.any_instance.stubs(:analysis_published_article_url).returns(random_url)
    Bot::Alegre.stubs(:get_merged_similar_items).returns({ create_project_media.id => { score: 0.9 } })
    Sidekiq::Testing.inline! do
      send_message 'hello', '1', '1', 'Foo bar foo bar foo bar', '1'
      assert_state 'search_result'
      assert_difference 'Dynamic.count + ProjectMedia.count' do
        send_message '1'
      end
      assert_state 'main'
    end
    Bot::Alegre.unstub(:get_merged_similar_items)
    ProjectMedia.any_instance.unstub(:report_status)
    ProjectMedia.any_instance.unstub(:analysis_published_article_url)
  end

  test "should submit query and get relevant image search results on tipline bot v2" do
    image_url = random_url
    WebMock.stub_request(:get, image_url).to_return(body: File.read(File.join(Rails.root, 'test', 'data', 'rails.png')))
    ProjectMedia.any_instance.stubs(:report_status).returns('published')
    ProjectMedia.any_instance.stubs(:analysis_published_article_url).returns(random_url)
    Bot::Alegre.stubs(:get_items_with_similar_media).returns({ @search_result.id => { score: 0.9 } })
    Bot::Smooch.stubs(:bundle_list_of_messages).returns({ 'type' => 'image', 'mediaUrl' => image_url })
    Sidekiq::Testing.inline! do
      send_message 'hello', '1', '1', 'Image here', '1'
      assert_state 'search_result'
      assert_difference 'Dynamic.count + ProjectMedia.count' do
        send_message '1'
      end
      assert_state 'main'
    end
    Bot::Alegre.unstub(:get_merged_similar_items)
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
      assert_state 'waiting_for_message'
    end
    CheckSearch.any_instance.unstub(:medias)
  end

  test "should skip language confirmation and get resource if there is only one language on tipline bot v2" do
    @team.set_languages ['en']
    @team.save!
    WebMock.stub_request(:get, 'http://test.com/feed.rss').to_return(body: '<rss></rss>')
    send_message 'hello', '4'
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

    send_message '6'
    assert_state 'main'
    assert_user_language 'en'

    send_message '7'
    assert_state 'main'
    assert_user_language 'pt'

    send_message '8'
    assert_state 'main'
    assert_user_language 'es'

    send_message '9'
    assert_state 'main'
    assert_user_language 'fr'
  end

  test "should stay on search state until there are results on tipline bot v2" do
    send_message 'hello', '1', '1', 'Foo bar', '1'
    assert_state 'search'
    send_message 'hey'
    assert_state 'search'
  end

  test "should parse WhatsApp payload on tipline bot v2" do
    message = { 'text' => 'Bar', 'payload' => { state: 'main', keyword: 'Foo ' }.to_json }
    assert_equal 'foo', Bot::Smooch.get_typed_message(message, @sm)[0]
  end

  test "should confirm language on tipline bot v2" do
    assert_state 'waiting_for_message'
    send_message 'hello'
    assert_state 'main'
    send_message 'hello'
    assert_state 'main'
  end

  test "should submit URL on tipline bot v2" do
    url = random_url
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","description":"Foo bar","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    ProjectMedia.any_instance.stubs(:report_status).returns('published')
    ProjectMedia.any_instance.stubs(:analysis_published_article_url).returns(random_url)
    Bot::Alegre.stubs(:get_merged_similar_items).returns({ create_project_media.id => { score: 0.9 } })
    Sidekiq::Testing.inline! do
      send_message 'hello', '1', '1', "Foo bar foo bar #{url} foo bar", '1'
    end
    Bot::Alegre.unstub(:get_merged_similar_items)
    ProjectMedia.any_instance.unstub(:report_status)
    ProjectMedia.any_instance.unstub(:analysis_published_article_url)
  end

  test "should update channel for manually matched items" do
    pm = create_project_media team: @team
    Sidekiq::Testing.inline! do
      message = {
        type: 'text',
        text: random_string,
        role: 'appUser',
        received: 1573082583.219,
        name: random_string,
        authorId: random_string,
        '_id': random_string,
        source: {
          originalMessageId: random_string,
          originalMessageTimestamp: 1573082582,
          type: 'whatsapp',
          integrationId: random_string
        },
      }
      Bot::Smooch.save_message(message.to_json, @app_id, nil, 'menu_options_requests', pm)
      # verifiy new channel value
      data = {"main" => CheckChannels::ChannelCodes::MANUAL, "others" => [CheckChannels::ChannelCodes::WHATSAPP]}
      assert_equal data, pm.reload.channel
    end
  end

  test "should read newsletter after 24 hours since the last message" do
    WebMock.stub_request(:get, 'http://test.com/feed.rss').to_return(body: '<rss></rss>')
    id = random_string
    message = { 'appUser' => { '_id' => @uid } }
    original = { 'language' => 'en', 'introduction' => 'Latest from {date} on {channel}:' }
    Bot::Smooch.stubs(:send_message_to_user).returns(OpenStruct.new(message: OpenStruct.new({ id: id })))
    assert Bot::Smooch.resend_newsletter_after_window(message, original)
    assert_equal 'newsletter:en', Rails.cache.read("smooch:original:#{id}")
    Bot::Smooch.unstub(:send_message_to_user)

    send_message_to_smooch_bot('Read now', @uid, { 'quotedMessage' => { 'content' => { '_id' => id } } })
  end

  test "should show main menu as buttons for non-WhatsApp platforms on tipline bot v2" do
    send_message_to_smooch_bot('Hello', @uid, { 'source' => { 'type' => 'telegram' } })
    send_message_to_smooch_bot('1', @uid, { 'source' => { 'type' => 'telegram' } })
    assert_state 'main'
  end

  test "should auto-start conversation" do
    payload = {
      trigger: 'conversation:start',
      app: {
        '_id': @app_id
      },
      version: 'v1.1',
      source: { type: 'viber' },
      conversation: { '_id': random_string },
      appUser: {
        '_id': random_string,
        'conversationStarted': true
      }
    }.to_json
    assert Bot::Smooch.run(payload)
  end

  test "should send feedback message after user receive search results" do
    uid = random_string
    CheckStateMachine.new(uid).go_to_search_result
    id = random_string
    redis = Redis.new(REDIS_CONFIG)
    redis.rpush("smooch:search:#{uid}", id)
    assert_equal 1, redis.llen("smooch:search:#{uid}")
    Bot::Smooch.ask_for_feedback_when_all_search_results_are_received(@app_id, 'en', {}, uid, 'WhatsApp', 1)
    Sidekiq::Testing.inline! do
      payload = {
        trigger: 'message:delivery:channel',
        app: {
          '_id': @app_id
        },
        version: 'v1.1',
        source: { type: 'whatsapp' },
        conversation: { '_id': random_string },
        message: { '_id': id },
        appUser: {
          '_id': uid,
          'conversationStarted': true
        }
      }.to_json
      assert Bot::Smooch.run(payload)
      Bot::Smooch.ask_for_feedback_when_all_search_results_are_received(@app_id, 'en', {}, uid, 'WhatsApp', 1)
      assert_equal 0, redis.llen("smooch:search:#{uid}")
    end
  end
end
