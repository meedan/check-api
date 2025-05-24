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
    payload = '{"trigger":"message:appUser","app":{"_id":"' + @app_id + '"},"version":"v1.1","messages":[{"type":"text","text":"This is a test","role":"appUser","received":1546269763.141,"name":"Foo Bar","authorId":"22bd83d736b4eb15eec863ec","_id":"6d3b3443c03bb3111e88c6ec1","source":{"type":"whatsapp","integrationId":"6d193e6d91130000222756e4"}}],"appUser":{"_id":"22bd83d736b4eb15eec863ec","conversationStarted":true}}'
    assert Bot::Smooch.run(payload)
    payload = '{"trigger":"message:appUser","app":{"_id":"' + @app_id + '"},"version":"v1.1","messages":[{"text":"This is a test","role":"appUser","received":1546269763.141,"name":"Foo Bar","authorId":"22bd83d736b4eb15eec863ec","_id":"6d3b3443c03bb3111e88c6ec2","source":{"type":"whatsapp","integrationId":"6d193e6d91130000222756e4"}}],"appUser":{"_id":"22bd83d736b4eb15eec863ec","conversationStarted":true}}'
    assert !Bot::Smooch.run(payload)
    assert !Bot::Smooch.run('not a json')
  end

  test "should add channel for smooch bot" do
    payload = '{"trigger":"message:appUser","app":{"_id":"' + @app_id + '"},"version":"v1.1","messages":[{"type":"text","text":"This is a test","role":"appUser","received":1546269763.141,"name":"Foo Bar","authorId":"22bd83d736b4eb15eec863ec","_id":"6d3b3443c03bb3111e88c6ec1","source":{"type":"whatsapp","integrationId":"6d193e6d91130000222756e4"}}],"appUser":{"_id":"22bd83d736b4eb15eec863ec","conversationStarted":true}}'
    assert Bot::Smooch.run(payload)
    # Verirfy channel value
    assert CheckChannels::ChannelCodes::WHATSAPP, ProjectMedia.last.channel
    payload = '{"trigger":"message:appUser","app":{"_id":"' + @app_id + '"},"version":"v1.1","messages":[{"type":"audio", "mediaUrl":"' + @audio_url + '","text":"This is a test","role":"appUser","received":1546269763.141,"name":"Foo Bar","authorId":"22bd83d736b4eb15eec863ec2","_id":"6d3b3443c03bb3111e88c6ec","source":{"type":"messenger","integrationId":"6d193e6d91130000222756e4"}}],"appUser":{"_id":"22bd83d736b4eb15eec863ec","conversationStarted":true}}'
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
        source: { type: "whatsapp" },
        mediaUrl: @audio_url
      },
      {
        '_id': random_string,
        authorId: id,
        type: 'text',
        source: { type: "whatsapp" },
        text: 'This is a test claim'
      },
      {
        '_id': random_string,
        authorId: id,
        type: 'image',
        text: random_string,
        source: { type: "whatsapp" },
        mediaUrl: @media_url
      },
      {
        '_id': random_string,
        authorId: id,
        type: 'text',
        source: { type: "whatsapp" },
        text: "#{random_string} #{@link_url} #{random_string}"
      },
      {
        '_id': random_string,
        authorId: id,
        type: 'text',
        source: { type: "whatsapp" },
        text: 'This is a test claim'
      },
      {
        '_id': random_string,
        authorId: id,
        type: 'image',
        text: random_string,
        source: { type: "whatsapp" },
        mediaUrl: @media_url
      },
      {
        '_id': random_string,
        authorId: id,
        type: 'text',
        source: { type: "whatsapp" },
        text: "#{random_string} #{@link_url} #{random_string}"
      },
      {
        '_id': random_string,
        authorId: id2,
        type: 'text',
        source: { type: "whatsapp" },
        text: 'This is a test claim'
      },
      {
        '_id': random_string,
        authorId: id2,
        type: 'image',
        text: random_string,
        source: { type: "whatsapp" },
        mediaUrl: @media_url
      },
      {
        '_id': random_string,
        authorId: id3,
        type: 'file',
        text: random_string,
        mediaUrl: @media_url,
        source: { type: "whatsapp" },
        mediaType: 'image/jpeg'
      },
      {
        '_id': random_string,
        authorId: id3,
        type: 'file',
        text: random_string,
        mediaUrl: @media_url,
        source: { type: "whatsapp" },
        mediaType: 'application/pdf'
      },
      {
        '_id': random_string,
        authorId: id2,
        type: 'text',
        source: { type: "whatsapp" },
        text: "#{random_string} #{@link_url} #{random_string}"
      },
      {
        '_id': random_string,
        authorId: id2,
        type: 'text',
        source: { type: "whatsapp" },
        text: 'This is a test claim'
      },
      {
        '_id': random_string,
        authorId: id2,
        type: 'image',
        text: random_string,
        source: { type: "whatsapp" },
        mediaUrl: @media_url
      },
      {
        '_id': random_string,
        authorId: id2,
        type: 'video',
        text: random_string,
        source: { type: "whatsapp" },
        mediaUrl: @video_url
      },
      {
        '_id': random_string,
        authorId: id2,
        type: 'text',
        source: { type: "whatsapp" },
        text: "#{random_string} #{@link_url} #{random_string}"
      },
      {
        '_id': random_string,
        authorId: id2,
        type: 'text',
        source: { type: "whatsapp" },
        text: "#{random_string} #{@link_url_2} #montag #{random_string}"
      },
      {
        '_id': random_string,
        authorId: id3,
        type: 'text',
        source: { type: "whatsapp" },
        text: "#{random_string} #{@link_url_2.gsub(/^https?:\/\//, '')} #teamtag #{random_string}"
      },
      {
        '_id': random_string,
        authorId: id2,
        type: 'text',
        source: { type: "whatsapp" },
        text: 'This #teamtag is another #hashtag claim'
      },
      {
        '_id': random_string,
        authorId: id3,
        type: 'text',
        source: { type: "whatsapp" },
        text: 'This #teamtag is another #hashtag CLAIM'
      },
      {
        '_id': random_string,
        authorId: id3,
        type: 'file',
        text: random_string,
        mediaUrl: @video_url,
        source: { type: "whatsapp" },
        mediaType: 'video/mp4'
      },
      {
        '_id': random_string,
        authorId: id3,
        type: 'file',
        text: random_string,
        mediaUrl: @audio_url,
        source: { type: "whatsapp" },
        mediaType: 'audio/mpeg'
      }
    ]

    tt_teamtag = create_tag_text text: 'teamtag', team_id: @team.id
    tt_montag = create_tag_text text: 'montag', team_id: @team.id

    assert_difference 'ProjectMedia.count', 7 do
      assert_difference 'TiplineRequest.count', 22 do
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

    pms = ProjectMedia.order("id desc").limit(5).reverse
    assert_equal 1, pms[4].annotations.where(annotation_type: 'tag').count
    data = pms[4].annotations.where(annotation_type: 'tag').last.load.data
    assert_equal [{'tag' => tt_teamtag.id}], [data]
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
        text: random_string,
        source: { type: "whatsapp" },
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

  test "should send a final failure message with code to Sentry" do
    uid = random_string

    error_hash = {
      code: 'forbidden',
      message: 'Forbidden',
      underlyingError: {
        description: 'Forbidden: user is deactivated',
        error_code: 403,
        ok: 'False'
      }
    }.with_indifferent_access

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
      error: error_hash,
      message: {
        '_id': @msg_id,
      },
      isFinalEvent: true,
      timestamp: Time.now.to_f
    }

    mock_error = mock('error')
    Bot::Smooch::FinalMessageDeliveryError.expects(:new).with('(forbidden) Forbidden').returns(mock_error)
    CheckSentry.expects(:notify).with(mock_error, has_entries(error: error_hash, uid: uid, smooch_app_id: @app_id, timestamp: kind_of(Float)))

    assert Bot::Smooch.run(payload.to_json)
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
    WebMock.disable_net_connect!
    assert_nil Bot::Smooch.extract_url('foo https://news...')
    assert_nil Bot::Smooch.extract_url('foo https://ha..?')
    assert_nil Bot::Smooch.extract_url('foo https://30th-JUNE-2019.*')
    assert_nil Bot::Smooch.extract_url('foo https://...')
    assert_nil Bot::Smooch.extract_url('foo https://*1.*')
    URI.stubs(:parse).raises(URI::InvalidURIError)
    assert_nil Bot::Smooch.extract_url('https://trigger-exception.com')
    URI.unstub(:parse)
  end

  test "should send report to user" do
    text = random_string
    uid = random_string
    child1 = create_project_media team: @team
    u = create_user
    messages = [
      {
        '_id': random_string,
        authorId: uid,
        type: 'text',
        text: text,
        source: { type: "whatsapp" },
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
    assert !r.reload.report_design_field_value('visual_card_url')
    r = Dynamic.find(r.id)
    r.save!
    assert !r.reload.report_design_field_value('visual_card_url')
    publish_report(pm, {}, r)
    assert r.reload.report_design_field_value('visual_card_url')
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
    assert_equal 'In Progress', r.reload.report_design_field_value('status_label')
    assert_not_equal 'In Progress', r.reload.report_design_field_value('previous_published_status_label')
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
        text: random_string,
        source: { type: "whatsapp" },
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
        text: random_string,
        source: { type: "whatsapp" },
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
    tr = pm.tipline_requests.last
    assert_equal 0, tr.reload.smooch_report_received_at
    assert_equal 0, tr.reload.smooch_report_update_received_at
    r = publish_report(pm)
    assert_equal 0, r.reload.sent_count
    msg_id = random_string
    original = Rails.cache.write("smooch:original:#{msg_id}", {
      fallback_template: 'fact_check_report',
      project_media_id: pm.id
    }.to_json)
    assert_equal 0, tr.reload.smooch_report_received_at
    
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
    }

    assert Bot::Smooch.run(payload.to_json)
    assert tr.reload.smooch_report_received_at > 0
    assert_equal 0, tr.reload.smooch_report_update_received_at
    assert_equal 1, r.reload.sent_count
    sleep 1

    # Process TiplineMessage creation in background to avoid duplication exception
    Sidekiq::Testing.fake! do
      assert Bot::Smooch.run(payload.to_json)
      tr2 = pm.tipline_requests.last
      assert_equal tr, tr2
      assert tr2.smooch_report_update_received_at > 0
      assert_equal 1, r.reload.sent_count
    end
  end

  test "should save a single tipline message in background when user receives report" do
    # For full expected response, see docs at
    # https://docs.smooch.io/rest/v1/#trigger---messagedeliverychannel
    payload = {
      trigger: 'message:delivery:channel',
      app: {
        '_id': @app_id
      },
      version: 'v1.1',
      appUser: {
        '_id': random_string,
        conversationStarted: true
      },
      message: {
        '_id': @msg_id
      },
      destination: {
        type: "whatsapp"
      },
      timestamp: 1444348338
    }.to_json

    Sidekiq::Testing.fake! do
      assert_equal TiplineMessage.where(team: @team).count, 0

      # Run with data, see that job is queued but not yet created
      assert_equal 0, SmoochTiplineMessageWorker.jobs.size

      Bot::Smooch.run(payload)

      assert SmoochTiplineMessageWorker.jobs.size > 0
      assert_equal TiplineMessage.where(team: @team).count, 0

      # Verify that TiplineMessage is created in background
      Sidekiq::Worker.drain_all
      assert_equal TiplineMessage.where(team: @team).count, 1

      tm = TiplineMessage.last
      assert_equal @msg_id, tm.external_id
    end

    # Re-run with same data, see that it does not save
    Sidekiq::Testing.inline! do
      Bot::Smooch.run(payload)
      assert_equal TiplineMessage.where(team: @team).count, 1
    end
  end

  test "should save tipline messages in background when user sends a message" do
    user_id = random_string

    # For full expected response, see docs at
    # https://docs.smooch.io/rest/v1/#trigger---messageappuser-text
    payload = {
      "trigger": "message:appUser",
      "app": {
          "_id": @app_id
      },
      "messages": [
        {
          "_id": @msg_id,
          "authorId": user_id,
          "received": 1444348338.704,
          "type": "text",
          "source": {
              "type": "whatsapp"
          }
        }
      ],
      "appUser": {
          "_id": user_id,
          "conversationStarted": true
      },
      version: 'v1.1'
    }.to_json

    Sidekiq::Testing.fake! do
      assert_equal TiplineMessage.where(team: @team).count, 0

      # Run with data, see that job is queued but not yet created
      assert_equal 0, SmoochTiplineMessageWorker.jobs.size

      Bot::Smooch.run(payload)

      assert SmoochTiplineMessageWorker.jobs.size > 0
      assert_equal 0, TiplineMessage.where(team: @team).count

      # Verify that TiplineMessage is created in background
      Sidekiq::Worker.drain_all
      assert_equal 2, TiplineMessage.where(team: @team).count
      assert_not_empty TiplineMessage.where(team: @team).map(&:external_id).uniq
    end
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
        text: random_string,
        source: { type: "whatsapp" },
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
    Bot::Smooch.stubs(:send_message_to_user).with(uid, 'Custom', {}, false, true, 'status_change').once
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
        text: random_string,
        source: { type: "whatsapp" },
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
    tr = pm.tipline_requests.last
    assert_equal 'en', tr.smooch_user_request_language
  end

  test "should submit message for factchecking" do
    Bot::Smooch.stubs(:is_v2?).returns(true)
    state='main'

    # Should not be a submission shortcut
    message = {"text"=>"abc"}
    assert_equal(false, Bot::Smooch.is_a_shortcut_for_submission?(state,message), "Unexpected shortcut")

    # Should be a submission shortcut
    message = {"text"=>"abc http://example.com"}
    assert_equal(true, Bot::Smooch.is_a_shortcut_for_submission?(state,message), "Missed URL shortcut")

    # Should be a submission shortcut
    message = {"text"=>"abc", "mediaUrl"=>"not blank"}
    assert_equal(true, Bot::Smooch.is_a_shortcut_for_submission?(state,message), "Missed media shortcut")

    # Should be a submission shortcut
    message = {"text"=>"abc example.com"}
    assert_equal(true, Bot::Smooch.is_a_shortcut_for_submission?(state,message), "Missed non-qualified URL shortcut")

    Bot::Smooch.unstub(:is_v2?)
  end
end
