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
    Rails.cache.delete("smooch:banned:#{@uid}")
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
    Sidekiq::Worker.clear_all
    Sidekiq::Testing.inline!
  end

  def reload_tipline_settings
    @installation = TeamBotInstallation.find(@installation.id)
    Bot::Smooch.get_installation('smooch_webhook_secret', 'test')
  end

  def send_message(*messages)
    [messages].flatten.each { |message| send_message_to_smooch_bot(message, @uid) }
  end

  def assert_state(expected)
    assert_equal expected, @sm.state.value
  end

  def assert_saved_query_type(type)
    assert_difference "TiplineRequest.where('smooch_request_type LIKE ?', '%#{type}%').count" do
      Sidekiq::Worker.drain_all
    end
  end

  def assert_no_saved_query
    assert_no_difference "TiplineRequest.count" do
      Sidekiq::Worker.drain_all
    end
  end

  def assert_user_language(language)
    !Rails.cache.read("smooch:user_language:#{@uid}") == language
  end

  def send_message_outside_24_hours_window(template, pm = nil, extra = {})
    message_id = random_string
    response = OpenStruct.new(body: OpenStruct.new({ message: OpenStruct.new(id: message_id) }))
    Bot::Smooch.save_smooch_response(response, pm, Time.now.to_i, template, 'en', extra)

    @msgid = random_string
    response = OpenStruct.new(body: OpenStruct.new({ message: OpenStruct.new(id: @msgid) }))
    Bot::Smooch.stubs(:send_message_to_user).returns(response)
    assert_nil Rails.cache.read("smooch:original:#{@msgid}")

    payload = {
      trigger: 'message:delivery:failure',
      app: {
        '_id': @app_id
      },
      version: 'v1.1',
      appUser: {
        '_id': @uid,
        conversationStarted: true
      },
      destination: {
        type: 'whatsapp'
      },
      error: {
        code: 'uncategorized_error',
        underlyingError: {
          errors: [
            {
              code: 470,
              title: 'Message sent more than 24 hours after the user last interaction.'
            }
          ]
        }
      },
      message: {
        '_id': message_id
      },
      timestamp: Time.now.to_f
    }.to_json

    assert Bot::Smooch.run(payload)
    assert_not_nil Rails.cache.read("smooch:original:#{@msgid}")
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
    WebMock.stub_request(:post, /\/text\/similarity\/search\//).to_return(body: {}.to_json) # For explainers
    WebMock.stub_request(:post, /\/similarity\/async\/text/).to_return(body: {}.to_json) # For explainers
    WebMock.stub_request(:post, /\/similarity\/sync\/text/).to_return(body: {}.to_json) # For explainers
    claim = 'This is a test claim'
    send_message 'hello', '1', '1', random_string, random_string, claim, random_string, random_string, '1'
    assert_saved_query_type 'default_requests'
    pm = ProjectMedia.last
    assert_equal "text-#{@team.slug}-#{pm.id}", pm.title
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
    WebMock.stub_request(:post, /\/similarity\/sync\/text/).to_return(body: {}.to_json) # For explainers
    WebMock.stub_request(:post, /\/similarity\/async\/text/).to_return(body: {}.to_json) # For explainers
    WebMock.stub_request(:post, /\/text\/similarity\/search\//).to_return(body: {}.to_json) # For explainers
    claim = 'This is a test claim'
    send_message 'hello', '1', '1', random_string, '2', random_string, claim, '1'
    assert_saved_query_type 'default_requests'
    pm = ProjectMedia.last
    assert_equal "text-#{@team.slug}-#{pm.id}", pm.title
  end

  test "should submit query and get relevant text keyword search results on tipline bot v2" do
    pm = create_project_media(team: @team)
    publish_report(pm, {}, nil, { language: 'en', use_visual_card: false })
    CheckSearch.any_instance.stubs(:medias).returns([pm])
    Sidekiq::Testing.inline! do
      # Verify no results when smooch_skip_search options enabled
      @installation.set_smooch_skip_search = true
      @installation.save!
      send_message 'hello', '1', '1', 'Foo bar', '1'
      assert_state 'main'
      # Verify results when smooch_skip_search options disabled
      @installation.set_smooch_skip_search = false
      @installation.save!
      send_message '2', 'hello #2', '1', '1', 'Foo bar #2', '1'
      assert_state 'search_result'
      assert_difference 'TiplineRequest.count + ProjectMedia.count', 2 do
        send_message '1'
      end
      assert_state 'main'
    end
    CheckSearch.any_instance.unstub(:medias)
  end

  test "should send summary on messenger when URL is blank" do
    pm = create_project_media(team: @team)
    publish_report(pm, {}, nil, { language: 'en', use_visual_card: false })
    CheckSearch.any_instance.stubs(:medias).returns([pm])
    Sidekiq::Testing.inline! do
      ['hello', '1', '1', 'Foo bar', '1'].flatten.each { |message| send_message_to_smooch_bot(message, @uid, { 'source' => { 'type' => 'messenger' } }) }
      assert_state 'search_result'
      assert_difference 'TiplineRequest.count + ProjectMedia.count', 2 do
        send_message_to_smooch_bot('1', @uid, { 'source' => { 'type' => 'messenger' } })
      end
      assert_state 'main'
    end
    CheckSearch.any_instance.unstub(:medias)
  end

  test "should submit query and get relevant text similarity search results on tipline bot v2" do
    ProjectMedia.any_instance.stubs(:report_status).returns('published')
    ProjectMedia.any_instance.stubs(:analysis_published_article_url).returns(random_url)
    pm = create_project_media(team: @team)
    publish_report(pm, {}, nil, { language: 'en', use_visual_card: false })
    Bot::Alegre.stubs(:get_merged_similar_items).returns({ pm.id => { score: 0.9, context: {foo: :bar} } })
    Sidekiq::Testing.inline! do
      send_message 'hello', '1', '1', 'Foo bar foo bar foo bar', '1'
      assert_state 'search_result'
      assert_difference 'TiplineRequest.count + ProjectMedia.count', 2 do
        send_message '1'
      end
      assert_state 'main'
    end
    Bot::Alegre.unstub(:get_merged_similar_items)
    ProjectMedia.any_instance.unstub(:report_status)
    ProjectMedia.any_instance.unstub(:analysis_published_article_url)
  end

  test "should submit query and get relevant image search results on tipline bot v2" do
    publish_report(@search_result, {}, nil, { language: 'en', use_visual_card: false })
    image_url = random_url
    WebMock.stub_request(:get, image_url).to_return(body: File.read(File.join(Rails.root, 'test', 'data', 'rails.png')))
    ProjectMedia.any_instance.stubs(:report_status).returns('published')
    ProjectMedia.any_instance.stubs(:analysis_published_article_url).returns(random_url)
    Bot::Alegre.stubs(:get_items_with_similar_media_v2).returns({ @search_result.id => { score: 0.9, context: {foo: :bar} } })
    Bot::Smooch.stubs(:bundle_list_of_messages).returns({ 'type' => 'image', 'mediaUrl' => image_url, 'source' => { type: "whatsapp" }, language: 'en' })
    CheckS3.stubs(:rewrite_url).returns(random_url)
    Sidekiq::Testing.inline! do
      send_message 'hello', '1', '1', 'Image here', '1'
      assert_state 'search_result'
      assert_difference 'TiplineRequest.count + ProjectMedia.count', 2 do
        send_message '1'
      end
      assert_state 'main'
    end
  end

  test "should submit query and handle search error on tipline bot v2" do
    WebMock.stub_request(:post, /\/similarity\/sync\/text/).to_return(body: {}.to_json) # For explainers
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
    pm = create_project_media(team: @team)
    publish_report(pm, {}, nil, { language: 'en', use_visual_card: false })
    CheckSearch.any_instance.stubs(:medias).returns([pm])
    Sidekiq::Testing.inline! do
      send_message 'hello', '1', '1', 'Foo bar', '1'
      assert_state 'search_result'
      assert_difference 'Dynamic.count + TiplineRequest.count + ProjectMedia.count', 3 do
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
    reload_tipline_settings

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
    WebMock.stub_request(:post, /\/similarity\/sync\/text/).to_return(body: {}.to_json) # For explainers
    Sidekiq::Testing.inline! do
      send_message 'hello', '1', '1', "Foo bar foo bar #{url} foo bar", '1'
    end
    Bot::Alegre.unstub(:get_merged_similar_items)
    ProjectMedia.any_instance.unstub(:report_status)
    ProjectMedia.any_instance.unstub(:analysis_published_article_url)
  end

  test "should update channel for all items" do
    pm = create_project_media team: @team
    pm2 = create_project_media team: @team, channel: { main: CheckChannels::ChannelCodes::WHATSAPP }
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
        language: 'en',
      }
      Bot::Smooch.save_message(message.to_json, @app_id, nil, 'menu_options_requests', pm.id, pm.class.name)
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
          type: 'messenger',
          integrationId: random_string
        },
        language: 'en',
      }
      Bot::Smooch.save_message(message.to_json, @app_id, nil, 'menu_options_requests', pm.id, pm.class.name)
      # verifiy new channel value
      data = {"main" => CheckChannels::ChannelCodes::MANUAL, "others" => [CheckChannels::ChannelCodes::WHATSAPP, CheckChannels::ChannelCodes::MESSENGER]}
      assert_equal data, pm.reload.channel
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
          type: 'messenger',
          integrationId: random_string
        },
        language: 'en',
      }
      Bot::Smooch.save_message(message.to_json, @app_id, nil, 'menu_options_requests', pm2.id, pm2.class.name)
      # verifiy new channel value
      data = {"main" => CheckChannels::ChannelCodes::WHATSAPP, "others" => [CheckChannels::ChannelCodes::MESSENGER]}
      assert_equal data, pm2.reload.channel
    end
  end

  test "should save only one item and one request for same tipline message" do
    text = "This is message is so long that it is considered a media"
    Sidekiq::Testing.inline! do
      message = {
        type: 'text',
        text: text,
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
        language: 'en',
      }
      author = BotUser.smooch_user
      threads = []
      assert_difference 'ProjectMedia.count' do
        assert_difference "TiplineRequest.count" do
          assert_raises ActiveRecord::StatementInvalid do
            3.times do |i|
              threads << Thread.new {
                Bot::Smooch.save_message(message.to_json, @app_id, author, 'timeout_requests', nil, nil)
              }
            end
            threads.map(&:join)
          end
        end
      end
    end
  end

  test "should show main menu as buttons for non-WhatsApp platforms on tipline bot v2" do
    send_message_to_smooch_bot('Hello', @uid, { 'source' => { 'type' => 'telegram' } })
    send_message_to_smooch_bot('1', @uid, { 'source' => { 'type' => 'telegram' } })
    assert_state 'main'
  end

  test "should change language on non-WhatsApp platforms on tipline bot v2" do
    send_message_to_smooch_bot('hello', @uid, { 'source' => { 'type' => 'telegram' } })
    send_message_to_smooch_bot('1', @uid, { 'source' => { 'type' => 'telegram' } })
    send_message_to_smooch_bot('6', @uid, { 'source' => { 'type' => 'telegram' } })
    assert_state 'main'
    assert_user_language 'en'

    send_message_to_smooch_bot('hello', @uid, { 'source' => { 'type' => 'telegram' } })
    send_message_to_smooch_bot('7', @uid, { 'source' => { 'type' => 'telegram' } })
    assert_state 'main'
    assert_user_language 'pt'
  end

  test "should handle more than 10 supported languages on tipline bot v2" do
    langs = ['en', 'pt', 'es', 'fr', 'de', 'ar', 'hi', 'bn', 'fi', 'da', 'nl']
    @team.set_languages langs
    @team.save!
    settings = @installation.settings.clone
    langs.each_with_index do |l, i|
      next if i < 2
      settings['smooch_workflows'][i] = @settings['smooch_workflows'][0].clone.merge({ 'smooch_workflow_language' => l })
    end
    @installation.settings = settings
    @installation.save!
    reload_tipline_settings

    send_message 'hello', '1'
    assert_state 'main'
    assert_user_language 'en'

    send_message '6'
    assert_state 'main'
    assert_user_language nil
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
    Bot::Smooch.ask_for_feedback_when_all_search_results_are_received(@app_id, 'en', {}, uid, 'WhatsApp', 'ZENDESK', 1)
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
      Bot::Smooch.ask_for_feedback_when_all_search_results_are_received(@app_id, 'en', {}, uid, 'WhatsApp', 'ZENDESK', 1)
      assert_equal 0, redis.llen("smooch:search:#{uid}")
    end
  end

  test "should timeout search results on tipline bot v2" do
    @installation.set_smooch_disable_timeout = false
    @installation.save!
    reload_tipline_settings
    uid = random_string
    Bot::Smooch.save_search_results_for_user(uid, [create_project_media.id])
    send_message_to_smooch_bot('Hello', uid)
    sm = CheckStateMachine.new(uid)
    sm.go_to_search_result
    assert_equal 'search_result', sm.state.value

    message = { 'authorId' => uid, '_id' => random_string }
    Bot::Smooch.timeout_smooch_menu((Time.now + 30.minutes).to_i, message, @app_id, 'ZENDESK')
    assert_equal 'waiting_for_message', sm.state.value
  end

  test "should send report notification with button after 24 hours window" do
    Sidekiq::Testing.inline! do
      @installation.set_smooch_template_name_for_fact_check_report_with_button = 'report_with_button'
      @installation.save!
      pm = create_project_media team: @team
      publish_report(pm)

      send_message_outside_24_hours_window('fact_check_report', pm)

      send_message_to_smooch_bot('Receive fact-check', @uid, { 'quotedMessage' => { 'content' => { '_id' => @msgid } } })
      assert_nil Rails.cache.read("smooch:original:#{@msgid}")
    end
  end

  test "should send report update notification with button after 24 hours window" do
    Sidekiq::Testing.inline! do
      @installation.set_smooch_template_name_for_fact_check_report_updated_with_button = 'report_updated_with_button'
      @installation.save!
      pm = create_project_media team: @team
      publish_report(pm)

      send_message_outside_24_hours_window('fact_check_report_updated', pm)

      send_message_to_smooch_bot('Receive update', @uid, { 'quotedMessage' => { 'content' => { '_id' => @msgid } } })
      assert_nil Rails.cache.read("smooch:original:#{@msgid}")
    end
  end

  test "should send Slack message notification with button after 24 hours window" do
    Sidekiq::Testing.inline! do
      Bot::Smooch.stubs(:get_original_slack_message_text_to_be_resent).returns(random_string)
      @installation.set_smooch_template_name_for_more_information_with_button = 'more_information_with_button'
      @installation.save!

      send_message_outside_24_hours_window('more_information')

      send_message_to_smooch_bot('Receive message', @uid, { 'quotedMessage' => { 'content' => { '_id' => @msgid } } })
      assert_nil Rails.cache.read("smooch:original:#{@msgid}")
    end
  end

  test "should get user name from id" do
    create_annotation_type_and_fields('Smooch User', { 'Data' => ['JSON', true], 'ID' => ['String', true] })

    # Self-hosted WhatsApp Business API / Turn.io
    uid1 = random_string
    data1 = { id: uid1, raw: { profile: { name: 'Foo Bar' }, wa_id: 123456 }, identifier: uid1 }
    create_dynamic_annotation annotation_type: 'smooch_user', set_fields: { smooch_user_id: uid1, smooch_user_data: data1.to_json }.to_json

    # Smooch
    uid2 = random_string
    data2 = { id: uid2, raw: { '_id': uid2, givenName: 'Foo' }, identifier: uid2 }
    create_dynamic_annotation annotation_type: 'smooch_user', set_fields: { smooch_user_id: uid2, smooch_user_data: data2.to_json }.to_json

    # Other
    uid3 = random_string
    data3 = { id: uid3, identifier: uid3 }
    create_dynamic_annotation annotation_type: 'smooch_user', set_fields: { smooch_user_id: uid3, smooch_user_data: data3.to_json }.to_json

    assert_equal 'Foo Bar', Bot::Smooch.get_user_name_from_uid(uid1)
    assert_equal 'Foo', Bot::Smooch.get_user_name_from_uid(uid2)
    assert_equal '-', Bot::Smooch.get_user_name_from_uid(random_string)
    assert_equal '-', Bot::Smooch.get_user_name_from_uid(uid3)
  end

  test "should not duplicate messages when saving" do
    @team.set_languages ['en']
    @team.save!
    message_text = 'not_a_url' #Not a URL, not media, and not longer than 'min_number_of_words_for_tipline_long_text'
    send_message message_text, '1', message_text, '1'
    assert_state 'search'
    Sidekiq::Worker.drain_all
    tr = TiplineRequest.last
    assert_equal 2, tr.smooch_data['text'].split("\n#{Bot::Smooch::MESSAGE_BOUNDARY}").select{ |x| x.chomp.strip == message_text }.size
  end

  test "should get search results in different languages" do
    tbi = create_team_bot_installation team_id: @team.id, user_id: create_bot_user(name: 'Alegre', login: 'alegre', approved: true).id
    tbi.set_single_language_fact_checks_enabled = false
    tbi.save!
    pm = create_project_media team: @team
    publish_report(pm, {}, nil, { language: 'pt', use_visual_card: false })
    Bot::Smooch.stubs(:get_search_results).returns([pm])
    Sidekiq::Testing.inline! do
      send_message 'hello', '1', '1', 'Foo bar', '1'
    end
    Bot::Smooch.unstub(:get_search_results)
    assert_not_nil Rails.cache.read("smooch:user_search_results:#{@uid}")
  end

  test "should not get search results in different languages" do
    tbi = create_team_bot_installation team_id: @team.id, user_id: create_bot_user(name: 'Alegre', login: 'alegre', approved: true).id
    tbi.set_single_language_fact_checks_enabled = true
    tbi.save!
    pm = create_project_media team: @team
    publish_report(pm, {}, nil, { language: 'pt', use_visual_card: false })
    Bot::Smooch.stubs(:get_search_results).returns([pm])
    WebMock.stub_request(:post, /\/similarity\/sync\/text/).to_return(body: {}.to_json) # For explainers
    Sidekiq::Testing.inline! do
      send_message 'hello', '1', '1', 'Foo bar', '1'
    end
    Bot::Smooch.unstub(:get_search_results)
    assert_nil Rails.cache.read("smooch:user_search_results:#{@uid}")
  end

  test "should not import duplicate smooch user id field" do
    create_annotation_type_and_fields('Smooch User', { 'Id' => ['Text', false], 'App Id' => ['Text', false], 'Data' => ['JSON', false] })
    app_id = random_string
    id = random_string
    phone = random_string
    name = random_string
    fields = { smooch_user_id: id, smooch_user_app_id: app_id, smooch_user_data: { phone: phone, app_name: name }.to_json }
    create_dynamic_annotation annotation_type: 'smooch_user', set_fields: fields.to_json
    f_count = DynamicAnnotation::Field.where(field_name: 'smooch_user_id', value: id).count
    assert_equal 1, f_count
    assert_raises ActiveRecord::RecordNotUnique do
      create_dynamic_annotation annotation_type: 'smooch_user', set_fields: fields.to_json
    end
  end

  test "should avoid race condition on newsletter delivery" do
    @installation.set_smooch_disable_timeout = false
    @installation.save!
    reload_tipline_settings

    assert_no_difference 'ProjectMedia.count' do
      Sidekiq::Testing.fake! do
        send_message_to_smooch_bot('Read now', @uid, { 'quotedMessage' => { 'content' => { '_id' => random_string } } })
      end
      Sidekiq::Worker.drain_all
    end
  end

  test "should ask for feedback even when confirmation is not received" do
    uid = random_string
    CheckStateMachine.new(uid).go_to_search_result
    id = random_string
    redis = Redis.new(REDIS_CONFIG)
    redis.rpush("smooch:search:#{uid}", id)
    assert_equal 1, redis.llen("smooch:search:#{uid}")
    Sidekiq::Testing.inline! do
      Bot::Smooch.ask_for_feedback_when_all_search_results_are_received(@app_id, 'en', {}, uid, 'WhatsApp', 'ZENDESK', 1)
    end
    assert_equal 0, redis.llen("smooch:search:#{uid}")
  end

  test "should send main menu in background if interval is greater than 1" do
    Sidekiq::Worker.clear_all
    Sidekiq::Testing.fake! do
      assert_equal 0, Sidekiq::Worker.jobs.size
      Bot::Smooch.send_final_messages_to_user(@uid, 'Test', nil, 'en', 5)
      assert_equal 2, Sidekiq::Worker.jobs.size
    end
  end

  test "should not reply to banned user" do
    Bot::Smooch.ban_user({ 'authorId' => @uid })
    Sidekiq::Worker.clear_all
    Sidekiq::Testing.fake! do
      send_message 'hello'
      assert_equal 0, Sidekiq::Worker.jobs.size
    end
  end

  test 'should update subscription and not try to reply to user when a payload about number change is received' do
    @installation.set_capi_whatsapp_business_account_id = '123456'
    @installation.set_capi_phone_number = '000000'
    @installation.save!
    Rails.cache.write('smooch_bot_installation_id:whatsapp_business_account_id:123456', @installation.id)
    reload_tipline_settings
    RequestStore.store[:smooch_bot_provider] = 'CAPI'

    Bot::Smooch.expects(:send_message_to_user).never

    ts = create_tipline_subscription team_id: @team.id, uid: '000000:111111'
    assert_equal '000000:111111', ts.reload.uid

    payload = {
      object: 'whatsapp_business_account',
      entry: [{
        id: '123456',
        changes: [{
          value: {
            messaging_product: 'whatsapp',
            metadata: {
              display_phone_number: '000000',
              phone_number_id: '654321'
            },
            messages: [{
              from: '111111',
              id: 'wamid.abc123',
              timestamp: Time.now.to_i.to_s,
              system: {
                body: 'User A changed from 111111 to 222222',
                wa_id: '222222',
                type: 'user_changed_number'
              },
              type: 'system'
            }
            ]
          },
          field: 'messages'
        }]
      }]
    }
    assert !Bot::Smooch.run(payload.to_json)
    assert_equal '000000:222222', ts.reload.uid
  end

  test 'should process menu option using NLU' do
    # Mock any call to Alegre like `POST /text/similarity/` with a "text" parameter that contains "want"
    Bot::Alegre.stubs(:request).with{ |x, y, z| x == 'post' && y == '/similarity/sync/text' && z[:text] =~ /want/ }.returns(true)
    # Mock any call to Alegre like `GET /text/similarity/` with a "text" parameter that does not contain "want"
    Bot::Alegre.stubs(:request).with{ |x, y, z| x == 'post' && y == '/similarity/sync/text' && (z[:text] =~ /want/).nil? }.returns({ 'result' => [] })

    # Enable NLU and add a couple of keywords for the newsletter menu option
    nlu = SmoochNlu.new(@team.slug)
    nlu.enable!
    nlu.add_keyword_to_menu_option('en', 'main', 1, 'I want to query')
    nlu.add_keyword_to_menu_option('en', 'main', 2, 'I want to subscribe to the newsletter')
    nlu.add_keyword_to_menu_option('en', 'main', 2, 'I want to unsubscribe from the newsletter')
    reload_tipline_settings
    query_option_id = @installation.get_smooch_workflows[0]['smooch_state_main']['smooch_menu_options'][1]['smooch_menu_option_id']
    subscription_option_id = @installation.get_smooch_workflows[0]['smooch_state_main']['smooch_menu_options'][2]['smooch_menu_option_id']

    # Mock a call to Alegre like `GET /text/similarity/` with a "text" parameter that contains "want"
    Bot::Alegre.stubs(:request).with{ |x, y, z| x == 'post' && y == '/similarity/sync/text' && z[:text] =~ /want/ }.returns({ 'result' => [
      { 'score' => 0.9, 'context' => { 'menu_option_id' => subscription_option_id } },
      { 'score' => 0.2, 'context' => { 'menu_option_id' => query_option_id } }
    ]})

    # Sending a message about the newsletter should take to the newsletter state, as per configurations done above
    send_message 'hello', '1' # Sends a first message and confirms language as English
    assert_state 'main'
    send_message 'I want to subscribe to the newsletter?'
    assert_state 'subscription'
    send_message '2' # Keep subscription
    assert_state 'main'

    # Mock a call to Alegre like `GET /text/similarity/` with a "text" parameter that contains "want"
    Bot::Alegre.stubs(:request).with{ |x, y, z| x == 'post' && y == '/similarity/sync/text' && z[:text] =~ /want/ }.returns({ 'result' => [
      { 'score' => 0.96, 'context' => { 'menu_option_id' => subscription_option_id } },
      { 'score' => 0.91, 'context' => { 'menu_option_id' => query_option_id } }
    ]})

    # Sending a message that returns more than one option (disambiguation)
    send_message 'I want to subscribe to the newsletter?'
    assert_state 'main'

    # After disabling NLU
    nlu.disable!
    reload_tipline_settings
    send_message 'Can I subscribe to the newsletter?'
    assert_state 'main'

    # Delete two keywords, so expect two calls to Alegre
    Bot::Alegre.expects(:request).with{ |x, y, _z| x == 'delete' && y == '/text/similarity/' }.twice
    nlu.remove_keyword_from_menu_option('en', 'main', 2, 'I want to subscribe to the newsletter')
    nlu.remove_keyword_from_menu_option('en', 'main', 2, 'I want to unsubscribe from the newsletter')
  end

  test "should get multimedia resource on tipline bot v2" do
    Sidekiq::Testing.inline! do
      TiplineResource.any_instance.stubs(:new_file_uploaded?).returns(true)
      @resource.header_type = 'image'
      File.open(File.join(Rails.root, 'test', 'data', 'rails.png')) do |f|
        @resource.file = f
      end
      @resource.save!
    end
    WebMock.stub_request(:get, 'http://test.com/feed.rss').to_return(body: '<rss></rss>')
    send_message 'hello', '1', '4'
    assert_saved_query_type 'resource_requests'
  end

  test 'should send resource using NLU' do
    Sidekiq::Testing.fake! do
      WebMock.disable_net_connect! allow: /#{CheckConfig.get('elasticsearch_host')}|#{CheckConfig.get('storage_endpoint')}/
      # Mock any call to Alegre like `POST /text/similarity/` with a "text" parameter that contains "who are you"
      Bot::Alegre.stubs(:request).with{ |x, y, z| x == 'post' && y == '/similarity/sync/text' && z[:text] =~ /who are you/ }.returns(true)
      # Mock any call to Alegre like `GET /text/similarity/` with a "text" parameter that does not contain "who are you"
      Bot::Alegre.stubs(:request).with{ |x, y, z| x == 'post' && y == '/similarity/sync/text' && (z[:text] =~ /who are you/).nil? }.returns({ 'result' => [] })

      # Enable NLU and add a couple of keywords to a new "About Us" resource
      nlu = SmoochNlu.new(@team.slug)
      nlu.enable!
      reload_tipline_settings
      r = create_tipline_resource team: @team, content_type: 'static', title: 'About Us', content: 'We are a fact-checking organization.'
      r.add_keyword('who are you')

      # Mock a call to Alegre like `GET /text/similarity/` with a "text" parameter that contains "who are you"
      Bot::Alegre.stubs(:request).with{ |x, y, z| x == 'post' && y == '/similarity/sync/text' && z[:text] =~ /who are you/ }.returns({ 'result' => [
        { '_score' => 0.9, 'context' => { 'resource_id' => 0 } },
        { '_score' => 0.8, 'context' => { 'resource_id' => r.id } }
      ]})

      # Sending a message asking about the tipline should send a resource, as per configurations done above
      send_message 'hello', '1' # Sends a first message and confirms language as English
      assert_state 'main'
      send_message 'Hey, who are you and what you do?'
      assert_saved_query_type 'resource_requests'

      # After disabling NLU
      nlu.disable!
      reload_tipline_settings
      send_message 'Hey, who are you and what you do??'
      assert_no_saved_query

      # Delete one keyword, so expect one call to Alegre
      Bot::Alegre.expects(:request).with{ |x, y, _z| x == 'delete' && y == '/text/similarity/' }.once
      r.remove_keyword('who are you')
      Bot::Alegre.unstub(:request)
    end
  end

  test 'should have shortcuts for submission' do
    send_message 'This is message is so long that it is considered a media'
    assert_state 'ask_if_ready'
  end

  test 'should not have shortcuts for submission' do
    send_message 'Hello'
    assert_state 'main'
  end

  test 'should save unconfirmed media with enough words' do
    @installation.set_smooch_disable_timeout = false
    @installation.save!
    reload_tipline_settings
    send_message 'hello', '1' # Sends a first message and confirms language as English
    send_message 'This is message is so long that it is considered a media'
    assert_difference 'ProjectMedia.count' do
      assert_difference "TiplineRequest.count" do
        Sidekiq::Worker.drain_all
      end
    end
  end

  test 'should not save unconfirmed media with just a few words' do
    @installation.set_smooch_disable_timeout = false
    @installation.save!
    reload_tipline_settings
    send_message 'hello', '1' # Sends a first message and confirms language as English
    send_message 'Hi, there!'
    assert_no_difference 'ProjectMedia.count' do
      assert_difference "TiplineRequest.count" do
        Sidekiq::Worker.drain_all
      end
    end
  end

  test "should submit query and handle explainer search error on tipline bot v2" do
    Explainer.stubs(:search_by_similarity).raises(StandardError)
    Sidekiq::Testing.inline! do
      send_message 'hello', '1', '1', 'Foo bar', '1'
    end
  end

  test "should search by explainers on tipline bot v2" do
    assert_nil Rails.cache.read("smooch:user_search_results:#{@uid}")
    @search_result.explainers << create_explainer(language: 'en', team: @team, title: 'Test', description: 'Foo bar')
    Bot::Smooch.stubs(:get_search_results).returns([])
    Sidekiq::Testing.inline! do
      send_message 'hi', '1', '1', 'Foo', '1'
    end
    assert_not_nil Rails.cache.read("smooch:user_search_results:#{@uid}")
  end

  test "should get dynamic resource on tipline bot v2" do
    civic_api_mocked_data = { pollingLocations: [{ address: {}, startDate: '2024-11-01', endDate: '2024-11-05', pollingHours: '7am - 5pm' }], earlyVoteSites: [{ address: {}, startDate: '2024-11-01', endDate: '2024-11-05', pollingHours: '7am - 5pm' }] }
    WebMock.stub_request(:get, /googleapis\.com\/civicinfo/).to_return(body: civic_api_mocked_data.to_json)
    stub_configs({ 'google_api_key' => random_string }) do
      @resource.content_type = 'dynamic'
      @resource.save!
      send_message 'hello', '1', '4'
      assert_state 'resource_waiting_for_user_input'
      send_message '972 Mission St San Francisco CA'
      assert_state 'waiting_for_message'
    end
  end

  test "should not get dynamic resource on tipline bot v2 if resource is not available anymore" do
    @resource.content_type = 'dynamic'
    @resource.save!
    send_message 'hello', '1', '4'
    assert_state 'resource_waiting_for_user_input'
    @resource.delete
    send_message '972 Mission St San Francisco CA'
    assert_state 'waiting_for_message'
  end

  test "should not get dynamic resource on tipline bot v2 if external API returns an error" do
    WebMock.stub_request(:get, /googleapis\.com\/civicinfo/).to_return(body: { pollingLocations: 'Some error' }.to_json)
    stub_configs({ 'google_api_key' => random_string }) do
      @resource.content_type = 'dynamic'
      @resource.save!
      send_message 'hello', '1', '4'
      assert_state 'resource_waiting_for_user_input'
      send_message '972 Mission St San Francisco CA'
      assert_state 'waiting_for_message'
    end
  end

  test "should unsubscribe user when clicking on newsletter button" do
    Sidekiq::Testing.inline! do
      # Create subscription
      ts = create_tipline_subscription team_id: @team.id, uid: @uid
      assert_not_nil TiplineSubscription.find_by_id(ts.id)

      # "Send" newsletter
      message_id = random_string
      response = OpenStruct.new(body: OpenStruct.new({ message: OpenStruct.new(id: message_id) }))
      Bot::Smooch.save_smooch_response(response, nil, Time.now.to_i, 'newsletter', 'en')

      # Click on "Unsubscribe" button
      send_message_to_smooch_bot('Unsubscribe', @uid, { 'quotedMessage' => { 'content' => { '_id' => message_id } } })
      assert_nil TiplineSubscription.find_by_id(ts.id)
    end
  end

  test "should send explainer notification with button after 24 hours window" do
    @installation.set_smooch_template_name_for_fact_check_report_with_button = 'article_with_button'
    @installation.save!
    pm = create_project_media team: @team
    ex = create_explainer team: @team
    ei = create_explainer_item project_media: pm, explainer: ex

    Sidekiq::Testing.inline! do
      send_message_outside_24_hours_window('fact_check_report', pm, { explainer_item_id: ei.id })

      send_message_to_smooch_bot('Receive article', @uid, { 'quotedMessage' => { 'content' => { '_id' => @msgid } } })
      assert_nil Rails.cache.read("smooch:original:#{@msgid}")
    end
  end
end
