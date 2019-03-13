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
    create_annotation_type_and_fields('smooch', { 'Data' => ['JSON', false] })
    create_annotation_type annotation_type: 'reverse_image', label: 'Reverse Image'
    WebMock.disable_net_connect! allow: /#{CONFIG['elasticsearch_host']}/
    Sidekiq::Testing.inline!
    @app_id = random_string
    @msg_id = random_string
    SmoochApi::ConversationApi.any_instance.stubs(:post_message).returns(OpenStruct.new({ message: OpenStruct.new({ id: @msg_id }) }))
    @team = create_team
    @project = create_project team_id: @team.id
    @bid = random_string
    TeamBot.delete_all
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
    @bot = create_team_bot name: 'Smooch', identifier: 'smooch', approved: true, settings: settings, events: []
    settings = {
      'smooch_project_id' => @project.id,
      'smooch_bot_id' => @bid,
      'smooch_webhook_secret' => 'test',
      'smooch_app_id' => @app_id,
      'smooch_secret_key_key_id' => random_string,
      'smooch_secret_key_secret' => random_string,
      'smooch_template_namespace' => random_string,
      'smooch_window_duration' => 10
    }
    @installation = create_team_bot_installation team_bot_id: @bot.id, settings: settings, team_id: @team.id
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
        authorId: @bid,
        type: 'text',
        text: 'This should be ignored'
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
        text: "#{random_string} #{@link_url_2} #{random_string}"
      },
      {
        '_id': random_string,
        authorId: id3,
        type: 'text',
        text: "#{random_string} #{@link_url_2.gsub(/^https?:\/\//, '')} #{random_string}"
      },
      {
        '_id': random_string,
        authorId: id2,
        type: 'text',
        text: 'This is another claim'
      },
      {
        '_id': random_string,
        authorId: id3,
        type: 'text',
        text: 'This is another CLAIM'
      }
    ]

    assert_difference 'ProjectMedia.count', 5 do
      assert_difference 'Annotation.where(annotation_type: "smooch").count', 11 do
        assert_difference 'Comment.length', 4 do
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
            
            Bot::Smooch.run(message)
            Bot::Smooch.run(ignore)
            Bot::Smooch.run(message)
            send_confirmation(uid)
          end
        end
      end
    end

    pm = ProjectMedia.last
    s = pm.annotations.where(annotation_type: 'verification_status').last.load
    s.status = 'verified'
    s.save!
  end

  test "should schedule job when the window is over" do
    uid = random_string
    id = random_string
    key = 'smooch:' + uid + ':reminder_job_id'

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

    # Job scheduled
    job = Rails.cache.read(key)
    assert_not_nil job

    # If another message is sent, refresh the window
    Bot::Smooch.run(payload)
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
    send_confirmation(uid)

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
      key = 'smooch:' + uid + ':reminder_job_id'
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
      assert_not_nil Rails.cache.read(key)
      assert_equal 1, SmoochPingWorker.jobs.size
      assert_equal 0, SmoochWorker.jobs.size
      assert_equal 0, ProjectMedia.count
      sleep 1

      send_confirmation(uid)
      assert_not_nil Rails.cache.read(key)
      assert_equal 2, SmoochPingWorker.jobs.size
      assert_equal 1, SmoochWorker.jobs.size
      assert_equal 0, ProjectMedia.count

      SmoochWorker.drain

      assert_not_nil Rails.cache.read(key)
      assert_equal 2, SmoochPingWorker.jobs.size
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
    assert_nil Bot::Smooch.get_url_from_text('foo http://\foo.bar bar')
  end

  test "should send meme to user" do
    field_names = ['image', 'overlay', 'published_at', 'headline', 'body', 'status', 'operation']
    fields = {}
    field_names.each{ |fn| fields[fn] = ['text', false] }
    create_annotation_type_and_fields('memebuster', fields)
    text = random_string
    uid = random_string

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
    send_confirmation(uid)
    pm = ProjectMedia.last
    s = pm.last_status_obj
    s.status = CONFIG['app_name'] == 'Check' ? 'verified' : 'ready'
    s.save!

    fields = {}
    field_names.each{ |fn| fields["memebuster_#{fn}".to_sym] = random_string }
    a = create_dynamic_annotation annotation_type: 'memebuster', annotated: pm, set_fields: fields.to_json
    pa1 = a.get_field_value('memebuster_published_at')
    filepath = File.join(Rails.root, 'public', 'memebuster', "#{a.id}.png")
    assert !File.exist?(filepath)
    a = Dynamic.find(a.id)
    a.set_fields = { memebuster_operation: 'save' }.to_json
    a.save!
    assert !File.exist?(filepath)
    a = Dynamic.find(a.id)
    a.set_fields = { memebuster_operation: 'publish' }.to_json
    a.save!
    assert File.exist?(filepath)
    pa2 = a.get_field_value('memebuster_published_at')
    assert_not_equal pa1.to_s, pa2.to_s

    uid = random_string
    FileUtils.rm_f(filepath)
    assert !File.exist?(filepath)
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
    send_confirmation(uid)
    pm2 = ProjectMedia.last
    assert_equal pm, pm2
    assert File.exist?(filepath)
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
    send_confirmation(uid)
    
    Sidekiq::Testing.fake! do
      pm = ProjectMedia.last
      s = pm.annotations.where(annotation_type: 'verification_status').last.load
      s.status = 'verified'
      s.save!
      s = Annotation.find(s.id).load
      s.status = 'in_progress'
      s.save!
      I18n.expects(:t).with do |first_arg, second_arg|
        [:smooch_bot_result, :mail_subject_update_status].include?(first_arg)
      end.at_least_once
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
      send_confirmation(uid)
    end
  end

  protected

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
    assert Bot::Smooch.run(confirmation)
  end
end
