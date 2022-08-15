require_relative '../../test_helper'
require 'sidekiq/testing'

class Bot::SmoochTest < ActiveSupport::TestCase
  def setup
    super
    setup_smooch_bot
  end

  def teardown
    super
    CONFIG.unstub(:[])
    Bot::Smooch.unstub(:get_language)
  end

  test "should be valid only if the API key is valid" do
    assert !Bot::Smooch.valid_request?(OpenStruct.new(headers: {}, params: {}))
    assert !Bot::Smooch.valid_request?(OpenStruct.new(headers: { 'X-API-Key' => 'foo' }, params: {}))
    assert Bot::Smooch.valid_request?(OpenStruct.new(headers: { 'X-API-Key' => 'test' }, params: {}))
  end

  test "should validate JSON schema" do
    payload = '{"trigger":"message:appUser","app":{"_id":"' + @app_id + '"},"version":"v1.1","messages":[{"type":"text","text":"This is a test","role":"appUser","received":1546269763.141,"name":"Foo Bar","authorId":"22bd83d736b4eb15eec863ec","_id":"6d3b3443c03bb3111e88c6ec","source":{"type":"whatsapp","integrationId":"6d193e6d91130000222756e4"}}],"appUser":{"_id":"22bd83d736b4eb15eec863ec","conversationStarted":true}}'
    assert Bot::Smooch.run(payload)
    payload = '{"trigger":"message:appUser","app":{"_id":"' + @app_id + '"},"version":"v1.1","messages":[{"text":"This is a test","role":"appUser","received":1546269763.141,"name":"Foo Bar","authorId":"22bd83d736b4eb15eec863ec","_id":"6d3b3443c03bb3111e88c6ec","source":{"type":"whatsapp","integrationId":"6d193e6d91130000222756e4"}}],"appUser":{"_id":"22bd83d736b4eb15eec863ec","conversationStarted":true}}'
    assert !Bot::Smooch.run(payload)
    assert !Bot::Smooch.run('not a json')
  end

  test "should add channel for smooch bot" do
    payload = '{"trigger":"message:appUser","app":{"_id":"' + @app_id + '"},"version":"v1.1","messages":[{"type":"text","text":"This is a test","role":"appUser","received":1546269763.141,"name":"Foo Bar","authorId":"22bd83d736b4eb15eec863ec","_id":"6d3b3443c03bb3111e88c6ec","source":{"type":"whatsapp","integrationId":"6d193e6d91130000222756e4"}}],"appUser":{"_id":"22bd83d736b4eb15eec863ec","conversationStarted":true}}'
    assert Bot::Smooch.run(payload)
    # Verirfy channel value
    assert CheckChannels::ChannelCodes::WHATSAPP, ProjectMedia.last.channel
    payload = '{"trigger":"message:appUser","app":{"_id":"' + @app_id + '"},"version":"v1.1","messages":[{"type":"audio", "mediaUrl":"' + @audio_url + '","text":"This is a test","role":"appUser","received":1546269763.141,"name":"Foo Bar","authorId":"22bd83d736b4eb15eec863ec","_id":"6d3b3443c03bb3111e88c6ec","source":{"type":"messenger","integrationId":"6d193e6d91130000222756e4"}}],"appUser":{"_id":"22bd83d736b4eb15eec863ec","conversationStarted":true}}'
    assert Bot::Smooch.run(payload)
    # Verirfy channel value
    assert CheckChannels::ChannelCodes::MESSENGER, ProjectMedia.last.channel
  end

  test "should catch Smooch exception" do
    SmoochApi::ConversationApi.any_instance.stubs(:post_message).raises(SmoochApi::ApiError)
    assert_nothing_raised do
      Bot::Smooch.send_message_to_user(random_string, random_string)
    end
  end

  test "should not save message of unsupported type" do
    assert_no_difference 'Annotation.count' do
      Bot::Smooch.save_message({ 'type' => 'invalid' }.to_json, @app_id)
    end
  end

  test "should process messages" do
    id = random_string
    id2 = random_string
    id3 = random_string
    messages = [
      {
        '_id': random_string,
        authorId: id2,
        type: 'audio',
        text: random_string,
        mediaUrl: @audio_url
      },
      {
        '_id': random_string,
        authorId: id,
        type: 'text',
        text: 'This is a test claim'
      },
      {
        '_id': random_string,
        authorId: id,
        type: 'image',
        text: random_string,
        mediaUrl: @media_url
      },
      {
        '_id': random_string,
        authorId: id,
        type: 'text',
        text: "#{random_string} #{@link_url} #{random_string}"
      },
      {
        '_id': random_string,
        authorId: id,
        type: 'text',
        text: 'This is a test claim'
      },
      {
        '_id': random_string,
        authorId: id,
        type: 'image',
        text: random_string,
        mediaUrl: @media_url
      },
      {
        '_id': random_string,
        authorId: id,
        type: 'text',
        text: "#{random_string} #{@link_url} #{random_string}"
      },
      {
        '_id': random_string,
        authorId: id2,
        type: 'text',
        text: 'This is a test claim'
      },
      {
        '_id': random_string,
        authorId: id2,
        type: 'image',
        text: random_string,
        mediaUrl: @media_url
      },
      {
        '_id': random_string,
        authorId: id3,
        type: 'file',
        text: random_string,
        mediaUrl: @media_url,
        mediaType: 'image/jpeg'
      },
      {
        '_id': random_string,
        authorId: id3,
        type: 'file',
        text: random_string,
        mediaUrl: @media_url,
        mediaType: 'application/pdf'
      },
      {
        '_id': random_string,
        authorId: id2,
        type: 'text',
        text: "#{random_string} #{@link_url} #{random_string}"
      },
      {
        '_id': random_string,
        authorId: id2,
        type: 'text',
        text: 'This is a test claim'
      },
      {
        '_id': random_string,
        authorId: id2,
        type: 'image',
        text: random_string,
        mediaUrl: @media_url
      },
      {
        '_id': random_string,
        authorId: id2,
        type: 'video',
        text: random_string,
        mediaUrl: @video_url
      },
      {
        '_id': random_string,
        authorId: id2,
        type: 'text',
        text: "#{random_string} #{@link_url} #{random_string}"
      },
      {
        '_id': random_string,
        authorId: id2,
        type: 'text',
        text: "#{random_string} #{@link_url_2} #montag #{random_string}"
      },
      {
        '_id': random_string,
        authorId: id3,
        type: 'text',
        text: "#{random_string} #{@link_url_2.gsub(/^https?:\/\//, '')} #teamtag #{random_string}"
      },
      {
        '_id': random_string,
        authorId: id2,
        type: 'text',
        text: 'This #teamtag is another #hashtag claim'
      },
      {
        '_id': random_string,
        authorId: id3,
        type: 'text',
        text: 'This #teamtag is another #hashtag CLAIM'
      },
      {
        '_id': random_string,
        authorId: id3,
        type: 'file',
        text: random_string,
        mediaUrl: @video_url,
        mediaType: 'video/mp4'
      },
      {
        '_id': random_string,
        authorId: id3,
        type: 'file',
        text: random_string,
        mediaUrl: @audio_url,
        mediaType: 'audio/mpeg'
      }
    ]

    create_tag_text text: 'teamtag', team_id: @team.id
    create_tag_text text: 'montag', team_id: @team.id

    assert_difference 'ProjectMedia.count', 7 do
      assert_difference 'Annotation.where(annotation_type: "smooch").count', 22 do
        assert_no_difference 'Comment.length' do
          messages.each do |message|
            uid = message[:authorId]

            message = {
              trigger: 'message:appUser',
              app: {
                '_id': @app_id
              },
              version: 'v1.1',
              messages: [message],
              appUser: {
                '_id': uid,
                'conversationStarted': true
              }
            }.to_json

            ignore = {
              trigger: 'message:appUser',
              app: {
                '_id': @app_id
              },
              version: 'v1.1',
              messages: [
                {
                  '_id': random_string,
                  authorId: uid,
                  type: 'text',
                  text: '2'
                }
              ],
              appUser: {
                '_id': uid,
                'conversationStarted': true
              }
            }.to_json

            assert Bot::Smooch.run(message)
          end
        end
      end
    end

    pms = ProjectMedia.order("id desc").limit(5).reverse
    assert_equal 1, pms[4].annotations.where(annotation_type: 'tag').count
    assert_equal 'teamtag', pms[4].annotations.where(annotation_type: 'tag').last.load.data[:tag].text
    assert_equal 2, pms[3].annotations.where(annotation_type: 'tag').count
  end

  test "should ignore unsupported message triggers" do
    payload = {
      trigger: 'unsupported:Trigger',
      app: {
        '_id': @app_id
      },
      version: 'v1.1',
      appUser: {
        '_id': random_string,
        'conversationStarted': true
      }
    }.to_json
    assert !Bot::Smooch.run(payload)
  end

  test "should resend message if it fails" do
    uid = random_string

    messages = [
      {
        '_id': random_string,
        authorId: uid,
        type: 'text',
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

    assert Bot::Smooch.run(payload)

    pm = ProjectMedia.last
    r = publish_report(pm)

    payload = {
      trigger: 'message:delivery:failure',
      app: {
        '_id': @app_id
      },
      version: 'v1.1',
      appUser: {
        '_id': uid,
        conversationStarted: true
      },
      error: {
        code: 'uncategorized_error',
        underlyingError: {
          errors: [
            {
              code: 470,
              title: 'Failed to send message because you are outside the support window for freeform messages to this user. Please use a valid HSM notification or reconsider.'
            }
          ]
        }
      },
      message: {
        '_id': @msg_id
      },
      timestamp: Time.now.to_f
    }.to_json

    assert Bot::Smooch.run(payload)
  end

  test "should have different configurations per thread" do
    threads = []
    threads << Thread.start do
      RequestStore.store[:smooch_bot_settings] = { 'test' => 1 }
      assert_equal 1, Bot::Smooch.config['test']
    end
    threads << Thread.start do
      RequestStore.store[:smooch_bot_settings] = { 'test' => 2 }
      assert_equal 2, Bot::Smooch.config['test']
    end
    threads.map(&:join)
  end

  test "should not get invalid URL" do
    assert_nil Bot::Smooch.extract_url('foo http://\foo.bar bar')
    assert_nil Bot::Smooch.extract_url('foo https://news...')
    assert_nil Bot::Smooch.extract_url('foo https://ha..?')
    assert_nil Bot::Smooch.extract_url('foo https://30th-JUNE-2019.*')
    assert_nil Bot::Smooch.extract_url('foo https://...')
    assert_nil Bot::Smooch.extract_url('foo https://*1.*')
  end

  test "should send report to user" do
    text = random_string
    uid = random_string
    child1 = create_project_media project: @project
    u = create_user
    messages = [
      {
        '_id': random_string,
        authorId: uid,
        type: 'text',
        text: text
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
    Bot::Smooch.run(payload)
    sleep 1
    pm = ProjectMedia.last
    pm.archived = CheckArchivedFlags::FlagCodes::NONE
    pm.save!
    create_relationship source_id: pm.id, target_id: child1.id, user: u
    r = create_report(pm)
    pa1 = r.reload.get_field_value('last_published')
    assert !r.reload.report_design_field_value('visual_card_url', 'en')
    r = Dynamic.find(r.id)
    r.save!
    assert !r.reload.report_design_field_value('visual_card_url', 'en')
    publish_report(pm, {}, r)
    assert r.reload.report_design_field_value('visual_card_url', 'en')
    pa2 = r.reload.get_field_value('last_published')
    assert_not_equal pa1.to_s, pa2.to_s
    s = pm.annotations.where(annotation_type: 'verification_status').last.load
    s.status = 'in_progress'
    assert_raises RuntimeError do
      s.save!
    end
    r = Dynamic.find(r.id)
    r.set_fields = { state: 'paused' }.to_json
    r.action = 'pause'
    r.save!
    s.reload.save!
    assert_equal 'In Progress', r.reload.report_design_field_value('status_label', 'en')
    assert_not_equal 'In Progress', r.reload.report_design_field_value('previous_published_status_label', 'en')
    r = Dynamic.find(r.id)
    r.set_fields = { state: 'published' }.to_json
    r.action = 'republish_and_resend'
    r.save!
    pa3 = r.reload.get_field_value('last_published')
    assert_not_equal pa2.to_s, pa3.to_s
  end

  test "should get language" do
    stub_request(:post, "http://alegre/text/langid/").
    with(
      body: "{\"text\":\"This is just a test\"}",
      headers: {
  	  'Accept'=>'*/*',
  	  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
  	  'Content-Type'=>'application/json',
  	  'User-Agent'=>'Ruby'
      }).
    to_return(status: 200, body: "", headers: {})
    Bot::Smooch.unstub(:get_language)
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      WebMock.stub_request([:get, :post], 'http://alegre/text/langid/').to_return(body: {
        'result': {
          'language': 'en',
          'confidence': 1.0
        }
      }.to_json)
      WebMock.disable_net_connect! allow: [CheckConfig.get('elasticsearch_host')]
      assert_equal 'en', Bot::Smooch.get_language({ 'text' => 'This is just a test' })
    end
  end

  test "should send the status that triggered the event" do
    Sidekiq::Worker.clear_all
    uid = random_string

    messages = [
      {
        '_id': random_string,
        authorId: uid,
        type: 'text',
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

    assert Bot::Smooch.run(payload)

    Sidekiq::Testing.fake! do
      pm = ProjectMedia.last
      s = pm.annotations.where(annotation_type: 'verification_status').last.load
      s.status = 'verified'
      s.save!
      s = Annotation.find(s.id).load
      s.status = 'in_progress'
      s.save!
      I18n.expects(:t).with do |first_arg, second_arg|
        [:smooch_bot_result, 'mails_notifications.media_status.subject', :error_project_archived].include?(first_arg)
      end.at_least_once
      I18n.stubs(:t)
      I18n.expects(:t).with('statuses.media.verified.label', { locale: 'en' }).once
      I18n.expects(:t).with('statuses.media.in_progress.label', { locale: 'en' }).never
      Sidekiq::Worker.drain_all
      I18n.unstub(:t)
    end
  end

  test "should save when user receives report" do
    uid = random_string

    messages = [
      {
        '_id': random_string,
        authorId: uid,
        type: 'text',
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

    assert Bot::Smooch.run(payload)

    pm = ProjectMedia.last
    sm = pm.get_annotations('smooch').last
    df = DynamicAnnotation::Field.where(annotation_id: sm.id, field_name: 'smooch_data').last
    assert_not_nil df
    assert_equal 0, df.reload.smooch_report_received_at
    assert_nil df.reload.smooch_report_update_received_at
    r = publish_report(pm)
    assert_equal 0, r.reload.sent_count
    msg_id = random_string
    original = Rails.cache.write("smooch:original:#{msg_id}", {
      fallback_template: 'fact_check_report',
      project_media_id: pm.id
    }.to_json)
    assert_nil DynamicAnnotation::Field.where(field_name: 'smooch_report_received').last
    
    payload = {
      trigger: 'message:delivery:channel',
      app: {
        '_id': @app_id
      },
      version: 'v1.1',
      appUser: {
        '_id': uid,
        conversationStarted: true
      },
      message: {
        '_id': msg_id
      },
      timestamp: Time.now.to_f
    }.to_json

    assert Bot::Smooch.run(payload)
    f1 = DynamicAnnotation::Field.where(field_name: 'smooch_report_received').last
    assert_not_nil f1
    t1 = f1.value
    assert_equal t1, df.reload.smooch_report_received_at
    assert_nil df.reload.smooch_report_update_received_at
    assert_equal 1, r.reload.sent_count

    sleep 1

    assert Bot::Smooch.run(payload)
    f2 = DynamicAnnotation::Field.where(field_name: 'smooch_report_received').last
    assert_equal f1, f2
    t2 = f2.value
    assert_equal t2, df.reload.smooch_report_received_at
    assert_equal t2, df.reload.smooch_report_update_received_at
    assert_equal 1, r.reload.sent_count

    assert t2 > t1
  end

  test "should add utm_source parameter to URLs" do
    input = 'Go to https://x.com and http://meedan.com/?lang=en and http://meedan.com/en/website?a=1&b=2 and http://meedan.com/en/ and http://meedan.com/en and finally meedan.com. Thanks.Everyone !'
    expected = 'Go to https://x.com?utm_source=check_test and http://meedan.com/?lang=en&utm_source=check_test and http://meedan.com/en/website?a=1&b=2&utm_source=check_test and http://meedan.com/en/?utm_source=check_test and http://meedan.com/en?utm_source=check_test and finally meedan.com?utm_source=check_test. Thanks.Everyone !'
    output = Bot::Smooch.utmize_urls(input, 'test')
    assert_equal expected, output

    URI.stubs(:parse).raises(RuntimeError)
    input = 'Test http://meedan.com'
    output = Bot::Smooch.utmize_urls(input, 'test')
    assert_equal input, output
    URI.unstub(:parse)
  end

  test "should send message on status change" do
    value = {
      label: 'Field label',
      active: '2',
      default: '1',
      statuses: [
        { id: '1', locales: { en: { label: 'Custom Status 1', description: 'The meaning of this status' } }, style: { color: 'red' } },
        { id: '2', should_send_message: true, locales: { en: { label: 'Custom Status 2', description: 'The meaning of that status', message: 'Custom' } }, style: { color: 'blue' } }
      ]
    }
    @team.set_media_verification_statuses(value)
    @team.save!
    uid = random_string
    messages = [
      {
        '_id': random_string,
        authorId: uid,
        type: 'text',
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
    assert Bot::Smooch.run(payload)
    pm = ProjectMedia.last
    Bot::Smooch.stubs(:send_message_to_user).with(uid, 'Custom').once
    s = pm.annotations.where(annotation_type: 'verification_status').last.load
    s.status = '2'
    s.save!
    Bot::Smooch.unstub(:send_message_to_user)
  end

  test "should return user request language" do
    uid = random_string
    messages = [
      {
        '_id': random_string,
        authorId: uid,
        type: 'text',
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
    assert Bot::Smooch.run(payload)
    pm = ProjectMedia.last
    sm = pm.get_annotations('smooch').last.load
    f = sm.get_field('smooch_data')
    assert_equal 'en', f.smooch_user_request_language
  end

  test "should get turn.io installation" do
    @installation.set_turnio_secret = 'secret'
    @installation.set_turnio_token = 'token'
    @installation.save!
    assert_equal @installation, Bot::Smooch.get_turnio_installation('PzqzmGtlarsXrz6xRD7WwI74//n+qDkVkJ0bQhrsib4=', '{"foo":"bar"}')
  end

  test "should send message to turn.io user" do
    @installation.set_turnio_secret = 'test'
    @installation.set_turnio_phone = 'test'
    @installation.set_turnio_token = 'token'
    @installation.save!
    Bot::Smooch.get_installation('turnio_secret', 'test')
    WebMock.stub_request(:post, 'https://whatsapp.turn.io/v1/messages').to_return(status: 200, body: '{}')
    assert_not_nil Bot::Smooch.turnio_send_message_to_user('test:123456', 'Test')
    WebMock.stub_request(:post, 'https://whatsapp.turn.io/v1/messages').to_return(status: 404, body: '{}')
    assert_nil Bot::Smooch.turnio_send_message_to_user('test:123456', 'Test 2')
  end

  test "should resend turn.io message" do
    WebMock.stub_request(:post, 'https://whatsapp.turn.io/v1/messages').to_return(status: 200, body: '{}')
    @installation.set_turnio_secret = 'test'
    @installation.set_turnio_phone = 'test'
    @installation.set_turnio_token = 'test'
    @installation.save!
    Bot::Smooch.get_installation('turnio_secret', 'test')
    pm = create_project_media team: @team
    publish_report(pm)
    Rails.cache.write('smooch:original:987654', { project_media_id: pm.id, fallback_template: 'fact_check_report_text_only', language: 'en', query_date: Time.now.to_i }.to_json)
    payload = { statuses: [{ id: '987654', recipient_id: '123456', status: 'failed', timestamp: Time.now.to_i.to_s }]}
    assert Bot::Smooch.run(payload.to_json)
  end

  test "should send media message to turn.io user" do
    @installation.set_turnio_secret = 'test'
    @installation.set_turnio_phone = 'test'
    @installation.set_turnio_token = 'token'
    @installation.save!
    Bot::Smooch.get_installation('turnio_secret', 'test')
    WebMock.stub_request(:post, 'https://whatsapp.turn.io/v1/messages').to_return(status: 200, body: '{}')
    WebMock.stub_request(:post, 'https://whatsapp.turn.io/v1/media').to_return(status: 200, body: { media: [{ id: random_string }] }.to_json)
    url = random_url
    WebMock.stub_request(:get, url).to_return(status: 200, body: File.read(File.join(Rails.root, 'test', 'data', 'rails.png')))
    assert_not_nil Bot::Smooch.turnio_send_message_to_user('test:123456', 'Test', { 'type' => 'image', 'mediaUrl' => url })
  end
end
