require_relative '../../test_helper'
require 'sidekiq/testing'

class Bot::Smooch3Test < ActiveSupport::TestCase
  def setup
    super
    setup_smooch_bot
  end

  def teardown
    super
    CONFIG.unstub(:[])
    Bot::Smooch.unstub(:get_language)
  end

  test "should route to project based on rules" do
    s1 = @team.settings.clone
    s2 = @team.settings.clone
    p1 = create_project team: @team
    p2 = create_project team: @team
    s2['rules'] = [
      {
        "name": "Rule 1",
        "rules": {
          "operator": "and",
          "groups": [
            {
              "operator": "and",
              "conditions": [
                {
                  "rule_definition": "contains_keyword",
                  "rule_value": "hi,hello, sorry, Please"
                },
                {
                  "rule_definition": "has_less_than_x_words",
                  "rule_value": "5"
                }
              ]
            }
          ]
        },
        "actions": [
          {
            "action_definition": "move_to_project",
            "action_value": p1.id.to_s
          }
        ]
      },
      {
        "name": "Rule 2",
        "rules": {
          "operator": "and",
          "groups": [
            {
              "operator": "and",
              "conditions": [
                {
                  "rule_definition": "has_less_than_x_words",
                  "rule_value": "2"
                }
              ]
            }
          ]
        },
        "actions": [
          {
            "action_definition": "move_to_project",
            "action_value": p2.id.to_s
          }
        ]
      },
      {
        "name": "Rule 3",
        "rules": {
          "operator": "and",
          "groups": [
            {
              "operator": "and",
              "conditions": [
                {
                  "rule_definition": "request_matches_regexp",
                  "rule_value": "^[0-9]+$"
                }
              ]
            }
          ]
        },
        "actions": [
          {
            "action_definition": "send_to_trash",
            "action_value": ""
          }
        ]
      },
      {
        "name": "Rule 4",
        "rules": {
          "operator": "and",
          "groups": [
            {
              "operator": "and",
              "conditions": [
                {
                  "rule_definition": "request_matches_regexp",
                  "rule_value": "bad word"
                }
              ]
            }
          ]
        },
        "actions": [
          {
            "action_definition": "send_to_trash",
            "action_value": ""
          },
          {
            "action_definition": "ban_submitter",
            "action_value": ""
          }
        ]
      }
    ]
    @team.settings = s2
    @team.save!
    uid = random_string

    messages = [
      {
        '_id': random_string,
        authorId: uid,
        type: 'text',
        text: ([random_string] * 10).join(' ')
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
    assert_equal [@project.id], pm.project_ids
    assert !pm.archived

    messages = [
      {
        '_id': random_string,
        authorId: uid,
        type: 'text',
        text: ([random_string] * 3).join(' ') + ' pLease?'
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
    assert_equal [p1.id], pm.project_ids
    assert !pm.archived

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
    assert_equal [p2.id], pm.project_ids
    assert !pm.archived

    messages = [
      {
        '_id': random_string,
        authorId: uid,
        type: 'text',
        text: random_number.to_s
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
    assert pm.archived

    messages = [
      {
        '_id': random_string,
        authorId: uid,
        type: 'text',
        text: [random_string, random_string, random_string, 'bad word', random_string, random_string].join(' ')
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
    assert_nil Rails.cache.read("smooch:banned:#{uid}")
    assert Bot::Smooch.run(payload)
    pm = ProjectMedia.last
    assert pm.archived
    assert_not_nil Rails.cache.read("smooch:banned:#{uid}")

    @team.settings = s1
    @team.save!
  end

  test "should create media" do
    Sidekiq::Testing.inline! do
      json_message = {
        type: 'image',
        text: random_string,
        mediaUrl: @media_url_2,
        mediaType: 'image/jpeg',
        role: 'appUser',
        received: 1573082583.219,
        name: random_string,
        authorId: random_string,
        mediaSize: random_number,
        '_id': random_string,
        source: {
          originalMessageId: random_string,
          originalMessageTimestamp: 1573082582,
          type: 'whatsapp',
          integrationId: random_string
        },
        language: 'en'
      }.to_json
      assert_difference 'ProjectMedia.count' do
        SmoochWorker.perform_async(json_message, 'image', @app_id, 'default_requests', YAML.dump({}))
      end
    end
  end

  test "should create media with unstarted status" do
    messages = [
      {
        '_id': random_string,
        authorId: random_string,
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
    Bot::Smooch.run(payload)
    pm = ProjectMedia.last
    assert_equal 'undetermined', pm.last_verification_status
    # Get requests data
    requests =  pm.get_versions_log(['create_dynamicannotationfield'], ['smooch_data'], [], ['smooch'])
    assert_equal 1, requests.count
  end

  test "should bundle messages" do
    Sidekiq::Testing.fake! do
      uid = random_string
      messages = [
        {
          '_id': random_string,
          authorId: uid,
          type: 'text',
          text: 'foo',
        },
        {
          '_id': random_string,
          authorId: uid,
          type: 'image',
          text: 'first image',
          mediaUrl: @media_url
        },
        {
          '_id': random_string,
          authorId: uid,
          type: 'image',
          text: 'second image',
          mediaUrl: @media_url_2
        },
        {
          '_id': random_string,
          authorId: uid,
          type: 'text',
          text: 'bar'
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
      assert_difference 'ProjectMedia.count' do
        Sidekiq::Worker.drain_all
      end
      pm = ProjectMedia.last
      assert_no_match /#{@media_url}/, pm.text
      assert_equal 'UploadedImage', pm.media.type
    end
  end

  test "should not crash on und language annotation" do
    ft = DynamicAnnotation::FieldType.where(field_type: 'language').last || create_field_type(field_type: 'language', label: 'Language')
    at = create_annotation_type annotation_type: 'language', label: 'Language'
    create_field_instance annotation_type_object: at, name: 'language', label: 'Language', field_type_object: ft, optional: false
    bot = create_alegre_bot
    pm = create_project_media
    Bot::Alegre.save_language(pm, 'und')
    payload = {
      trigger: 'message:appUser',
      app: {
        '_id': @app_id
      },
      version: 'v1.1',
      message: {
        '_id': random_string,
        authorId: random_string,
        type: random_string,
        text: random_string,
      },
      appUser: {
        '_id': random_string,
        'conversationStarted': true
      }
    }.with_indifferent_access
    Rails.cache.write('smooch:response:' + payload['message']['_id'], pm.id)
    assert_nothing_raised do
      Bot::Smooch.resend_message_after_window(payload.to_json)
    end
  end

  test "should delete cache entries when user annotation is deleted" do
    create_annotation_type_and_fields('Smooch User', { 'Id' => ['Text', false], 'App Id' => ['Text', false], 'Data' => ['JSON', false] })
    Bot::Smooch.unstub(:save_user_information)
    SmoochApi::AppApi.any_instance.stubs(:get_app).returns(OpenStruct.new(app: OpenStruct.new(name: random_string)))
    { 'whatsapp' => '', 'messenger' => 'http://facebook.com/psid=1234', 'twitter' => 'http://twitter.com/profile_images/1234/image.jpg', 'other' => '' }.each do |platform, url|
      SmoochApi::AppUserApi.any_instance.stubs(:get_app_user).returns(OpenStruct.new(appUser: { clients: [{ displayName: random_string, platform: platform, info: { avatarUrl: url } }] }))
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
      redis = Redis.new(REDIS_CONFIG)
      assert_equal 0, redis.llen("smooch:bundle:#{uid}")
      assert_nil Rails.cache.read("smooch:banned:#{uid}")
      assert_difference "Dynamic.where(annotation_type: 'smooch_user').count" do
        Bot::Smooch.run(payload)
      end
      pm = ProjectMedia.last
      assert_not_nil Rails.cache.read("smooch:request:#{uid}:#{pm.id}")
      sm = CheckStateMachine.new(uid)
      sm.enter_human_mode
      sm = CheckStateMachine.new(uid)
      assert_equal 'human_mode', sm.state.value
      Bot::Smooch.ban_user({ 'authorId' => uid })
      assert_not_nil Rails.cache.read("smooch:banned:#{uid}")
      a = Dynamic.where(annotation_type: 'smooch_user').last
      assert_not_nil a
      a.destroy!
      assert_nil Rails.cache.read("smooch:banned:#{uid}")
      assert_nil Rails.cache.read("smooch:request:#{uid}:#{pm.id}")
      sm = CheckStateMachine.new(uid)
      assert_equal 'waiting_for_message', sm.state.value
      assert_equal 0, redis.llen("smooch:bundle:#{uid}")
    end
    Bot::Smooch.stubs(:save_user_information).returns(nil)
  end

  test "should detect media type" do
    Sidekiq::Testing.inline! do
      # video
      message = {
        type: 'file',
        text: random_string,
        mediaUrl: @video_url,
        mediaType: 'image/jpeg',
        role: 'appUser',
        received: 1573082583.219,
        name: random_string,
        authorId: random_string,
        '_id': random_string
      }
      assert_difference 'ProjectMedia.count' do
        Bot::Smooch.save_message(message.to_json, @app_id)
      end
      message['mediaUrl'] = @video_url_2
      assert_raises 'ActiveRecord::RecordInvalid' do
        Bot::Smooch.save_message(message.to_json, @app_id)
      end
      # audio
      message = {
        type: 'file',
        text: random_string,
        mediaUrl: @audio_url,
        mediaType: 'image/jpeg',
        role: 'appUser',
        received: 1573082583.219,
        name: random_string,
        authorId: random_string,
        '_id': random_string
      }
      assert_difference 'ProjectMedia.count' do
        Bot::Smooch.save_message(message.to_json, @app_id)
      end
      message['mediaUrl'] = @audio_url_2
      assert_raises 'ActiveRecord::RecordInvalid' do
        Bot::Smooch.save_message(message.to_json, @app_id)
      end
    end
  end

  test "should not save larger files" do
    messages = [
      {
        '_id': random_string,
        authorId: random_string,
        type: 'image',
        text: random_string,
        mediaUrl: @media_url_3,
        mediaSize: UploadedImage.max_size + random_number
      },
      {
        '_id': random_string,
        authorId: random_string,
        type: 'file',
        mediaType: 'image/jpeg',
        text: random_string,
        mediaUrl: @media_url_2,
        mediaSize: UploadedImage.max_size + random_number
      },
      {
        '_id': random_string,
        authorId: random_string,
        type: 'video',
        mediaType: 'video/mp4',
        text: random_string,
        mediaUrl: @video_url,
        mediaSize: UploadedVideo.max_size + random_number
      },
      {
        '_id': random_string,
        authorId: random_string,
        type: 'audio',
        mediaType: 'audio/mpeg',
        text: random_string,
        mediaUrl: @audio_url,
        mediaSize: UploadedAudio.max_size + random_number
      }

    ]
    assert_no_difference 'ProjectMedia.count', 0 do
      assert_no_difference 'Annotation.where(annotation_type: "smooch").count', 0 do
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

  test "should not crash if message in payload contains nil name" do
    messages = [
      {
        '_id': random_string,
        authorId: random_string,
        type: 'text',
        text: random_string,
        name: nil
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
  end

  test "should support message without mediaType" do
    # video
    message = {
      '_id': random_string,
      authorId: random_string,
      type: 'file',
      text: random_string,
      mediaUrl: @video_url,
      mediaType: 'video/mp4'
    }.with_indifferent_access
    is_supported = Bot::Smooch.supported_message?(message)
    assert is_supported.slice(:type, :size).all?{ |_k, v| v }

    message = {
      '_id': random_string,
      authorId: random_string,
      type: 'file',
      text: random_string,
      mediaUrl: @video_url,
      mediaType: 'newtype/ogg'
    }.with_indifferent_access
    is_supported = Bot::Smooch.supported_message?(message)
    assert !is_supported.slice(:type, :size).all?{ |_k, v| v }

    message = {
      '_id': random_string,
      authorId: random_string,
      type: 'file',
      text: random_string,
      mediaUrl: @video_url
    }.with_indifferent_access
    is_supported = Bot::Smooch.supported_message?(message)
    assert is_supported.slice(:type, :size).all?{ |_k, v| v }
    # audio
    message = {
      '_id': random_string,
      authorId: random_string,
      type: 'file',
      text: random_string,
      mediaUrl: @audio_url,
      mediaType: 'audio/mpeg'
    }.with_indifferent_access
    is_supported = Bot::Smooch.supported_message?(message)
    assert is_supported.slice(:type, :size).all?{ |_k, v| v }

    message = {
      '_id': random_string,
      authorId: random_string,
      type: 'file',
      text: random_string,
      mediaUrl: @audio_url,
      mediaType: 'newtype/mp4'
    }.with_indifferent_access
    is_supported = Bot::Smooch.supported_message?(message)
    assert !is_supported.slice(:type, :size).all?{ |_k, v| v }

    message = {
      '_id': random_string,
      authorId: random_string,
      type: 'file',
      text: random_string,
      mediaUrl: @audio_url
    }.with_indifferent_access
    is_supported = Bot::Smooch.supported_message?(message)
    assert is_supported.slice(:type, :size).all?{ |_k, v| v }
  end

  test "should update cached field when request is created or deleted" do
    RequestStore.store[:skip_cached_field_update] = false
    create_annotation_type_and_fields('Smooch', { 'Data' => ['JSON', true] })
    pm = create_project_media
    assert_equal 0, pm.reload.requests_count
    d = create_dynamic_annotation annotation_type: 'smooch', annotated: pm
    assert_equal 1, pm.reload.requests_count
    d.destroy
    assert_equal 0, pm.reload.requests_count
  end

  test "should go through menus" do
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
        send_message_to_smooch_bot('1', uid)
        assert_equal 'waiting_for_message', sm.state.value
        send_message_to_smooch_bot(' ONE', uid)
        assert_equal 'main', sm.state.value
        send_message_to_smooch_bot('ONE ', uid)
        assert_equal 'secondary', sm.state.value
        send_message_to_smooch_bot('2', uid)
        assert_equal 'query', sm.state.value
        send_message_to_smooch_bot('0', uid)
        assert_equal 'main', sm.state.value
        send_message_to_smooch_bot('1', uid)
        assert_equal 'secondary', sm.state.value
        assert_equal 'en', Bot::Smooch.get_user_language({ 'authorId' => uid })
        send_message_to_smooch_bot('3', uid)
        assert_equal 'main', sm.state.value
        assert_equal 'pt', Bot::Smooch.get_user_language({ 'authorId' => uid })
        send_message_to_smooch_bot('um', uid)
        assert_equal 'query', sm.state.value
      end
    end
    Rails.cache.stubs(:read).returns(nil)
    Rails.cache.stubs(:read).with("smooch:last_message_from_user:#{uid}").returns(Time.now + 10.seconds)
    assert_difference 'ProjectMedia.count' do
      send_message_to_smooch_bot(random_string, uid)
    end
    Rails.cache.unstub(:read)
    assert_equal 'waiting_for_message', sm.state.value
  end

  test "should ask for TOS again if 24 hours have passed" do
    uid = random_string
    assert_nil Rails.cache.read("smooch:last_accepted_terms:#{uid}")

    send_message_to_smooch_bot(random_string, uid)
    pm = ProjectMedia.last
    publish_report(pm, {}, nil, { use_visual_card: false })
    assert_not_nil Rails.cache.read("smooch:last_accepted_terms:#{uid}")
    t1 = Rails.cache.read("smooch:last_accepted_terms:#{uid}")

    send_message_to_smooch_bot(random_string, uid)
    pm = ProjectMedia.last
    publish_report(pm, {}, nil, { use_visual_card: false })
    t2 = Rails.cache.read("smooch:last_accepted_terms:#{uid}")
    assert_equal t1, t2

    now = Time.now
    Time.stubs(:now).returns(now + 12.hours)
    send_message_to_smooch_bot(random_string, uid)
    pm = ProjectMedia.last
    publish_report(pm, {}, nil, { use_visual_card: false })
    t2 = Rails.cache.read("smooch:last_accepted_terms:#{uid}")
    assert_equal t1, t2

    Time.stubs(:now).returns(now + 25.hours)
    send_message_to_smooch_bot(random_string, uid)
    pm = ProjectMedia.last
    publish_report(pm, {}, nil, { use_visual_card: false })
    t2 = Rails.cache.read("smooch:last_accepted_terms:#{uid}")
    assert_not_equal t1, t2

    Time.unstub(:now)
  end

  test "should transition from query state to query state" do
    uid = random_string
    sm = CheckStateMachine.new(uid)
    assert_nothing_raised do
      sm.go_to_query
      sm.go_to_query
    end
  end

  test "should timeout menu status" do
    setup_smooch_bot(true)
    Sidekiq::Testing.fake! do
      now = Time.now
      uid = random_string
      sm = CheckStateMachine.new(uid)
      assert_equal 'waiting_for_message', sm.state.value
      send_message_to_smooch_bot(random_string, uid)
      assert_equal 'main', sm.state.value
      send_message_to_smooch_bot('1', uid)
      assert_equal 'secondary', sm.state.value
      send_message_to_smooch_bot(random_string, uid)
      assert_equal 'secondary', sm.state.value
      send_message_to_smooch_bot(random_string, uid)
      Time.stubs(:now).returns(now + 30.minutes)
      Sidekiq::Worker.drain_all
      assert_equal 'waiting_for_message', sm.state.value
    end
    Time.unstub(:now)
  end

  test "should create smooch annotation for user requests" do
    setup_smooch_bot(true)
    Sidekiq::Testing.fake! do
      now = Time.now
      uid = random_string
      sm = CheckStateMachine.new(uid)
      send_message_to_smooch_bot(random_string, uid)
      send_message_to_smooch_bot('1', uid)
      assert_equal 'secondary', sm.state.value
      send_message_to_smooch_bot('1', uid)
      conditions = {
        annotation_type: 'smooch',
        annotated_type: @pm_for_menu_option.class.name,
        annotated_id: @pm_for_menu_option.id
      }
      assert_difference "Dynamic.where(#{conditions}).count", 1 do
        Sidekiq::Worker.drain_all
      end
      send_message_to_smooch_bot(random_string, uid)
      send_message_to_smooch_bot(random_string, uid)
      Time.stubs(:now).returns(now + 30.minutes)
      conditions[:annotated_type] = @team.class.name
      conditions[:annotated_id] = @team.id
      assert_difference "Dynamic.where(#{conditions}).count", 1 do
        Sidekiq::Worker.drain_all
      end
    end
    Time.unstub(:now)
  end

  test "should resend report after window" do
    msgid = random_string
    pm = create_project_media
    publish_report(pm)
    response = OpenStruct.new({ message: OpenStruct.new({ id: msgid }) })
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
      }
    }.to_json
    assert Bot::Smooch.resend_message_after_window(message)
    pm.destroy!
    assert !Bot::Smooch.resend_message_after_window(message)
  end

  test "should resend Slack message after window" do
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
      }
    }.to_json
    assert Bot::Smooch.resend_message_after_window(message)
    result = OpenStruct.new({ messages: [] })
    SmoochApi::ConversationApi.any_instance.stubs(:get_messages).returns(result)
    assert !Bot::Smooch.resend_message_after_window(message)
  end

  test "should resend rules action message after window" do
    msgid = random_string
    pm = create_project_media
    publish_report(pm)
    response = OpenStruct.new({ message: OpenStruct.new({ id: msgid }) })
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
      }
    }.to_json
    assert Bot::Smooch.resend_message_after_window(message)
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
          text: 'foo',
        },
        {
          '_id': random_string,
          authorId: uid,
          type: 'text',
          text: 'bar'
        },
        {
          '_id': random_string,
          authorId: uid,
          type: 'text',
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
      assert_difference 'Dynamic.where(annotation_type: "smooch").count' do
        Sidekiq::Worker.drain_all
      end
      assert_equal ['bar', 'foo', 'test'], JSON.parse(Dynamic.where(annotation_type: 'smooch').last.get_field_value('smooch_data'))['text'].split(Bot::Smooch::MESSAGE_BOUNDARY).map(&:chomp).sort
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
    assert_equal ['Hello for the last time', 'Query'], JSON.parse(Dynamic.where(annotation_type: 'smooch').last.get_field_value('smooch_data'))['text'].split(Bot::Smooch::MESSAGE_BOUNDARY).map(&:chomp)
    assert_equal 'Hello for the last time', ProjectMedia.last.text
  end

  test "should save Smooch response error if the request to Smooch API fails" do
    SmoochApi::ConversationApi.any_instance.stubs(:post_message).raises(SmoochApi::ApiError.new)
    Bot::Smooch.stubs(:notify_error).returns(Airbrake::Promise.new)
    response = Bot::Smooch.send_message_to_user(random_string, random_string)
    assert !Bot::Smooch.save_smooch_response(response, create_project_media, Time.now, random_string)
    SmoochApi::ConversationApi.any_instance.unstub(:post_message)
    Bot::Smooch.unstub(:notify_error)
  end

  protected

  def run_concurrent_requests
    threads = []
    uid = random_string
    CheckStateMachine.new(random_string)
    Bot::Smooch.stubs(:config).returns(@settings)
    @success = 0
    threads << Thread.start do
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
      Bot::Smooch.singleton_class.send(:alias_method, :send_message_to_user_mock_backup, :send_message_to_user)
      Bot::Smooch.define_singleton_method(:send_message_to_user) do |*args|
        sleep(15)
        Bot::Smooch.send_message_to_user_mock_backup(*args)
      end
      response = Bot::Smooch.run(payload)
      Bot::Smooch.singleton_class.send(:alias_method, :send_message_to_user, :send_message_to_user_mock_backup)
      @success += 1 if response
    end
    threads.map(&:join)
    Bot::Smooch.unstub(:config)
    @success
  end
end
