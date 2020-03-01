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

  # test "should handle race condition on state machine" do
  #   passed = false
  #   while !passed
  #     if run_concurrent_requests == 2
  #       passed = true
  #     else
  #       puts 'Test "should handle race condition on state machine" failed, retrying...'
  #     end
  #   end
  #   assert passed
  # end

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
    assert_nil CheckI18n.convert_numbers(nil)
    assert_nil CheckI18n.convert_numbers('')
  end

  test "should get is rtl lang" do
    I18n.locale = :ar
    assert CheckI18n.is_rtl_lang?
    I18n.locale = :en
    assert_not CheckI18n.is_rtl_lang?
  end

  test "should support file only if image or video" do
    assert Bot::Smooch.supported_message?({ 'type' => 'image' })[:type]
    assert Bot::Smooch.supported_message?({ 'type' => 'video' })[:type]
    assert Bot::Smooch.supported_message?({ 'type' => 'text' })[:type]
    assert Bot::Smooch.supported_message?({ 'type' => 'file', 'mediaType' => 'image/jpeg' })[:type]
    assert Bot::Smooch.supported_message?({ 'type' => 'file', 'mediaType' => 'video/mp4' })[:type]
    assert !Bot::Smooch.supported_message?({ 'type' => 'file', 'mediaType' => 'application/pdf' })[:type]
    # should not supoort invalid size
    large_image =  UploadedImage.max_size + random_number
    large_video =  UploadedVideo.max_size + random_number
    assert !Bot::Smooch.supported_message?({ 'type' => 'image', 'mediaSize' => large_image })[:size]
    assert !Bot::Smooch.supported_message?({ 'type' => 'video', 'mediaSize' => large_video })[:size]
    assert Bot::Smooch.supported_message?({ 'type' => 'text' })[:size]
    assert !Bot::Smooch.supported_message?({ 'type' => 'file', 'mediaType' => 'image/jpeg', 'mediaSize' => large_image })[:size]
    assert !Bot::Smooch.supported_message?({ 'type' => 'file', 'mediaType' => 'video/mp4', 'mediaSize' => large_video })[:size]
    assert !Bot::Smooch.supported_message?({ 'type' => 'file', 'mediaType' => 'application/pdf' })[:size]
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
    end

    payload[:messages][0][:text] = url
    assert_nil Rails.cache.read("smooch:banned:#{uid}")
    assert_no_difference 'ProjectMedia.count' do
      assert Bot::Smooch.run(payload.to_json)
    end

    payload[:messages][0][:text] = random_string
    assert_not_nil Rails.cache.read("smooch:banned:#{uid}")
    assert_no_difference 'ProjectMedia.count' do
      assert Bot::Smooch.run(payload.to_json)
    end
  end

  test "should send strings to Transifex" do
    t = create_team
    tbi = create_team_bot_installation user_id: @bot.id, settings: @settings, team_id: t.id

    stub_configs({ 'transifex_user' => random_string, 'transifex_password' => random_string, 'transifex_project' => 'check-2' }) do
      s = tbi.settings.clone
      s['smooch_message_smooch_bot_meme'] = random_string
      s['smooch_message_smooch_bot_not_final'] = random_string
      tbi.settings = s
      assert_nothing_raised do
        tbi.save!
      end
      CheckI18n.stubs(:upload_custom_strings_to_transifex).raises(StandardError)
      s['smooch_message_smooch_bot_meme'] = random_string
      s['smooch_message_smooch_bot_not_final'] = random_string
      tbi.settings = s
      assert_raises StandardError do
        tbi.save!
      end
      CheckI18n.unstub(:upload_custom_strings_to_transifex)
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
    t.set_language = 'fr'
    t.save!
    assert_equal I18n.t(k, locale: 'fr'), Bot::Smooch.i18n_t(k, { locale: 'pt' })
    t.settings.delete(:language)
    t.save!
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
    stub_configs({ 'transifex_user' => random_string, 'transifex_password' => random_string, 'transifex_project' => 'check-2' }) do
      s = @settings.clone
      s['smooch_message_smooch_bot_meme'] = random_string
      s['smooch_message_smooch_bot_not_final'] = random_string
      create_team_bot_installation user_id: @bot.id, settings: s, team_id: t.id
    end
    ::Transifex::Project.any_instance.unstub(:resource)
  end

  test "should delete Transifex resource if no localization setting" do
    require 'transifex'
    t = create_team
    stub_configs({ 'transifex_user' => random_string, 'transifex_password' => random_string, 'transifex_project' => 'check-2' }) do
      s = @settings.clone
      s['smooch_message_smooch_bot_meme'] = random_string
      s['smooch_message_smooch_bot_not_final'] = random_string
      s['smooch_localize_messages'] = false
      create_team_bot_installation user_id: @bot.id, settings: s, team_id: t.id
    end
  end

  test "should use custom embed URL from task answer" do
    create_task_status_stuff
    at = create_annotation_type annotation_type: 'memebuster', label: 'Memebuster'
    ft1 = create_field_type field_type: 'text_field', label: 'Text Field'
    fi1 = create_field_instance annotation_type_object: at, name: 'memebuster_custom_url', label: 'Memebuster Custom URL', field_type_object: ft1
    pm = create_project_media
    create_dynamic_annotation annotation_type: 'memebuster', annotated: pm, set_fields: { memebuster_custom_url: 'https://custom.url' }.to_json
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

  test "should never return an empty string" do
    t = create_team slug: 'reverso'
    settings = @settings.clone.merge({ 'team_id' => t.id, 'smooch_message_smooch_bot_ask_for_confirmation' => 'Custom Message' })
    Bot::Smooch.stubs(:config).returns(settings)
    I18n.stubs(:t).with(:smooch_bot_ask_for_confirmation, { locale: 'es' }).returns('Default Message')
    I18n.stubs(:exists?).with('custom_message_smooch_bot_ask_for_confirmation_reverso').returns(true)
    I18n.stubs(:t).with(:custom_message_smooch_bot_ask_for_confirmation_reverso, { locale: 'es' }).returns('')
    assert_equal 'Custom Message', ::Bot::Smooch.i18n_t(:smooch_bot_ask_for_confirmation, { locale: 'es' })
    I18n.unstub(:t)
    I18n.unstub(:exists?)
    Bot::Smooch.unstub(:config)
  end

  # Add tests to test/models/bot/smooch_3_test.rb
end
