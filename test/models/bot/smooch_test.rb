require_relative '../../test_helper'
require 'sidekiq/testing'

class Bot::SmoochTest < ActiveSupport::TestCase
  def setup
    super
    DynamicAnnotation::AnnotationType.delete_all
    DynamicAnnotation::FieldInstance.delete_all
    DynamicAnnotation::FieldType.delete_all
    DynamicAnnotation::Field.delete_all
    create_translation_status_stuff
    create_verification_status_stuff(false)
    create_annotation_type_and_fields('Smooch', { 'Data' => ['JSON', false] })
    create_annotation_type_and_fields('Smooch Response', { 'Data' => ['JSON', true] })
    create_annotation_type annotation_type: 'reverse_image', label: 'Reverse Image'
    WebMock.disable_net_connect! allow: /#{CONFIG['elasticsearch_host']}|#{CONFIG['storage']['endpoint']}/
    Sidekiq::Testing.inline!
    @app_id = random_string
    @msg_id = random_string
    SmoochApi::ConversationApi.any_instance.stubs(:post_message).returns(OpenStruct.new({ message: OpenStruct.new({ id: @msg_id }) }))
    @team = create_team
    @project = create_project team_id: @team.id
    @bid = random_string
    BotUser.delete_all
    settings = [
      { name: 'smooch_app_id', label: 'Smooch App ID', type: 'string', default: '' },
      { name: 'smooch_secret_key_key_id', label: 'Smooch Secret Key: Key ID', type: 'string', default: '' },
      { name: 'smooch_secret_key_secret', label: 'Smooch Secret Key: Secret', type: 'string', default: '' },
      { name: 'smooch_webhook_secret', label: 'Smooch Webhook Secret', type: 'string', default: '' },
      { name: 'smooch_template_namespace', label: 'Smooch Template Namespace', type: 'string', default: '' },
      { name: 'smooch_bot_id', label: 'Smooch Bot ID', type: 'string', default: '' },
      { name: 'smooch_project_id', label: 'Check Project ID', type: 'number', default: '' },
      { name: 'smooch_window_duration', label: 'Window Duration (in hours - after this time since the last message from the user, the user will be notified... enter 0 to disable)', type: 'number', default: 20 }
    ]
    {
      'smooch_bot_result' => 'Message sent with the verification results (placeholders: %{status} (final status of the report) and %{url} (public URL to verification results))',
      'smooch_bot_result_changed' => 'Message sent with the new verification results when a final status of an item changes (placeholders: %{previous_status} (previous final status of the report), %{status} (new final status of the report) and %{url} (public URL to verification results))',
      'smooch_bot_ask_for_confirmation' => 'Message that asks the user to confirm the request to verify an item... should mention that the user needs to sent "1" to confirm',
      'smooch_bot_message_confirmed' => 'Message that confirms to the user that the request is in the queue to be verified',
      'smooch_bot_message_type_unsupported' => 'Message that informs the user that the type of message is not supported (for example, audio and video)',
      'smooch_bot_message_unconfirmed' => 'Message sent when the user does not send "1" to confirm a request',
      'smooch_bot_not_final' => 'Message when an item was wrongly marked as final, but that status is reverted (placeholder: %{status} (previous final status))',
      'smooch_bot_meme' => 'Message sent along with a meme (placeholder: %{url} (public URL to verification results))',
    }.each do |name, label|
      settings << { name: "smooch_message_#{name}", label: label, type: 'string', default: '' }
    end
    WebMock.stub_request(:post, 'https://www.transifex.com/api/2/project/check-2/resources').to_return(status: 200, body: 'ok', headers: {})
    WebMock.stub_request(:get, 'https://www.transifex.com/api/2/project/check-2/resource/api/translation/en').to_return(status: 200, body: { 'content' => { 'en' => {} }.to_yaml }.to_json, headers: {})
    WebMock.stub_request(:put, /^https:\/\/www\.transifex\.com\/api\/2\/project\/check-2\/resource\/api-custom-messages-/).to_return(status: 200, body: { i18n_type: 'YML', 'content' => { 'en' => {} }.to_yaml }.to_json)
    WebMock.stub_request(:get, /^https:\/\/www\.transifex\.com\/api\/2\/project\/check-2\/resource\/api-custom-messages-/).to_return(status: 200, body: { i18n_type: 'YML', 'content' => { 'en' => {} }.to_yaml }.to_json)
    @bot = create_team_bot name: 'Smooch', login: 'smooch', set_approved: true, set_settings: settings, set_events: [], set_request_url: "#{CONFIG['checkdesk_base_url_private']}/api/bots/smooch"
    @settings = {
      'smooch_project_id' => @project.id,
      'smooch_bot_id' => @bid,
      'smooch_webhook_secret' => 'test',
      'smooch_app_id' => @app_id,
      'smooch_secret_key_key_id' => random_string,
      'smooch_secret_key_secret' => random_string,
      'smooch_template_namespace' => random_string,
      'smooch_window_duration' => 10
    }
    @installation = create_team_bot_installation user_id: @bot.id, settings: @settings, team_id: @team.id
    Bot::Smooch.get_installation('smooch_webhook_secret', 'test')
    @media_url = 'https://smooch.com/image/test.jpeg'
    WebMock.stub_request(:get, 'https://smooch.com/image/test.jpeg').to_return(body: File.read(File.join(Rails.root, 'test', 'data', 'rails.png')))
    @link_url = random_url
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    WebMock.stub_request(:get, pender_url).with({ query: { url: @link_url } }).to_return({ body: '{"type":"media","data":{"url":"' + @link_url + '","type":"item"}}' })
    @link_url_2 = 'https://' + random_string + '.com'
    WebMock.stub_request(:get, pender_url).with({ query: { url: @link_url_2 } }).to_return({ body: '{"type":"media","data":{"url":"' + @link_url_2 + '","type":"item"}}' })
    Bot::Smooch.stubs(:get_language).returns('en')
    create_alegre_bot
    AlegreClient.host = 'http://alegre'
    WebMock.stub_request(:get, pender_url).with({ query: { url: 'https://www.instagram.com/p/Bu3enV8Fjcy' } }).to_return({ body: '{"type":"media","data":{"url":"https://www.instagram.com/p/Bu3enV8Fjcy","type":"item"}}' })
    WebMock.stub_request(:get, pender_url).with({ query: { url: 'https://www.instagram.com/p/Bu3enV8Fjcy/?utm_source=ig_web_copy_link' } }).to_return({ body: '{"type":"media","data":{"url":"https://www.instagram.com/p/Bu3enV8Fjcy","type":"item"}}' })
    WebMock.stub_request(:get, "https://api-ssl.bitly.com/v3/shorten").with({ query: hash_including({}) }).to_return(status: 200, body: "", headers: {})
    WebMock.stub_request(:get, "https://meedan.com/en/check/check_message_tos.html").to_return({ body: '<h1>Check Message Terms of Service</h1><p class="meta">Last modified: August 7, 2019</p>' })
    Bot::Smooch.stubs(:save_user_information).returns(nil)
  end

  def teardown
    super
    CONFIG.unstub(:[])
    Bot::Smooch.unstub(:get_language)
  end

  test "should be valid only if the API key is valid" do
    assert !Bot::Smooch.valid_request?(OpenStruct.new(headers: {}))
    assert !Bot::Smooch.valid_request?(OpenStruct.new(headers: { 'X-API-Key' => 'foo' }))
    assert Bot::Smooch.valid_request?(OpenStruct.new(headers: { 'X-API-Key' => 'test' }))
  end

  test "should validate JSON schema" do
    payload = '{"trigger":"message:appUser","app":{"_id":"' + @app_id + '"},"version":"v1.1","messages":[{"type":"text","text":"This is a test","role":"appUser","received":1546269763.141,"name":"Foo Bar","authorId":"22bd83d736b4eb15eec863ec","_id":"6d3b3443c03bb3111e88c6ec","source":{"type":"whatsapp","integrationId":"6d193e6d91130000222756e4"}}],"appUser":{"_id":"22bd83d736b4eb15eec863ec","conversationStarted":true}}'
    assert Bot::Smooch.run(payload)
    payload = '{"trigger":"message:appUser","app":{"_id":"' + @app_id + '"},"version":"v1.1","messages":[{"text":"This is a test","role":"appUser","received":1546269763.141,"name":"Foo Bar","authorId":"22bd83d736b4eb15eec863ec","_id":"6d3b3443c03bb3111e88c6ec","source":{"type":"whatsapp","integrationId":"6d193e6d91130000222756e4"}}],"appUser":{"_id":"22bd83d736b4eb15eec863ec","conversationStarted":true}}'
    assert !Bot::Smooch.run(payload)
    assert !Bot::Smooch.run('not a json')
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
        mediaUrl: random_url
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
      }
    ]

    create_tag_text text: 'teamtag', team_id: @team.id, teamwide: true
    create_tag_text text: 'montag', team_id: @team.id, teamwide: true

    assert_difference 'ProjectMedia.count', 5 do
      assert_difference 'Annotation.where(annotation_type: "smooch").count', 11 do
        assert_difference 'Comment.length', 8 do
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
            assert Bot::Smooch.run(ignore)
            assert Bot::Smooch.run(message)
            assert send_confirmation(uid)
          end
        end
      end
    end

    pms = ProjectMedia.order("id desc").limit(5).reverse
    assert_equal 1, pms[4].annotations.where(annotation_type: 'tag').count
    assert_equal 'teamtag', pms[4].annotations.where(annotation_type: 'tag').last.load.data[:tag].text
    assert_equal 2, pms[3].annotations.where(annotation_type: 'tag').count
  end

  test "should schedule job when the window is over" do
    uid = random_string
    id = random_string
    key = 'smooch:reminder:' + uid

    # No job scheduled if user didn't send any message
    job = Rails.cache.read(key)
    assert_nil job

    # User sends message
    messages = [
      {
        '_id': id,
        authorId: uid,
        type: 'text',
        text: random_string
      },
      {
        '_id': id,
        authorId: uid,
        type: 'text',
        text: random_string
      }
    ]
    payload1 = {
      trigger: 'message:appUser',
      app: {
        '_id': @app_id
      },
      version: 'v1.1',
      messages: [messages[0]],
      appUser: {
        '_id': random_string,
        'conversationStarted': true
      }
    }.to_json
    payload2 = {
      trigger: 'message:appUser',
      app: {
        '_id': @app_id
      },
      version: 'v1.1',
      messages: [messages[1]],
      appUser: {
        '_id': random_string,
        'conversationStarted': true
      }
    }.to_json

    Bot::Smooch.run(payload1)
    assert_nil Rails.cache.read(key)
    assert send_confirmation(uid)
    job = Rails.cache.read(key)
    assert_not_nil job
    Bot::Smooch.run(payload1)
    assert_not_nil Rails.cache.read(key)
    Bot::Smooch.run(payload2)
    assert_nil Rails.cache.read(key)
    assert send_confirmation(uid)
    job2 = Rails.cache.read(key)
    assert_not_nil job2
    assert_not_equal job, job2
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
    assert send_confirmation(uid)

    pm = ProjectMedia.last
    s = pm.annotations.where(annotation_type: 'verification_status').last.load
    s.status = 'verified'
    s.save!

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

  test "should not send reminder if results were already sent" do
    Sidekiq::Testing.fake! do
      SmoochPingWorker.drain
      SmoochWorker.drain
      ProjectMedia.delete_all

      uid = random_string
      key = 'smooch:reminder:' + uid
      text = random_string

      assert_nil Rails.cache.read(key)
      assert_equal 0, SmoochPingWorker.jobs.size
      assert_equal 0, SmoochWorker.jobs.size

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
          '_id': uid,
          'conversationStarted': true
        }
      }.to_json

      Bot::Smooch.run(payload)
      assert_nil Rails.cache.read(key)
      assert_equal 0, SmoochPingWorker.jobs.size
      assert_equal 0, SmoochWorker.jobs.size
      assert_equal 0, ProjectMedia.count

      assert send_confirmation(uid)
      assert_not_nil Rails.cache.read(key)
      assert_equal 1, SmoochPingWorker.jobs.size
      assert_equal 1, SmoochWorker.jobs.size
      assert_equal 0, ProjectMedia.count

      SmoochWorker.drain

      assert_not_nil Rails.cache.read(key)
      assert_equal 1, SmoochPingWorker.jobs.size
      assert_equal 0, SmoochWorker.jobs.size
      assert_equal 1, ProjectMedia.count

      pm = ProjectMedia.last
      s = pm.annotations.where(annotation_type: 'verification_status').last.load
      s.status = 'verified'
      s.save!

      Sidekiq::Worker.drain_all

      assert_nil Rails.cache.read(key)
      assert_equal 0, SmoochPingWorker.jobs.size
      assert_equal 0, SmoochWorker.jobs.size
    end
  end

  test "should not get invalid URL" do
    assert_nil Bot::Smooch.extract_url('foo http://\foo.bar bar')
    assert_nil Bot::Smooch.extract_url('foo https://news...')
    assert_nil Bot::Smooch.extract_url('foo https://ha..?')
    assert_nil Bot::Smooch.extract_url('foo https://30th-JUNE-2019.*')
    assert_nil Bot::Smooch.extract_url('foo https://...')
    assert_nil Bot::Smooch.extract_url('foo https://*1.*')
  end

  test "should send meme to user" do
    field_names = ['image', 'overlay', 'published_at', 'headline', 'body', 'status', 'operation']
    fields = {}
    field_names.each{ |fn| fields[fn] = ['text', false] }
    create_annotation_type_and_fields('memebuster', fields)
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
    assert send_confirmation(uid)
    pm = ProjectMedia.last
    create_relationship source_id: pm.id, target_id: child1.id, user: u
    s = pm.last_status_obj
    s.status = CONFIG['app_name'] == 'Check' ? 'verified' : 'ready'
    s.save!

    fields = {}
    field_names.each{ |fn| fields["memebuster_#{fn}".to_sym] = random_string }
    a = create_dynamic_annotation annotation_type: 'memebuster', annotated: pm, set_fields: fields.to_json
    pa1 = a.get_field_value('memebuster_published_at')
    filepath = "memebuster/#{a.id}.png"
    assert !CheckS3.exist?(filepath)
    a = Dynamic.find(a.id)
    a.action = 'save'
    a.set_fields = { memebuster_operation: 'save' }.to_json
    a.save!
    assert !CheckS3.exist?(filepath)
    a = Dynamic.find(a.id)
    a.action = 'publish'
    a.set_fields = { memebuster_operation: 'publish' }.to_json
    a.save!
    assert_not_equal '', a.reload.get_field_value('memebuster_status')
    assert CheckS3.exist?(filepath)
    pa2 = a.get_field_value('memebuster_published_at')
    assert_not_equal pa1.to_s, pa2.to_s

    uid = random_string
    CheckS3.delete(filepath)
    assert !CheckS3.exist?(filepath)
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
    pm2 = ProjectMedia.last
    assert_equal pm, pm2
    assert CheckS3.exist?(filepath)
    assert_not_nil Bot::Smooch.get_meme(pm).memebuster_png_path

    s = pm.annotations.where(annotation_type: 'verification_status').last.load
    s.status = 'in_progress'
    s.save!

    assert !CheckS3.exist?(filepath)
    assert_equal 'In Progress', a.reload.get_field_value('memebuster_status')

    child2 = create_project_media project: @project
    Bot::Smooch.expects(:send_meme).once
    create_relationship source_id: pm.id, target_id: child2.id, user: u
    Bot::Smooch.unstub(:send_meme)
  end

  test "should get language" do
    Bot::Smooch.unstub(:get_language)
    stub_configs({ 'alegre_host' => 'http://alegre', 'alegre_token' => 'test' }) do
      AlegreClient::Mock.mock_languages_identification_returns_text_language do
        WebMock.disable_net_connect! allow: [CONFIG['elasticsearch_host']]
        assert_equal 'en', Bot::Smooch.get_language({ 'text' => 'This is just a test' })
      end
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
    assert send_confirmation(uid)

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

  test "should not crash when there is no Meme Buster annotation" do
    c = random_string
    m = create_claim_media quote: c
    pm = create_project_media project: @project, media: m
    s = pm.annotations.where(annotation_type: 'verification_status').last.load
    s.status = 'verified'
    s.save!

    uid = random_string

    messages = [
      {
        '_id': random_string,
        authorId: uid,
        type: 'text',
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
      assert send_confirmation(uid)
    end
  end

  test "should replicate status to related items" do
    parent = create_project_media project: @project
    child = create_project_media project: @project
    create_relationship source_id: parent.id, target_id: child.id, user: create_user
    s = parent.annotations.where(annotation_type: 'verification_status').last.load
    s.status = 'verified'
    s.save!
    s = child.annotations.where(annotation_type: 'verification_status').last.load
    assert_equal 'verified', s.status
  end

  test "should handle race condition on state machine" do
    passed = false
    while !passed
      if run_concurrent_requests == 2
        passed = true
      else
        puts 'Test "should handle race condition on state machine" failed, retrying...'
      end
    end
    assert passed
  end

  test "should inherit status from parent" do
    parent = create_project_media project: @project
    s = parent.annotations.where(annotation_type: 'verification_status').last.load
    s.status = 'verified'
    s.save!

    child = create_project_media project: @project
    create_relationship source_id: parent.id, target_id: child.id
    s = child.annotations.where(annotation_type: 'verification_status').last.load
    assert_equal 'undetermined', s.status

    child = create_project_media project: @project
    r = create_relationship source_id: parent.id, target_id: child.id, user: create_user
    s = child.annotations.where(annotation_type: 'verification_status').last.load
    assert_equal 'verified', s.status
    r.destroy
    s = child.annotations.where(annotation_type: 'verification_status').last.load
    assert_equal 'undetermined', s.status
  end

  test "should get previous final status" do
    u = create_user is_admin: true
    with_current_user_and_team(u, @team) do
      pm = create_project_media project: @project
      s = pm.annotations.where(annotation_type: 'verification_status').last.load
      s.status = 'verified'
      s.save!
      s = Annotation.find(s.id).load
      s.status = 'false'
      s.save!
      pm = ProjectMedia.find(pm.id)
      assert_equal 'verified', Bot::Smooch.get_previous_final_status(pm)
      s.get_fields.first.destroy
      pm = ProjectMedia.find(pm.id)
      assert_nil Bot::Smooch.get_previous_final_status(pm)
    end
  end

  test "should send message to user when status changes" do
    u = create_user is_admin: true
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
    Bot::Smooch.run(payload)
    assert send_confirmation(uid)
    pm = ProjectMedia.last
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
          text: t
        }
      ]
      assert Bot::Smooch.run(confirmation.to_json)
    end
    # test with empty text
    assert_nil Bot::Smooch.convert_numbers(nil)
    assert_nil Bot::Smooch.convert_numbers('')
  end

  test "should get is rtl lang" do
    I18n.locale = :ar
    assert Bot::Smooch.is_rtl_lang?
    I18n.locale = :en
    assert_not Bot::Smooch.is_rtl_lang?
  end

  test "should support file only if image" do
    assert Bot::Smooch.supported_message?({ 'type' => 'image' })
    assert Bot::Smooch.supported_message?({ 'type' => 'text' })
    assert Bot::Smooch.supported_message?({ 'type' => 'file', 'mediaType' => 'image/jpeg' })
    assert !Bot::Smooch.supported_message?({ 'type' => 'file', 'mediaType' => 'application/pdf' })
  end

  test "should ban user that sends unsafe URL" do
    uid = random_string
    url = 'http://unsafe.com/'
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    response = '{"type":"error","data":{"code":12}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    WebMock.stub_request(:get, pender_url).with({ query: { url: url, refresh: '1' } }).to_return(body: response)
    messages = [
      {
        '_id': random_string,
        authorId: uid,
        type: 'text'
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
    }

    payload[:messages][0][:text] = random_string
    assert_nil Rails.cache.read("smooch:banned:#{uid}")
    assert_difference 'ProjectMedia.count' do
      assert Bot::Smooch.run(payload.to_json)
      assert send_confirmation(uid)
    end

    payload[:messages][0][:text] = url
    assert_nil Rails.cache.read("smooch:banned:#{uid}")
    assert_no_difference 'ProjectMedia.count' do
      assert Bot::Smooch.run(payload.to_json)
      assert send_confirmation(uid)
    end

    payload[:messages][0][:text] = random_string
    assert_not_nil Rails.cache.read("smooch:banned:#{uid}")
    assert_no_difference 'ProjectMedia.count' do
      assert Bot::Smooch.run(payload.to_json)
      assert send_confirmation(uid)
    end
  end

  test "should send strings to Transifex" do
    t = create_team
    tbi = create_team_bot_installation user_id: @bot.id, settings: @settings, team_id: t.id

    stub_configs({ 'transifex_user' => random_string, 'transifex_password' => random_string }) do
      s = tbi.settings.clone
      s['smooch_message_smooch_bot_meme'] = random_string
      s['smooch_message_smooch_bot_not_final'] = random_string
      tbi.settings = s
      assert_nothing_raised do
        tbi.save!
      end
      TeamBotInstallation.stubs(:upload_smooch_strings_to_transifex).raises(StandardError)
      s['smooch_message_smooch_bot_meme'] = random_string
      s['smooch_message_smooch_bot_not_final'] = random_string
      tbi.settings = s
      assert_raises StandardError do
        tbi.save!
      end
      TeamBotInstallation.unstub(:upload_smooch_strings_to_transifex)
    end
  end

  test "should get message string" do
    slug = random_string.downcase
    c1 = 'Here is your meme'
    c2 = 'Aqui está o seu meme'
    t = create_team slug: slug
    tbi = create_team_bot_installation user_id: @bot.id, settings: @settings, team_id: t.id
    RequestStore.store[:smooch_bot_settings] = tbi.settings.with_indifferent_access.merge({ team_id: t.id })
    k = 'smooch_bot_meme'
    assert_equal I18n.t(k), Bot::Smooch.i18n_t(k)
    assert_equal I18n.t(k, locale: 'pt'), Bot::Smooch.i18n_t(k, { locale: 'pt' })
    RequestStore.store[:smooch_bot_settings]['smooch_message_smooch_bot_meme'] = c1
    assert_equal c1, Bot::Smooch.i18n_t(k)
    assert_equal c1, Bot::Smooch.i18n_t(k, { locale: 'pt' })
    I18n.stubs(:exists?).with("custom_message_#{k}_#{slug}").returns(true)
    I18n.stubs(:t).with("custom_message_#{k}_#{slug}".to_sym, {}).returns(c1)
    I18n.stubs(:t).with("custom_message_#{k}_#{slug}".to_sym, { locale: 'pt' }).returns(c2)
    assert_equal c1, Bot::Smooch.i18n_t(k)
    assert_equal c2, Bot::Smooch.i18n_t(k, { locale: 'pt' })
    I18n.unstub(:t)
    I18n.unstub(:exists?)
  end

  test "should not accept new requests if bot is disabled" do
    u = create_user is_admin: true
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

    ProjectMedia.delete_all

    s = @installation.settings.clone.with_indifferent_access
    s['smooch_disabled'] = true
    @installation.settings = s
    @installation.save!
    @installation = TeamBotInstallation.find(@installation.id)
    Bot::Smooch.get_installation('smooch_webhook_secret', 'test')
    Bot::Smooch.run(payload)
    send_confirmation(uid)
    assert_equal 0, ProjectMedia.count

    s = @installation.settings.clone.with_indifferent_access
    s['smooch_disabled'] = false
    @installation.settings = s
    @installation.save!
    @installation = TeamBotInstallation.find(@installation.id)
    Bot::Smooch.get_installation('smooch_webhook_secret', 'test')
    Bot::Smooch.run(payload)
    send_confirmation(uid)
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

  test "should save last message and ignore if in human mode" do
    uid = random_string
    sm = CheckStateMachine.new(uid)
    assert_equal 'waiting_for_message', sm.state.value
    sm.enter_human_mode
    sm = CheckStateMachine.new(uid)
    assert_equal 'human_mode', sm.state.value
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
    Bot::Smooch.run(payload)
  end

  test "should create Transifex resource if it does not exist" do
    require 'transifex'
    t = create_team
    ::Transifex::Project.any_instance.stubs(:resource).raises(::Transifex::TransifexError.new(nil, nil, nil))
    stub_configs({ 'transifex_user' => random_string, 'transifex_password' => random_string }) do
      s = @settings.clone
      s['smooch_message_smooch_bot_meme'] = random_string
      s['smooch_message_smooch_bot_not_final'] = random_string
      create_team_bot_installation user_id: @bot.id, settings: s, team_id: t.id
    end
    ::Transifex::Project.any_instance.unstub(:resource)
  end

  test "should use custom embed URL from task answer" do
    create_task_status_stuff
    at = create_annotation_type annotation_type: 'task_response_free_text', label: 'Task'
    ft1 = create_field_type field_type: 'text_field', label: 'Text Field'
    fi1 = create_field_instance annotation_type_object: at, name: 'response_task', label: 'Response', field_type_object: ft1
    tt = create_team_task team_id: @team.id
    RequestStore.store[:smooch_bot_settings] = { smooch_task: tt.id }.with_indifferent_access
    pm = create_project_media
    t = create_task annotated: pm, team_task_id: tt.id
    t.response = { annotation_type: 'task_response_free_text', set_fields: { response_task: 'https://custom.url' }.to_json }.to_json
    t.save!
    assert_equal 'https://custom.url', Bot::Smooch.embed_url(pm)
    assert_no_match /bit\.ly/, Bot::Smooch.embed_url(pm)
  end

  test "should not use custom embed URL from task answer if there is no team task" do
    create_task_status_stuff
    at = create_annotation_type annotation_type: 'task_response_free_text', label: 'Task'
    ft1 = create_field_type field_type: 'text_field', label: 'Text Field'
    fi1 = create_field_instance annotation_type_object: at, name: 'response_task', label: 'Response', field_type_object: ft1
    tt = create_team_task team_id: @team.id
    RequestStore.store[:smooch_bot_settings] = { smooch_task: nil }.with_indifferent_access
    pm = create_project_media
    t = create_task annotated: pm, team_task_id: tt.id
    t.response = { annotation_type: 'task_response_free_text', set_fields: { response_task: 'https://custom.url' }.to_json }.to_json
    t.save!
    assert_not_equal 'https://custom.url', Bot::Smooch.embed_url(pm)
    assert_match /bit\.ly/, Bot::Smooch.embed_url(pm)
  end

  test "should not use custom embed URL from task answer if task is not resolved" do
    create_task_status_stuff
    at = create_annotation_type annotation_type: 'task_response_free_text', label: 'Task'
    ft1 = create_field_type field_type: 'text_field', label: 'Text Field'
    fi1 = create_field_instance annotation_type_object: at, name: 'response_task', label: 'Response', field_type_object: ft1
    tt = create_team_task team_id: @team.id
    RequestStore.store[:smooch_bot_settings] = { smooch_task: tt.id }.with_indifferent_access
    pm = create_project_media
    t = create_task annotated: pm, team_task_id: tt.id
    assert_not_equal 'https://custom.url', Bot::Smooch.embed_url(pm)
    assert_match /bit\.ly/, Bot::Smooch.embed_url(pm)
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
    threads << Thread.start do
      @success += 1 if send_confirmation(uid)
    end
    threads.map(&:join)
    Bot::Smooch.unstub(:config)
    @success
  end

  def send_confirmation(uid)
    confirmation = {
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
          text: '1'
        }
      ],
      appUser: {
        '_id': uid,
        'conversationStarted': true
      }
    }.to_json
    Bot::Smooch.run(confirmation)
  end
end
