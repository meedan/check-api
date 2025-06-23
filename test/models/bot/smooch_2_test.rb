require_relative '../../test_helper'
require 'sidekiq/testing'

class Bot::Smooch2Test < ActiveSupport::TestCase
  def setup
    super
    setup_smooch_bot
  end

  def teardown
    super
    CONFIG.unstub(:[])
    Bot::Smooch.unstub(:get_language)
  end

  test "should not crash when there is no Meme Buster annotation" do
    c = random_string
    m = create_claim_media quote: c
    pm = create_project_media team: @team, media: m
    s = pm.annotations.where(annotation_type: 'verification_status').last.load
    s.status = 'verified'
    s.save!

    uid = random_string

    messages = [
      {
        '_id': random_string,
        authorId: uid,
        type: 'text',
        source: { type: "whatsapp" },
        text: c
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

    Sidekiq::Testing.fake! do
      assert Bot::Smooch.run(payload)
      assert_nothing_raised do
        Sidekiq::Worker.drain_all
      end
    end
  end

  test "should not crash with canonical URLs" do
    uid = random_string

    ['https://www.instagram.com/p/Bu3enV8Fjcy', 'https://www.instagram.com/p/Bu3enV8Fjcy/?utm_source=ig_web_copy_link'].each do |url|
      messages = [
        {
          '_id': random_string,
          authorId: uid,
          type: 'text',
          source: { type: "whatsapp" },
          text: url
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
  end

  test "should replicate status to related items" do
    parent = create_project_media team: @team
    child = create_project_media team: @team
    create_relationship source_id: parent.id, target_id: child.id, user: create_user, relationship_type: Relationship.confirmed_type
    s = parent.annotations.where(annotation_type: 'verification_status').last.load
    s.status = 'verified'
    s.save!
    s = child.annotations.where(annotation_type: 'verification_status').last.load
    assert_equal 'verified', s.status
  end

  test "should inherit status from parent" do
    parent = create_project_media team: @team
    s = parent.annotations.where(annotation_type: 'verification_status').last.load
    s.status = 'verified'
    s.save!

    child = create_project_media team: @team
    create_tipline_request team_id: @team.id, associated: child, language: 'en', smooch_message_id: random_string, smooch_data: { app_id: @app_id, authorId: random_string, language: 'en' }
    r = create_relationship source_id: parent.id, target_id: child.id, relationship_type: Relationship.confirmed_type, user: create_user
    s = child.annotations.where(annotation_type: 'verification_status').last.load
    assert_equal 'verified', s.status

    r.destroy
    s = child.annotations.where(annotation_type: 'verification_status').last.load
    assert_equal 'undetermined', s.status
    u = create_user
    create_team_user team: @team, user: u, role: 'admin'
    with_current_user_and_team(u, @team) do
      child2 = create_project_media team: @team
      s2 = child2.annotations.where(annotation_type: 'verification_status').last.load
      assert_equal 'undetermined', s2.status
      create_tipline_request team_id: @team.id, associated: child2, language: 'en', smooch_message_id: random_string, smooch_data: { app_id: @app_id, authorId: random_string, language: 'en' }
      r = create_relationship source_id: parent.id, target_id: child2.id, relationship_type: Relationship.confirmed_type, user: @bot
      s2 = child2.annotations.where(annotation_type: 'verification_status').last.load
      assert_equal 'verified', s2.status
    end
  end

  test "should inherit status from parent even child is published" do
    pm_s = create_project_media team: @team
    pm_t = create_project_media team: @team
    r = create_relationship source_id: pm_s.id, target_id: pm_t.id, relationship_type: Relationship.confirmed_type
    s = pm_t.annotations.where(annotation_type: 'verification_status').last.load
    s.status = 'verified'
    s.save!
    publish_report(pm_t)
    s = s.reload
    s.status = 'in_progress'
    s.bypass_status_publish_check = true
    s.save!
    assert_equal 'in_progress', s.reload.status
  end

  test "should send message to user when status changes" do
    u = create_user is_admin: true
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
    Bot::Smooch.run(payload)
    pm = ProjectMedia.last
    pm.archived = CheckArchivedFlags::FlagCodes::NONE
    pm.save!
    with_current_user_and_team(u, @team) do
      s = pm.last_verification_status_obj
      s.status = 'false'
      s.save!
      s = pm.last_verification_status_obj
      s.status = 'verified'
      s.save!
    end
  end

  test "should return state machine error" do
    class AasmTest
      def aasm(_arg)
        OpenStruct.new(current_state: 'test')
      end
    end
    e = AASM::InvalidTransition.new(AasmTest.new, 'test', 'test')
    JSON.stubs(:parse).raises(e)
    assert_raises AASM::InvalidTransition do
      Bot::Smooch.run(nil)
    end
    JSON.unstub(:parse)
  end

  test "should send confirmation message in different language" do
    uid = random_string
    confirmation = {
      trigger: 'message:appUser',
      app: {
        '_id': @app_id
      },
      version: 'v1.1',
      appUser: {
        '_id': uid,
        'conversationStarted': true
      }
    }
    ['1','۱', '߁', '१', '১', '୧'].each do |t|
      confirmation[:messages] = [
        {
          '_id': random_string,
          authorId: uid,
          type: 'text',
          source: { type: "whatsapp" },
          text: t
        }
      ]
      assert Bot::Smooch.run(confirmation.to_json)
    end
  end

  test "should support file only if image or video or audio" do
    assert Bot::Smooch.supported_message?({ 'type' => 'image' })[:type]
    assert Bot::Smooch.supported_message?({ 'type' => 'video' })[:type]
    assert Bot::Smooch.supported_message?({ 'type' => 'audio' })[:type]
    assert Bot::Smooch.supported_message?({ 'type' => 'text' })[:type]
    assert Bot::Smooch.supported_message?({ 'type' => 'file', 'mediaType' => 'image/jpeg' })[:type]
    assert Bot::Smooch.supported_message?({ 'type' => 'file', 'mediaType' => 'video/mp4' })[:type]
    assert Bot::Smooch.supported_message?({ 'type' => 'file', 'mediaType' => 'audio/mpeg' })[:type]
    assert !Bot::Smooch.supported_message?({ 'type' => 'file', 'mediaType' => 'application/pdf' })[:type]
    # should not supoort invalid size
    large_image =  UploadedImage.max_size + random_number
    large_video =  UploadedVideo.max_size + random_number
    large_audio =  UploadedAudio.max_size + random_number
    assert !Bot::Smooch.supported_message?({ 'type' => 'image', 'mediaSize' => large_image })[:size]
    assert !Bot::Smooch.supported_message?({ 'type' => 'video', 'mediaSize' => large_video })[:size]
    assert !Bot::Smooch.supported_message?({ 'type' => 'audio', 'mediaSize' => large_video })[:size]
    assert Bot::Smooch.supported_message?({ 'type' => 'text' })[:size]
    assert !Bot::Smooch.supported_message?({ 'type' => 'file', 'mediaType' => 'image/jpeg', 'mediaSize' => large_image })[:size]
    assert !Bot::Smooch.supported_message?({ 'type' => 'file', 'mediaType' => 'video/mp4', 'mediaSize' => large_video })[:size]
    assert !Bot::Smooch.supported_message?({ 'type' => 'file', 'mediaType' => 'audio/mpeg', 'mediaSize' => large_audio })[:size]
    assert !Bot::Smooch.supported_message?({ 'type' => 'file', 'mediaType' => 'application/pdf' })[:size]
  end

  test "should ban user that sends unsafe URL" do
    create_flag_annotation_type
    uid = random_string
    url = 'http://unsafe.com/'
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"error","data":{"code":12}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    WebMock.stub_request(:get, pender_url).with({ query: { url: url, refresh: '1' } }).to_return(body: response)

    def unique_payload(uid, message_text)
      {
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
            source: { type: "whatsapp" },
            text: message_text
          }
        ],
        appUser: {
          '_id': random_string,
          'conversationStarted': true
        }
      }
    end

    assert_nil Rails.cache.read("smooch:banned:#{uid}")
    assert_difference 'ProjectMedia.count' do
      assert Bot::Smooch.run(unique_payload(uid, random_string).to_json)
    end

    assert_nil Rails.cache.read("smooch:banned:#{uid}")
    assert_no_difference 'ProjectMedia.count' do
      assert Bot::Smooch.run(unique_payload(uid, url).to_json)
    end

    assert_not_nil Rails.cache.read("smooch:banned:#{uid}")
    assert_no_difference 'ProjectMedia.count' do
      assert Bot::Smooch.run(unique_payload(uid, random_string).to_json)
    end
  end

  test "should not accept new requests if bot is disabled" do
    u = create_user is_admin: true
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

    ProjectMedia.delete_all

    s = @installation.settings.clone.with_indifferent_access
    s['smooch_disabled'] = true
    @installation.settings = s
    @installation.save!
    @installation = TeamBotInstallation.find(@installation.id)
    Bot::Smooch.get_installation('smooch_webhook_secret', 'test')
    Bot::Smooch.run(payload)
    assert_equal 0, ProjectMedia.count

    s = @installation.settings.clone.with_indifferent_access
    s['smooch_disabled'] = false
    @installation.settings = s
    @installation.save!
    @installation = TeamBotInstallation.find(@installation.id)
    Bot::Smooch.get_installation('smooch_webhook_secret', 'test')
    Bot::Smooch.run(payload)
    assert_equal 1, ProjectMedia.count
  end

  test "should change Smooch user state" do
    create_annotation_type_and_fields('Smooch User', { 'Id' => ['Text', false], 'App Id' => ['Text', false], 'Data' => ['JSON', false] })
    id = random_string
    phone = random_string
    name = random_string
    d = create_dynamic_annotation annotation_type: 'smooch_user', set_fields: { smooch_user_id: id, smooch_user_app_id: @app_id, smooch_user_data: { phone: phone, app_name: name }.to_json }.to_json
    assert_equal 'waiting_for_message', CheckStateMachine.new(id).state.value
    d = Dynamic.find(d.id) ; d.action = 'deactivate' ; d.save!
    assert_equal 'human_mode', CheckStateMachine.new(id).state.value
    d = Dynamic.find(d.id) ; d.action = 'reactivate' ; d.save!
    assert_equal 'waiting_for_message', CheckStateMachine.new(id).state.value
    d = Dynamic.find(d.id) ; d.action = 'deactivate' ; d.save!
    assert_equal 'human_mode', CheckStateMachine.new(id).state.value
    message = {
      '_id': random_string,
      authorId: id,
      type: 'text',
      text: random_string
    }
    d = Dynamic.find(d.id) ; d.action = 'send test' ; d.save!
    assert_equal 'human_mode', CheckStateMachine.new(id).state.value
  end

  test "should save user information" do
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
      assert_difference "Dynamic.where(annotation_type: 'smooch_user').count" do
        Bot::Smooch.run(payload)
      end
      assert_no_difference "Dynamic.where(annotation_type: 'smooch_user').count" do
        Bot::Smooch.run(payload)
      end
    end
    Bot::Smooch.stubs(:save_user_information).returns(nil)
  end

  test "should not trigger error when save user information" do
    create_annotation_type_and_fields('Smooch User', { 'Id' => ['Text', false], 'App Id' => ['Text', false], 'Data' => ['JSON', false] })
    Bot::Smooch.unstub(:save_user_information)
    SmoochApi::AppApi.any_instance.stubs(:get_app).returns(OpenStruct.new(app: OpenStruct.new(name: random_string)))
    { 'messenger' => 'http://facebook.com/psid=1234' }.each do |platform, url|
      SmoochApi::AppUserApi.any_instance.stubs(:get_app_user).returns(OpenStruct.new(appUser: { clients: [{ displayName: random_string, platform: platform }] }))
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
      assert_difference "Dynamic.where(annotation_type: 'smooch_user').count" do
        Bot::Smooch.run(payload)
      end
      assert_no_difference "Dynamic.where(annotation_type: 'smooch_user').count" do
        Bot::Smooch.run(payload)
      end
    end
    Bot::Smooch.stubs(:save_user_information).returns(nil)
  end

  test "should save last message and ignore if in human mode" do
    Sidekiq::Testing.inline! do
      Bot::Smooch.unstub(:save_user_information)
      SmoochApi::AppApi.any_instance.stubs(:get_app).returns(OpenStruct.new(app: OpenStruct.new(name: random_string)))
      { 'whatsapp' => '', 'messenger' => 'http://facebook.com/psid=1234', 'twitter' => 'http://twitter.com/profile_images/1234/image.jpg', 'other' => '' }.each do |platform, url|
        SmoochApi::AppUserApi.any_instance.stubs(:get_app_user).returns(OpenStruct.new(appUser: { clients: [{ displayName: random_string, platform: platform, info: { avatarUrl: url } }] }))
      end
      create_annotation_type_and_fields('Smooch User', { 'Id' => ['Text', false], 'App Id' => ['Text', false], 'Data' => ['JSON', false] })
      WebMock.stub_request(:get, /^https:\/\/slack\.com\/api\/chat\.postMessage.*/)
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
      Bot::Smooch.run(payload)
      d = DynamicAnnotation::Field.where(field_name: 'smooch_user_id', value: uid).last.annotation.load
      d.action = 'refresh_timeout'
      d.action_data = { token: random_string, channel: random_string }.to_json
      d.save!
      sm = CheckStateMachine.new(uid)
      sm.enter_human_mode
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
      assert Bot::Smooch.run(payload)
    end
  end

  test "should parse turn.io message" do
    Sidekiq::Testing.inline! do
      Bot::Smooch.unstub(:save_user_information)
      create_annotation_type_and_fields('Smooch User', { 'Id' => ['Text', false], 'App Id' => ['Text', false], 'Data' => ['JSON', false] })
      @installation.set_turnio_secret = 'test'
      @installation.set_turnio_token = 'test'
      @installation.save!
      Bot::Smooch.get_installation('turnio_secret', 'test')
      payload = {
        contacts: [
          {
            profile: {
              name: 'Caio Almeida'
            },
            wa_id: '557112345678'
          }
        ],
        messages: [
          {
            '_vnd': {
              v1: {
                author: {
                  id: '557112345678',
                  name: 'Foo Bar',
                  type: 'OWNER'
                },
                chat: {
                  assigned_to: nil,
                  owner: '+557112345678',
                  permalink: 'https://app.turn.io/c/123456789',
                  state: 'OPEN',
                  state_reason: 'Re-opened by inbound message.',
                  unread_count: 5,
                  uuid: '123456789'
                },
                direction: 'inbound',
                faq_uuid: nil,
                in_reply_to: nil,
                inserted_at: '2021-06-16T17:45:10.326052Z',
                labels: nil,
                rendered_content: nil
              }
            },
            from: '557112345678',
            id: '123456789',
            text: {
              body: 'Test'
            },
            timestamp: '1623865510',
            type: 'text',
            source: { type: "whatsapp" },
          }
        ]
      }
      assert_difference 'ProjectMedia.count' do
        assert Bot::Smooch.run(payload.to_json)
      end
      assert_equal '557112345678', DynamicAnnotation::Field.where(field_name: 'smooch_user_id').last.value
      payload = { statuses: [{ id: random_string, recipient_id: '557112345678', status: 'delivered', timestamp: '1624042957' }]}
      assert Bot::Smooch.run(payload.to_json)
      assert !Bot::Smooch.run({}.to_json)
    end
  end

  test "should parse turn.io media message" do
    Sidekiq::Testing.inline! do
      @installation.set_turnio_secret = 'test'
      @installation.set_turnio_token = 'test'
      @installation.save!
      Bot::Smooch.get_installation('turnio_secret', 'test')
      WebMock.stub_request(:get, 'https://whatsapp.turn.io/v1/media/123456').to_return(status: 200, body: File.read(File.join(Rails.root, 'test', 'data', 'rails.png')))
      payload = {
        contacts: [
          {
            profile: {
              name: 'Caio Almeida'
            },
            wa_id: '557112345678'
          }
        ],
        messages: [
          {
            '_vnd': {
              v1: {
                author: {
                  id: '557112345678',
                  name: 'Foo Bar',
                  type: 'OWNER'
                },
                chat: {
                  assigned_to: nil,
                  owner: '+557112345678',
                  permalink: 'https://app.turn.io/c/123456789',
                  state: 'OPEN',
                  state_reason: 'Re-opened by inbound message.',
                  unread_count: 5,
                  uuid: '123456789'
                },
                direction: 'inbound',
                faq_uuid: nil,
                in_reply_to: nil,
                inserted_at: '2021-06-16T17:45:10.326052Z',
                labels: nil,
                rendered_content: nil
              }
            },
            from: '557112345678',
            id: '123456789',
            text: {
              body: 'Test'
            },
            timestamp: '1623865510',
            type: 'image',
            source: { type: "whatsapp" },
            image: {
              id: '123456',
              mime_type: 'image/png'
            }
          }
        ]
      }
      assert_difference 'ProjectMedia.count' do
        assert Bot::Smooch.run(payload.to_json)
      end
    end
  end
end
