require_relative '../../test_helper'
require 'sidekiq/testing'

class Bot::Smooch4Test < ActiveSupport::TestCase
  def setup
    super
    setup_smooch_bot
    Rails.cache.delete('smooch_bot_installation_id:smooch_webhook_secret:test')
  end

  def teardown
    super
    CONFIG.unstub(:[])
    Bot::Smooch.unstub(:get_language)
  end

  ['whatsapp', 'messenger'].each do |platform|
    test "should resend status message after #{platform} window" do
      msgid = random_string
      pm = create_project_media
      publish_report(pm)
      response = OpenStruct.new({ body: OpenStruct.new(message: OpenStruct.new({ id: msgid })) })
      Bot::Smooch.save_smooch_response(response, pm, random_string, 'fact_check_status', 'en', { message: random_string })
      message = {
        app: {
          '_id': @app_id
        },
        appUser: {
          '_id': random_string,
        },
        message: {
          '_id': msgid
        },
        destination: {
          type: platform
        }
      }.to_json
      assert Bot::Smooch.resend_message_after_window(message)
    end

    test "should resend report after #{platform} window" do
      msgid = random_string
      pm = create_project_media
      publish_report(pm)
      response = OpenStruct.new({ body: OpenStruct.new(message: OpenStruct.new({ id: msgid })) })
      Bot::Smooch.save_smooch_response(response, pm, random_string, 'report', 'en')
      message = {
        app: {
          '_id': @app_id
        },
        appUser: {
          '_id': random_string,
        },
        message: {
          '_id': msgid
        },
        destination: {
          type: platform
        }
      }.to_json
      assert Bot::Smooch.resend_message_after_window(message)
      pm.destroy!
      assert !Bot::Smooch.resend_message_after_window(message)
    end

    test "should resend Slack message after #{platform} window" do
      msgid = random_string
      result = OpenStruct.new({ messages: [OpenStruct.new({ source: OpenStruct.new(type: 'slack'), id: msgid, text: random_string })]})
      SmoochApi::ConversationApi.any_instance.stubs(:get_messages).returns(result)
      message = {
        app: {
          '_id': @app_id
        },
        appUser: {
          '_id': random_string,
        },
        message: {
          '_id': msgid
        },
        destination: {
          type: platform
        }
      }.to_json
      assert Bot::Smooch.resend_message_after_window(message)
      result = OpenStruct.new({ messages: [] })
      SmoochApi::ConversationApi.any_instance.stubs(:get_messages).returns(result)
      assert !Bot::Smooch.resend_message_after_window(message)
    end
  end

  test "should store Smooch conversation id" do
    conversation_id = random_string
    result = OpenStruct.new({ conversation: OpenStruct.new({ id: conversation_id })})
    SmoochApi::ConversationApi.any_instance.stubs(:get_messages).returns(result)
    Sidekiq::Testing.inline! do
      uid = random_string
      messages = [
        {
          '_id': random_string,
          authorId: uid,
          type: 'text',
          source: { type: "whatsapp" },
          text: random_string
        }
      ]
      payload = {
        trigger: 'message:appUser',
        app: {
          '_id': @app_id
        },
        version: 'v1.1',
        messages: messages,
        appUser: {
          '_id': random_string,
          'conversationStarted': true
        }
      }.to_json
      assert_difference "TiplineRequest.count" do
        Bot::Smooch.run(payload)
      end
      pm = ProjectMedia.last
      tr = TiplineRequest.last
      assert_equal conversation_id, tr.smooch_conversation_id
    end
    SmoochApi::ConversationApi.any_instance.unstub(:get_messages)
  end

  test "should rescue ConversationApi get_messages and skip create smooch conversation id" do
    SmoochApi::ConversationApi.any_instance.stubs(:get_messages).raises(SmoochApi::ApiError.new)
    Sidekiq::Testing.inline! do
      uid = random_string
      messages = [
        {
          '_id': random_string,
          authorId: uid,
          type: 'text',
          source: { type: "whatsapp" },
          text: random_string
        }
      ]
      payload = {
        trigger: 'message:appUser',
        app: {
          '_id': @app_id
        },
        version: 'v1.1',
        messages: messages,
        appUser: {
          '_id': random_string,
          'conversationStarted': true
        }
      }.to_json
      assert_no_difference "DynamicAnnotation::Field.where(field_name: 'smooch_conversation_id').count" do
        Bot::Smooch.run(payload)
      end
    end
    SmoochApi::ConversationApi.any_instance.unstub(:get_messages)
  end

  test "should get locales" do
    t1 = create_team
    Team.current = t1
    assert_equal ['en'], Bot::Smooch.template_locale_options
    t2 = create_team
    t2.set_languages = ['es', 'pt']
    t2.save!
    Team.current = t2
    assert_equal ['es', 'pt'], Bot::Smooch.template_locale_options
  end

  test "should split bundled messages" do
    Sidekiq::Testing.fake! do
      uid = random_string
      messages = [
        {
          '_id': random_string,
          authorId: uid,
          type: 'text',
          source: { type: "whatsapp" },
          text: 'foo',
        },
        {
          '_id': random_string,
          authorId: uid,
          type: 'text',
          source: { type: "whatsapp" },
          text: 'bar'
        },
        {
          '_id': random_string,
          authorId: uid,
          type: 'text',
          source: { type: "whatsapp" },
          text: 'test'
        }
      ]
      messages.each do |message|
        payload = {
          trigger: 'message:appUser',
          app: {
            '_id': @app_id
          },
          version: 'v1.1',
          messages: [message],
          appUser: {
            '_id': random_string,
            'conversationStarted': true
          }
        }.to_json
        Bot::Smooch.run(payload)
        sleep 1
      end
      assert_difference 'TiplineRequest.count' do
        Sidekiq::Worker.drain_all
      end
      assert_equal ['bar', 'foo', 'test'], TiplineRequest.last.smooch_data['text'].split(Bot::Smooch::MESSAGE_BOUNDARY).map(&:chomp).sort
    end
  end

  test "should bundle all user messages" do
    setup_smooch_bot(true)
    uid = random_string
    sm = CheckStateMachine.new(uid)
    Sidekiq::Testing.fake! do
      assert_no_difference 'ProjectMedia.count' do
        assert_equal 'waiting_for_message', sm.state.value
        send_message_to_smooch_bot('Hello', uid)
        assert_equal 'main', sm.state.value
        send_message_to_smooch_bot('What?', uid)
        assert_equal 'main', sm.state.value
        send_message_to_smooch_bot('1', uid)
        assert_equal 'secondary', sm.state.value
        send_message_to_smooch_bot('Hum', uid)
        assert_equal 'secondary', sm.state.value
        send_message_to_smooch_bot('1', uid) # Discards all messages: the user is seeing a resource, which closes the cycle
        assert_equal 'waiting_for_message', sm.state.value
        send_message_to_smooch_bot('Hello again', uid)
        assert_equal 'main', sm.state.value
        send_message_to_smooch_bot('ONE ', uid)
        assert_equal 'secondary', sm.state.value
        send_message_to_smooch_bot('2', uid)
        assert_equal 'query', sm.state.value
        send_message_to_smooch_bot('0', uid) # Discards all messages: the user cancels the process
        assert_equal 'main', sm.state.value
        send_message_to_smooch_bot('Hello for the last time', uid)
        assert_equal 'main', sm.state.value
        send_message_to_smooch_bot('ONE ', uid)
        assert_equal 'secondary', sm.state.value
        send_message_to_smooch_bot('2', uid)
        assert_equal 'query', sm.state.value
      end
    end
    Rails.cache.stubs(:read).returns(nil)
    Rails.cache.stubs(:read).with("smooch:last_message_from_user:#{uid}").returns(Time.now + 10.seconds)
    assert_difference 'ProjectMedia.count' do
      send_message_to_smooch_bot('Query', uid)
    end
    Rails.cache.unstub(:read)
    Sidekiq::Worker.drain_all
    assert_equal 'waiting_for_message', sm.state.value
    assert_equal ['Hello for the last time', 'ONE ', '2', 'Query'], TiplineRequest.last.smooch_data['text'].split(Bot::Smooch::MESSAGE_BOUNDARY).map(&:chomp)
    assert_equal 'Hello for the last time', ProjectMedia.last.text
  end

  test "should save Smooch response error if the request to Smooch API fails" do
    mock_error = SmoochApi::ApiError.new
    SmoochApi::ConversationApi.any_instance.stubs(:post_message).raises(mock_error)
    CheckSentry.expects(:notify)
    response = Bot::Smooch.send_message_to_user(random_string, random_string)
    assert !Bot::Smooch.save_smooch_response(response, create_project_media, Time.now, random_string)
  end

  test "should send message with URL preview" do
    assert_nothing_raised do
      Bot::Smooch.send_message_to_user(random_string, "foo #{random_url} bar")
    end
  end

  test "should get external identifier for user" do
    create_annotation_type_and_fields('Smooch User', { 'Id' => ['Text', false], 'Data' => ['JSON', false] })
    whatsapp_uid = random_string
    whatsapp_data = {
      '_id' => random_string,
      'givenName' => 'Foo',
      'surname' => 'Bar',
      'signedUpAt' => '2019-01-30T03:47:33.740Z',
      'properties' => {},
      'conversationStarted' => true,
      'clients' => [{
        'id' => random_string,
        'active' => true,
        'lastSeen' => '2020-10-01T15:41:20.877Z',
        'platform' => 'whatsapp',
        'displayName' => '+55 12 3456-7890',
        'raw' => { 'from' => '551234567890', 'profile' => { 'name' => 'Foo Bar' } }
      }],
      'pendingClients' => []
    }
    create_dynamic_annotation annotation_type: 'smooch_user', set_fields: { smooch_user_id: whatsapp_uid, smooch_user_data: { raw: whatsapp_data }.to_json }.to_json
    facebook_uid = random_string
    facebook_data = {
      '_id' => random_string,
      'givenName' => 'Foo',
      'surname' => 'Bar',
      'signedUpAt' => '2019-09-07T14:54:39.429Z',
      'properties' => {},
      'conversationStarted' => true,
      'clients' => [{
        'id' => random_string,
        'active' => true,
        'lastSeen' => '2020-10-02T16:37:13.721Z',
        'platform' => 'messenger',
        'displayName' => 'Foo Bar',
        'externalId' => '123456',
        'info' => {
          'avatarUrl' => random_url
        },
        'raw' => {
          'first_name' => 'Foo',
          'last_name' => 'Bar',
          'profile_pic' => random_url,
          'id' => random_string
        }
      }],
      'pendingClients' => []
    }
    create_dynamic_annotation annotation_type: 'smooch_user', set_fields: { smooch_user_id: facebook_uid, smooch_user_data: { raw: facebook_data }.to_json }.to_json
    twitter_uid = random_string
    twitter_data = {
      'clients' => [{
        'id' => random_string,
        'active' => true,
        'lastSeen' => '2020-10-02T16:55:59.211Z',
        'platform' => 'twitter',
        'displayName' => 'Foo Bar',
        'info' => {
          'avatarUrl' => random_url
        },
        'raw' => {
          'location' => random_string,
          'screen_name' => 'foobar',
          'name' => 'Foo Bar',
          'id_str' => random_string,
          'id' => random_string
        }
      }]
    }
    create_dynamic_annotation annotation_type: 'smooch_user', set_fields: { smooch_user_id: twitter_uid, smooch_user_data: { raw: twitter_data }.to_json }.to_json
    telegram_uid = random_string
    telegram_data = {
      'clients' => [{
        'id' => random_string,
        'active' => true,
        'lastSeen' => '2020-10-02T16:55:59.211Z',
        'platform' => 'telegram',
        'displayName' => 'Bar Foo',
        'info' => {
          'avatarUrl' => random_url
        },
        'raw' => {
          'name' => 'Bar Foo',
          'username' => 'barfoo',
          'id' => random_string
        }
      }]
    }
    create_dynamic_annotation annotation_type: 'smooch_user', set_fields: { smooch_user_id: telegram_uid, smooch_user_data: { raw: telegram_data }.to_json }.to_json
    other_uid = random_string
    other_data = {
      'clients' => [{
        'id' => random_string,
        'active' => true,
        'platform' => 'other',
        'raw' => {
          'id' => random_string
        }
      }]
    }
    create_dynamic_annotation annotation_type: 'smooch_user', set_fields: { smooch_user_id: other_uid, smooch_user_data: { raw: other_data }.to_json }.to_json
    u = create_user is_admin: true
    t = create_team
    with_current_user_and_team(u, t) do
      tr = create_tipline_request team_id: t.id, smooch_message_id: random_string, smooch_data: { 'authorId' => whatsapp_uid }
      assert_equal '+55 12 3456-7890', tr.smooch_user_external_identifier
      tr = create_tipline_request team_id: t.id,smooch_message_id: random_string, smooch_data: { 'authorId' => twitter_uid }
      assert_equal '@foobar', tr.smooch_user_external_identifier
      tr = create_tipline_request team_id: t.id, smooch_message_id: random_string, smooch_data: { 'authorId' => facebook_uid }
      assert_equal '123456', tr.smooch_user_external_identifier
      tr = create_tipline_request team_id: t.id, smooch_message_id: random_string, smooch_data: { 'authorId' => telegram_uid }
      assert_equal '@barfoo', tr.smooch_user_external_identifier
      tr = create_tipline_request team_id: t.id, smooch_message_id: random_string, smooch_data: { 'authorId' => other_uid }
      assert_equal '', tr.smooch_user_external_identifier
    end
  end

  test "should get external Smooch identifier" do
    uid = random_string
    id = Digest::MD5.hexdigest(uid)
    assert_equal id, Bot::Smooch.get_identifier({ clients: [{ platform: 'telegram' }] }, uid)
    assert_equal Digest::MD5.hexdigest('123456'), Bot::Smooch.get_identifier({ clients: [{ platform: 'viber', 'raw' => { 'avatar' => 'http://viber/dlid=123456&foo=bar' }}] }, uid)
    assert_equal Digest::MD5.hexdigest('123456'), Bot::Smooch.get_identifier({ clients: [{ platform: 'line', 'raw' => { 'pictureUrl' => 'https://sprofile.line-scdn.net/123456' }}] }, uid)
  end

  test "should load articles from RSS feed" do
    url = random_url
    rss = %{
      <rss xmlns:atom="http://www.w3.org/2005/Atom" version="2.0">
        <channel>
          <title>Test</title>
          <link>http://test.com/rss.xml</link>
          <description>Test</description>
          <language>en</language>
          <lastBuildDate>Fri, 09 Oct 2020 18:00:48 GMT</lastBuildDate>
          <managingEditor>test@test.com (editors)</managingEditor>
          <item>
            <title>Foo</title>
            <description>This is the description.</description>
            <pubDate>Wed, 11 Apr 2018 15:25:00 GMT</pubDate>
            <link>http://foo</link>
          </item>
          <item>
            <title>Bar</title>
            <description>This is the description.</description>
            <pubDate>Wed, 10 Apr 2018 15:25:00 GMT</pubDate>
            <link>http://bar</link>
          </item>
        </channel>
      </rss>
    }
    WebMock.stub_request(:get, url).to_return(status: 200, body: rss)
    tr = create_tipline_resource title: 'Test', rss_feed_url: url, content_type: 'rss', number_of_articles: 2, content: ''
    output = "*Test*\n\nFoo\nhttp://foo\n\nBar\nhttp://bar"
    assert_equal output, tr.format_as_tipline_message
    Rails.cache.clear
    WebMock.stub_request(:get, url).to_return(status: 404, body: 'not valid RSS')
    assert_raises RssFeed::RssLoadError do
      tr.format_as_tipline_message
    end
  end

  test "should not strictly validate RSS feed" do
    url = random_url
    rss = %{
      <rss xmlns:atom="http://www.w3.org/2005/Atom" version="2.0">
        <channel>
          <title>
            Test
          </title>
          <link>http://test.com/rss.xml</link>
          <description>
          Test</description>
          <language>en</language>
          <lastBuildDate>Fri, 09 Oct 2020 18:00:48 GMT</lastBuildDate>
          <managingEditor>test@test.com (editors)</managingEditor>
          <item>
            <title>Foo
            </title>
            <description>This is the description.</description>
            <pubDate>Wed, 11 Apr 2018 15:25:00 GMT</pubDate>
            <link>http://foo</link>
            <enclosure>http://foo/foo.jpg</enclosure>
          </item>
          <item>
            <title>
              Bar
            </title>
            <description>This is the description.</description>
            <pubDate>Wed, 10 Apr 2018 15:25:00 GMT</pubDate>
            <link>http://bar</link>
            <enclosure>http://bar/bar.jpg</enclosure>
          </item>
        </channel>
      </rss>
    }
    WebMock.stub_request(:get, url).to_return(status: 200, body: rss)
    tr = create_tipline_resource title: 'Test', rss_feed_url: url, content_type: 'rss', number_of_articles: 2, content: ''
    output = "*Test*\n\nFoo\nhttp://foo\n\nBar\nhttp://bar"
    assert_equal output, tr.format_as_tipline_message
  end

  test "should request resource" do
    setup_smooch_bot(true)
    uid = random_string
    rss = '<rss version="1"><channel><title>x</title><link>x</link><description>x</description><item><title>x</title><link>x</link></item></channel></rss>'
    WebMock.stub_request(:get, 'http://test.com/feed.rss').to_return(status: 200, body: rss)
    Sidekiq::Testing.fake! do
      send_message_to_smooch_bot('Hello', uid)
      send_message_to_smooch_bot('1', uid)
      send_message_to_smooch_bot('4', uid)
    end
    Sidekiq::Worker.drain_all
    tr = TiplineRequest.last
    assert_equal 'TiplineResource', tr.associated_type
    assert_not_nil tr.smooch_resource_id
  end

  test "should submit short unconfirmed request" do
    setup_smooch_bot(true)
    RequestStore.store[:skip_cached_field_update] = false
    uid = random_string
    message = "Hey ho, let's go"
    Sidekiq::Testing.fake! do
      send_message_to_smooch_bot('Hello', uid)
      send_message_to_smooch_bot(message, uid)
    end
    assert_no_difference 'ProjectMedia.count' do
      Sidekiq::Worker.drain_all
    end
    tr = TiplineRequest.last
    assert_equal 'Team', tr.associated_type
  end

  test "should submit long unconfirmed request" do
    setup_smooch_bot(true)
    RequestStore.store[:skip_cached_field_update] = false
    uid = random_string
    message = 'This is a message that has enough words to be considered a media'
    Sidekiq::Testing.fake! do
      send_message_to_smooch_bot('Hello', uid)
      send_message_to_smooch_bot(message, uid)
    end
    assert_difference 'ProjectMedia.count' do
      Sidekiq::Worker.drain_all
    end
    tr = TiplineRequest.last
    associated = tr.associated
    assert_equal 'ProjectMedia', tr.associated_type
    assert_equal CheckArchivedFlags::FlagCodes::UNCONFIRMED, associated.archived
    # Verify requests count & demand
    assert_equal 1, associated.requests_count
    assert_equal 1, associated.demand
    # Auto confirm the media if the same media is sent as a default request
    Sidekiq::Testing.fake! do
      send_message_to_smooch_bot(message, uid)
      send_message_to_smooch_bot('1', uid)
      send_message_to_smooch_bot('2', uid)
    end
    Rails.cache.stubs(:read).returns(nil)
    Rails.cache.stubs(:read).with("smooch:last_message_from_user:#{uid}").returns(Time.now + 10.seconds)
    assert_no_difference 'ProjectMedia.count' do
      send_message_to_smooch_bot('Query', uid)
    end
    Rails.cache.unstub(:read)
    Sidekiq::Worker.drain_all
    assert_equal CheckArchivedFlags::FlagCodes::NONE, associated.reload.archived
    assert_equal 2, associated.reload.requests_count
    # Test resend the same media (should not update archived column)
    Sidekiq::Testing.fake! do
      send_message_to_smooch_bot('Hello', uid)
      send_message_to_smooch_bot(message, uid)
    end
    assert_no_difference 'ProjectMedia.count' do
      Sidekiq::Worker.drain_all
    end
    assert_equal CheckArchivedFlags::FlagCodes::NONE, associated.reload.archived
    assert_equal 3, associated.reload.requests_count
  end

  test "should get default TOS message" do
    assert_kind_of String, Bot::Smooch.get_message_for_language(Bot::Smooch::GREETING, 'en')
    assert_kind_of String, Bot::Smooch.get_string('privacy_and_purpose', 'en')
  end

  test "should sanitize settings" do
    i = @installation.deep_dup
    assert_not_nil i.settings['smooch_app_id']
    Bot::Smooch.sanitize_installation(i, true)
    assert_nil i.settings['smooch_app_id']
  end

  test "should not create duplicated project media and media on team" do
    Sidekiq::Testing.inline! do
      # Video
      message = {
        type: 'file',
        text: random_string,
        mediaUrl: @video_url,
        mediaType: 'video/mp4',
        source: { type: "whatsapp" },
        role: 'appUser',
        received: 1573082583.219,
        name: random_string,
        authorId: random_string,
        '_id': random_string,
        language: 'en'
      }
      medias_count = Media.count
      assert_difference 'ProjectMedia.count', 1 do
        Bot::Smooch.save_message(message.to_json, @app_id)
      end
      pm = ProjectMedia.last

      assert_equal medias_count + 1, Media.count
      medias_count = Media.count

      assert_no_difference 'ProjectMedia.count' do
        Bot::Smooch.save_message(message.to_json, @app_id)
      end
      assert_equal medias_count, Media.count
    end
  end

  test "should normalize text for tipline queries" do
    Sidekiq::Testing.inline! do
      text  = "\vstring      for testing\t\n  "
      message = {
        type: 'text',
        source: { type: "whatsapp" },
        text: text,
        authorId: random_string,
        '_id': random_string,
        language: 'en',
      }
      assert_difference 'ProjectMedia.count', 1 do
        Bot::Smooch.save_message(message.to_json, @app_id)
      end
      pm = ProjectMedia.last
      assert_equal 'string for testing', pm.media.quote
      text  = "\vstring      FOR teSTIng\t\n  "
      message = {
        type: 'text',
        source: { type: "whatsapp" },
        text: text,
        authorId: random_string,
        '_id': random_string,
        language: 'en',
      }
      assert_no_difference 'ProjectMedia.count' do
        Bot::Smooch.save_message(message.to_json, @app_id)
      end
      # test with existing items
      pm = create_project_media team: @team, quote: '  test with Existing ITEM'
      text  = "\vTEST      with existing     item  \t\n  "
      message = {
        type: 'text',
        source: { type: "whatsapp" },
        text: text,
        authorId: random_string,
        '_id': random_string,
        language: 'en',
      }
      assert_no_difference 'ProjectMedia.count' do
        Bot::Smooch.save_message(message.to_json, @app_id)
      end
    end
  end

  test "should send only visual card to user" do
    pm = create_project_media
    publish_report(pm, {}, nil, { use_text_message: false })
    assert_nothing_raised do
      Bot::Smooch.send_report_to_user(random_string, { 'received' => Time.now.to_i }, pm, 'report')
    end
  end

  test "should search for longest string between query and URL description" do
    ProjectMedia.any_instance.stubs(:report_status).returns('published')

    t = create_team
    pm1 = create_project_media team: t
    pm2 = create_project_media team: t
    url = 'http://test.com'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item","description":"Foo bar"}}'
    WebMock.stub_request(:get, pender_url).with(query: { url: url }).to_return(body: response)
    Bot::Smooch.stubs(:bundle_list_of_messages).returns({ 'type' => 'text', 'text' => "Foo bar foo bar #{url}" })
    CheckSearch.any_instance.stubs(:medias).returns([pm1])
    Bot::Alegre.stubs(:get_merged_similar_items).returns({ pm2.id => { score: 0.9, model: 'elasticsearch', context: {foo: :bar} } })

    uid = random_string
    query = Bot::Smooch.get_search_query(uid, {})
    assert_equal [pm2], Bot::Smooch.get_search_results(uid, query, t.id, 'en', 3)
    Bot::Smooch.stubs(:bundle_list_of_messages).returns({ 'type' => 'text', 'text' => "Test #{url}" })
    query = Bot::Smooch.get_search_query(uid, {})
    assert_equal [pm1], Bot::Smooch.get_search_results(uid, query, t.id, 'en', 3)

    ProjectMedia.any_instance.unstub(:report_status)
    CheckSearch.any_instance.unstub(:medias)
    Bot::Smooch.unstub(:bundle_list_of_messages)
    Bot::Alegre.unstub(:get_merged_similar_items)
  end

  test "should search by URL" do
    t = create_team
    f = create_feed published: true
    f.teams << t
    FeedTeam.update_all(shared: true)

    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"http://projetocomprova.com.br/publicações/tuite-engana-ao-dizer-que-o-stf-decidiu-que-voto-impresso-e-inconstitucional/","type":"item","title":"Foo","description":"Bar"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: 'https://projetocomprova.com.br/publica%C3%A7%C3%B5es/tuite-engana-ao-dizer-que-o-stf-decidiu-que-voto-impresso-e-inconstitucional/' } }).to_return(body: response)

    assert_nothing_raised do
      with_current_user_and_team(nil, t) do
        Bot::Smooch.search_for_similar_published_fact_checks('text', 'https://projetocomprova.com.br/publicações/tuite-engana-ao-dizer-que-o-stf-decidiu-que-voto-impresso-e-inconstitucional/ ', [t.id], 3, nil, f.id)
      end
    end
  end

  test "should resend newsletter after Facebook Messenger 24-hours window" do
    WebMock.stub_request(:get, 'http://test.com/feed.rss').to_return(body: '<rss></rss>')
    msgid = random_string
    response = OpenStruct.new({ body: OpenStruct.new(message: OpenStruct.new({ id: msgid })) })
    Bot::Smooch.save_smooch_response(response, nil, random_string, 'newsletter', 'en', { message: random_string })
    message = {
      app: {
        '_id': @app_id
      },
      appUser: {
        '_id': random_string,
      },
      message: {
        '_id': msgid
      },
      destination: {
        type: 'messenger'
      }
    }.to_json
    assert Bot::Smooch.resend_message_after_window(message)
  end
end
