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
  end

  def teardown
    super
    CONFIG.unstub(:[])
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

  test "should save messages of different types by different users but not allow identical messages from the same user and notify them when verified" do
    id = random_string
    id2 = random_string
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

    assert_difference 'ProjectMedia.count', 3 do
      assert_difference 'Annotation.where(annotation_type: "smooch").count', 6 do
        assert_difference 'Comment.length', 2 do
          Bot::Smooch.run(payload)
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
    key = 'smooch:' + uid + ':' + @app_id + ':reminder_job_id'

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
end
