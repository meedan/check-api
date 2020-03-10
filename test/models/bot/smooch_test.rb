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
        authorId: id2,
        type: 'audio',
        text: random_string,
        mediaUrl: random_url
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
      }
    ]

    create_tag_text text: 'teamtag', team_id: @team.id, teamwide: true
    create_tag_text text: 'montag', team_id: @team.id, teamwide: true

    assert_difference 'ProjectMedia.count', 6 do
      assert_difference 'Annotation.where(annotation_type: "smooch").count', 13 do
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
      WebMock.stub_request(:get, 'http://alegre/text/langid/').to_return(body: {
        'result': {
          'language': 'en',
          'confidence': 1.0
        }
      }.to_json)
      WebMock.disable_net_connect! allow: [CONFIG['elasticsearch_host']]
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

  # Add tests to test/models/bot/smooch_3_test.rb
end
