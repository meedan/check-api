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
    assert_equal 'undetermined', pm.last_verification_status
    # Get requests data
    requests = TiplineRequest.where(associated_type: 'ProjectMedia', associated_id: pm.id)
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
          source: { type: "whatsapp" },
          text: 'foo',
        },
        {
          '_id': random_string,
          authorId: uid,
          type: 'image',
          source: { type: "whatsapp" },
          text: 'first image',
          mediaUrl: @media_url
        },
        {
          '_id': random_string,
          authorId: uid,
          type: 'image',
          source: { type: "whatsapp" },
          text: 'second image',
          mediaUrl: @media_url_2
        },
        {
          '_id': random_string,
          authorId: uid,
          type: 'text',
          text: 'bar',
          source: { type: "whatsapp" },
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

  test "should delete cache entries when user annotation is deleted" do
    create_flag_annotation_type
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
      redis = Redis.new(REDIS_CONFIG)
      assert_equal 0, redis.llen("smooch:bundle:#{uid}")
      assert_nil Rails.cache.read("smooch:banned:#{uid}")
      assert_difference "Dynamic.where(annotation_type: 'smooch_user').count" do
        assert Bot::Smooch.run(payload)
      end
      pm = ProjectMedia.last
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
        source: { type: "whatsapp" },
        text: random_string,
        mediaUrl: @video_url,
        mediaType: 'image/jpeg',
        role: 'appUser',
        received: 1573082583.219,
        name: random_string,
        authorId: random_string,
        '_id': random_string,
        language: 'en',
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
        source: { type: "whatsapp" },
        text: random_string,
        mediaUrl: @audio_url,
        mediaType: 'image/jpeg',
        role: 'appUser',
        received: 1573082583.219,
        name: random_string,
        authorId: random_string,
        '_id': random_string,
        language: 'en',
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
        source: { type: "whatsapp" },
        text: random_string,
        mediaUrl: @media_url_3,
        mediaSize: UploadedImage.max_size + random_number
      },
      {
        '_id': random_string,
        authorId: random_string,
        type: 'file',
        mediaType: 'image/jpeg',
        source: { type: "whatsapp" },
        text: random_string,
        mediaUrl: @media_url_2,
        mediaSize: UploadedImage.max_size + random_number
      },
      {
        '_id': random_string,
        authorId: random_string,
        type: 'video',
        mediaType: 'video/mp4',
        source: { type: "whatsapp" },
        text: random_string,
        mediaUrl: @video_url,
        mediaSize: UploadedVideo.max_size + random_number
      },
      {
        '_id': random_string,
        authorId: random_string,
        type: 'audio',
        mediaType: 'audio/mpeg',
        source: { type: "whatsapp" },
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
                source: { type: "whatsapp" },
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
        source: { type: "whatsapp" },
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
      mediaType: 'video/mp4',
      source: { type: "whatsapp" },
    }.with_indifferent_access
    is_supported = Bot::Smooch.supported_message?(message)
    assert is_supported.slice(:type, :size).all?{ |_k, v| v }

    message = {
      '_id': random_string,
      authorId: random_string,
      type: 'file',
      text: random_string,
      mediaUrl: @video_url,
      mediaType: 'newtype/ogg',
      source: { type: "whatsapp" },
    }.with_indifferent_access
    is_supported = Bot::Smooch.supported_message?(message)
    assert !is_supported.slice(:type, :size).all?{ |_k, v| v }

    message = {
      '_id': random_string,
      authorId: random_string,
      type: 'file',
      text: random_string,
      mediaUrl: @video_url,
      source: { type: "whatsapp" },
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
      mediaType: 'audio/mpeg',
      source: { type: "whatsapp" },
    }.with_indifferent_access
    is_supported = Bot::Smooch.supported_message?(message)
    assert is_supported.slice(:type, :size).all?{ |_k, v| v }

    message = {
      '_id': random_string,
      authorId: random_string,
      type: 'file',
      text: random_string,
      mediaUrl: @audio_url,
      mediaType: 'newtype/mp4',
      source: { type: "whatsapp" },
    }.with_indifferent_access
    is_supported = Bot::Smooch.supported_message?(message)
    assert !is_supported.slice(:type, :size).all?{ |_k, v| v }

    message = {
      '_id': random_string,
      authorId: random_string,
      type: 'file',
      text: random_string,
      mediaUrl: @audio_url,
      source: { type: "whatsapp" },
    }.with_indifferent_access
    is_supported = Bot::Smooch.supported_message?(message)
    assert is_supported.slice(:type, :size).all?{ |_k, v| v }
  end

  test "should perform fuzzy matching on keyword search" do
    RequestStore.store[:skip_cached_field_update] = false
    setup_elasticsearch

    t = create_team
    pm1 = create_project_media quote: 'A segurança das urnas está provada.', team: t
    pm2 = create_project_media quote: 'Segurança pública é tema de debate.', team: t
    [pm1, pm2].each { |pm| publish_report(pm) }
    sleep 2 # Wait for ElasticSearch to index content

    [
      'Segurança das urnas',
      'Segurança dad urnas',
      'Segurança das urna',
      'Seguranca das urnas'
    ].each do |query|
      assert_equal [pm1.id], Bot::Smooch.search_for_similar_published_fact_checks('text', query, [t.id]).to_a.map(&:id)
    end

    assert_equal [], Bot::Smooch.search_for_similar_published_fact_checks('text', 'Segurando', [t.id]).to_a.map(&:id)
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
    assert_equal 200, Bot::Smooch.turnio_send_message_to_user('test:123456', 'Test').code.to_i
    WebMock.stub_request(:post, 'https://whatsapp.turn.io/v1/messages').to_return(status: 404, body: '{}')
    assert_equal 404, Bot::Smooch.turnio_send_message_to_user('test:123456', 'Test 2').code.to_i
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

  test "should apply content warning after blocking user" do
    create_flag_annotation_type
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
      redis = Redis.new(REDIS_CONFIG)
      Bot::Smooch.run(payload)
      pm = ProjectMedia.last
      Bot::Smooch.block_user(uid)
      assert Dynamic.where(annotation_type: 'flag', annotated_id: pm.id).exists?, 'Content warning flags should be applied'
    end
    Bot::Smooch.stubs(:save_user_information).returns(nil)
  end
end
