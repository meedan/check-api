require File.join(File.expand_path(File.dirname(__FILE__)), '..', '..', 'test_helper')
require 'sidekiq/testing'

class Bot::ViberTest < ActiveSupport::TestCase
  def setup
    super
    create_translation_status_stuff
    ft = DynamicAnnotation::FieldType.where(field_type: 'text').last || create_field_type(field_type: 'text', label: 'Text')
    at = create_annotation_type annotation_type: 'translation_request', label: 'Translation Request'
    create_field_instance annotation_type_object: at, name: 'translation_request_raw_data', label: 'Translation Request Raw Data', field_type_object: ft, optional: false
    create_field_instance annotation_type_object: at, name: 'translation_request_type', label: 'Translation Request Type', field_type_object: ft, optional: false
    Bot::Viber.delete_all
    @bot = create_viber_bot
    @pm = create_project_media
    WebMock.stub_request(:post, 'https://chatapi.viber.com/pa/send_message')
  end

  test "should return default bot" do
    assert_equal @bot, Bot::Viber.default
  end

  test "should send text message to Viber" do
    assert_nothing_raised do
      @bot.send_text_message('123456', 'Message')
    end
  end

  test "should send image message to Viber" do
    assert_nothing_raised do
      @bot.send_image_message('123456', 'http://meedan.com/image.png')
    end
  end

  test "should respond to user when annotation is created" do
    pm = create_project_media
    at = create_annotation_type annotation_type: 'translation'
    Dynamic.expects(:respond_to_user).once
    Sidekiq::Testing.inline! do
      stub_config('viber_token', 'test') do
        d = create_dynamic_annotation annotation_type: 'translation', annotated: pm
      end
    end
    Dynamic.unstub(:respond_to_user)
  end

  test "should not respond to user when annotation is created if config is not set" do
    pm = create_project_media
    at = create_annotation_type annotation_type: 'translation'
    Dynamic.expects(:respond_to_user).never
    Sidekiq::Testing.inline! do
      stub_config('viber_token', nil) do
        d = create_dynamic_annotation annotation_type: 'translation', annotated: pm
      end
    end
    Dynamic.unstub(:respond_to_user)
  end

  test "should not respond to user when annotation is created if annotation type is not translation" do
    pm = create_project_media
    at = create_annotation_type annotation_type: 'not_translation'
    Dynamic.expects(:respond_to_user).never
    Sidekiq::Testing.inline! do
      stub_config('viber_token', 'test') do
        d = create_dynamic_annotation annotation_type: 'not_translation', annotated: pm
      end
    end
    Dynamic.unstub(:respond_to_user)
  end

  test "should not respond to user when annotation is created if annotated is not project media" do
    s = create_source
    at = create_annotation_type annotation_type: 'translation'
    Dynamic.expects(:respond_to_user).never
    Sidekiq::Testing.inline! do
      stub_config('viber_token', 'test') do
        d = create_dynamic_annotation annotation_type: 'translation', annotated: s
      end
    end
    Dynamic.unstub(:respond_to_user)
  end

  test "should respond to user" do
    pm = create_project_media
    create_annotation_type annotation_type: 'translation'
    tr = DynamicAnnotation::AnnotationType.where(annotation_type: 'translation_request').last || create_annotation_type(annotation_type: 'translation_request')
    create_field_instance(name: 'translation_request_type', annotation_type_object: tr) unless DynamicAnnotation::FieldInstance.where(name: 'translation_request_type').exists?
    create_field_instance(name: 'translation_request_raw_data', annotation_type_object: tr) unless DynamicAnnotation::FieldInstance.where(name: 'translation_request_type').exists?
    
    d1 = d2 = nil
    stub_config('viber_token', nil) do
      d1 = create_dynamic_annotation annotation_type: 'translation_request', set_fields: { translation_request_type: 'viber', translation_request_raw_data: { sender: '123456' }.to_json }.to_json, annotated: pm
      d2 = create_dynamic_annotation annotation_type: 'translation', annotated: pm
    end

    Sidekiq::Testing.inline! do
      d1.respond_to_user
    end
    
    Bot::Viber.any_instance.expects(:send_text_message).once
    Bot::Viber.any_instance.expects(:send_image_message).once

    Dynamic.respond_to_user(d1.id)

    Bot::Viber.any_instance.expects(:send_text_message).once
    Bot::Viber.any_instance.expects(:send_image_message).never

    Dynamic.respond_to_user(d1.id, false)

    Bot::Viber.any_instance.unstub(:send_text_message)
    Bot::Viber.any_instance.unstub(:send_image_message)
  end

  test "should not respond to user if translation does not exist" do
    pm = create_project_media
    create_annotation_type annotation_type: 'translation'
    tr = DynamicAnnotation::AnnotationType.where(annotation_type: 'translation_request').last || create_annotation_type(annotation_type: 'translation_request')
    create_field_instance(name: 'translation_request_type', annotation_type_object: tr) unless DynamicAnnotation::FieldInstance.where(name: 'translation_request_type').exists?
    create_field_instance(name: 'translation_request_raw_data', annotation_type_object: tr) unless DynamicAnnotation::FieldInstance.where(name: 'translation_request_type').exists?
    create_dynamic_annotation annotation_type: 'translation_request', set_fields: { translation_request_type: 'viber', translation_request_raw_data: { sender: '123456' }.to_json }.to_json, annotated: pm
    
    d = nil
    stub_config('viber_token', nil) do
      d = create_dynamic_annotation annotation_type: 'translation', annotated: pm
    end
    
    Bot::Viber.any_instance.expects(:send_text_message).never
    Bot::Viber.any_instance.expects(:send_image_message).never

    Dynamic.respond_to_user(d.id + 1)

    Bot::Viber.any_instance.unstub(:send_text_message)
    Bot::Viber.any_instance.unstub(:send_image_message)
  end

  test "should not respond to user if there is no translation request" do
    pm = create_project_media
    create_annotation_type annotation_type: 'translation'
    tr = DynamicAnnotation::AnnotationType.where(annotation_type: 'translation_request').last || create_annotation_type(annotation_type: 'translation_request')
    create_field_instance(name: 'translation_request_type', annotation_type_object: tr) unless DynamicAnnotation::FieldInstance.where(name: 'translation_request_type').exists?
    create_field_instance(name: 'translation_request_raw_data', annotation_type_object: tr) unless DynamicAnnotation::FieldInstance.where(name: 'translation_request_type').exists?
    
    d = nil
    stub_config('viber_token', nil) do
      d = create_dynamic_annotation annotation_type: 'translation', annotated: pm
    end
    
    Bot::Viber.any_instance.expects(:send_text_message).never
    Bot::Viber.any_instance.expects(:send_image_message).never

    Dynamic.respond_to_user(d.id)

    Bot::Viber.any_instance.unstub(:send_text_message)
    Bot::Viber.any_instance.unstub(:send_image_message)
  end

  test "should not respond to user if request type is not 'viber'" do
    pm = create_project_media
    create_annotation_type annotation_type: 'translation'
    tr = DynamicAnnotation::AnnotationType.where(annotation_type: 'translation_request').last || create_annotation_type(annotation_type: 'translation_request')
    create_field_instance(name: 'translation_request_type', annotation_type_object: tr) unless DynamicAnnotation::FieldInstance.where(name: 'translation_request_type').exists?
    create_field_instance(name: 'translation_request_raw_data', annotation_type_object: tr) unless DynamicAnnotation::FieldInstance.where(name: 'translation_request_type').exists?
    create_dynamic_annotation annotation_type: 'translation_request', set_fields: { translation_request_type: 'telegram', translation_request_raw_data: { sender: '123456' }.to_json }.to_json, annotated: pm
    
    d = nil
    stub_config('viber_token', nil) do
      d = create_dynamic_annotation annotation_type: 'translation', annotated: pm
    end
    
    Bot::Viber.any_instance.expects(:send_text_message).never
    Bot::Viber.any_instance.expects(:send_image_message).never

    Dynamic.respond_to_user(d.id)

    Bot::Viber.any_instance.unstub(:send_text_message)
    Bot::Viber.any_instance.unstub(:send_image_message)
  end

  test "should convert translation to message" do
    pm = create_project_media media: create_claim_media
    at = create_annotation_type annotation_type: 'translation'
    create_field_instance name: 'translation_text', annotation_type_object: at
    create_field_instance name: 'translation_language', annotation_type_object: at
    at = create_annotation_type annotation_type: 'language'
    create_field_instance name: 'language', annotation_type_object: at
    create_dynamic_annotation annotated: pm, annotation_type: 'language', set_fields: { language: 'pt' }.to_json
    d = create_dynamic_annotation annotation_type: 'translation', annotated: pm, set_fields: { translation_text: 'Foo', translation_language: 'en' }.to_json
    assert_not_equal '', d.translation_to_message
    assert_not_nil d.translation_to_message
  end

  test "should set translation status" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'owner'
    pm = create_project_media media: create_claim_media
    with_current_user_and_team(u, t) do
      assert_difference "Dynamic.where(annotation_type: 'translation_status').count" do
        create_dynamic_annotation annotator: u, annotated: pm, annotation_type: 'translation_status', set_fields: { translation_status_status: 'ready' }.to_json
      end
    end
  end

  test "should not set invalid translation status" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'owner'
    pm = create_project_media media: create_claim_media
    with_current_user_and_team(u, t) do
      assert_no_difference "Dynamic.where(annotation_type: 'translation_status').count" do
        assert_raises ActiveRecord::RecordInvalid do
          create_dynamic_annotation annotator: u, annotated: pm, annotation_type: 'translation_status', set_fields: { translation_status_status: 'invalid' }.to_json
        end
      end
    end
  end

  test "should set translation status if has permission to change current value" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'contributor'
    pm = create_project_media media: create_claim_media
    d = create_dynamic_annotation annotator: u, annotated: pm, annotation_type: 'translation_status', set_fields: { translation_status_status: 'pending' }.to_json
    
    with_current_user_and_team(u, t) do
      assert_nothing_raised do
        d = Dynamic.find(d.id)
        d.set_fields = { translation_status_status: 'in_progress' }.to_json
        d.save!
      end
    end
  end

  test "should set translation status if has permission to change current value 2" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'editor'
    pm = create_project_media media: create_claim_media
    d = create_dynamic_annotation annotator: u, annotated: pm, annotation_type: 'translation_status', set_fields: { translation_status_status: 'ready' }.to_json
    
    with_current_user_and_team(u, t) do
      assert_nothing_raised do
        d = Dynamic.find(d.id)
        d.set_fields = { translation_status_status: 'in_progress' }.to_json
        d.save!
      end
    end
  end

  test "should not set translation status if does not have permission to change current value" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'contributor'
    pm = create_project_media media: create_claim_media
    d = create_dynamic_annotation annotator: u, annotated: pm, annotation_type: 'translation_status', set_fields: { translation_status_status: 'ready' }.to_json
    
    with_current_user_and_team(u, t) do
      assert_raises ActiveRecord::RecordInvalid do
        d = Dynamic.find(d.id)
        d.set_fields = { translation_status_status: 'in_progress' }.to_json
        d.save!
      end
    end
  end

  test "should not set translation status if does not have permission to change for target value" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'contributor'
    pm = create_project_media media: create_claim_media
    d = create_dynamic_annotation annotator: u, annotated: pm, annotation_type: 'translation_status', set_fields: { translation_status_status: 'pending' }.to_json
    
    with_current_user_and_team(u, t) do
      assert_raises ActiveRecord::RecordInvalid do
        d = Dynamic.find(d.id)
        d.set_fields = { translation_status_status: 'ready' }.to_json
        d.save!
      end
    end
  end

  test "should set translation status if has permission to change for target value" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'contributor'
    pm = create_project_media media: create_claim_media
    d = create_dynamic_annotation annotator: u, annotated: pm, annotation_type: 'translation_status', set_fields: { translation_status_status: 'pending' }.to_json
    
    with_current_user_and_team(u, t) do
      assert_nothing_raised do
        d = Dynamic.find(d.id)
        d.set_fields = { translation_status_status: 'translated' }.to_json
        d.save!
      end
    end
  end

  test "should set translation status if has permission to change for target value and publish to Twitter and Facebook" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'editor'
    pm = create_project_media media: create_claim_media
    d = create_dynamic_annotation annotator: u, annotated: pm, annotation_type: 'translation_status', set_fields: { translation_status_status: 'pending', translation_status_approver: '{}' }.to_json
    create_dynamic_annotation annotated: pm, annotation_type: 'translation_request', set_fields: { translation_request_raw_data: '', translation_request_type: 'viber' }.to_json
    
    Bot::Twitter.any_instance.stubs(:send_to_twitter_in_background).once
    Bot::Facebook.any_instance.stubs(:send_to_facebook_in_background).once

    with_current_user_and_team(u, t) do
      assert_nothing_raised do
        d = Dynamic.find(d.id)
        d.set_fields = { translation_status_status: 'ready' }.to_json
        d.save!
      end

      approver = d.get_field('translation_status_approver')
      assert_equal u.name, JSON.parse(approver.value)['name']
      assert_nil JSON.parse(approver.value)['url']
    end
    
    Bot::Twitter.any_instance.unstub(:send_to_twitter_in_background)
    Bot::Facebook.any_instance.unstub(:send_to_facebook_in_background)
  end

  test "should create first translation status when translation request is created" do
    pm = create_project_media
    assert_difference "Dynamic.where(annotation_type: 'translation_status').count" do
      create_dynamic_annotation annotation_type: 'translation_request', set_fields: { translation_request_type: 'viber', translation_request_raw_data: { sender: '123456' }.to_json }.to_json, annotated: pm
    end
  end

  test "should respond to user when translation status changes to ready" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'editor'
    pm = create_project_media media: create_claim_media
    create_dynamic_annotation annotated: pm, annotation_type: 'translation_request'
    d = create_dynamic_annotation annotator: u, annotated: pm, annotation_type: 'translation_status', set_fields: { translation_status_status: 'pending' }.to_json
    create_annotation_type annotation_type: 'translation'
    create_dynamic_annotation annotated: pm, annotation_type: 'translation'

    Dynamic.expects(:respond_to_user).with(true).once

    with_current_user_and_team(u, t) do
      assert_nothing_raised do
        Sidekiq::Testing.inline! do
          stub_config('viber_token', nil) do
            d = Dynamic.find(d.id)
            d.set_fields = { translation_status_status: 'ready' }.to_json
            d.save!
          end
        end
      end
    end
    
    Dynamic.unstub(:respond_to_user)
  end

  test "should respond to user when translation status changes to error" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'editor'
    pm = create_project_media media: create_claim_media
    d = create_dynamic_annotation annotator: u, annotated: pm, annotation_type: 'translation_status', set_fields: { translation_status_status: 'pending' }.to_json
    create_annotation_type annotation_type: 'translation'
    create_dynamic_annotation annotated: pm, annotation_type: 'translation'

    Dynamic.expects(:respond_to_user).with(false).once

    with_current_user_and_team(u, t) do
      assert_nothing_raised do
        Sidekiq::Testing.inline! do
          stub_config('viber_token', nil) do
            d = Dynamic.find(d.id)
            d.set_fields = { translation_status_status: 'error' }.to_json
            d.save!
          end
        end
      end
    end
    
    Dynamic.unstub(:respond_to_user)
  end

  test "should respond to user in background" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'editor'
    pm = create_project_media media: create_claim_media
    d = create_dynamic_annotation annotator: u, annotated: pm, annotation_type: 'translation_status', set_fields: { translation_status_status: 'pending' }.to_json
    create_annotation_type annotation_type: 'translation'
    create_dynamic_annotation annotated: pm, annotation_type: 'translation'

    with_current_user_and_team(u, t) do
      assert_nothing_raised do
        stub_config('viber_token', 'test') do
          d = Dynamic.find(d.id)
          d.set_fields = { translation_status_status: 'error' }.to_json
          d.save!
        end
      end
    end
  end

  test "should get translation status value" do
    pm = create_project_media
    d = create_dynamic_annotation annotated: pm, annotation_type: 'translation_status', set_fields: { translation_status_status: 'pending' }.to_json
    assert_equal 'pending', DynamicAnnotation::Field.last.status
  end

  test "should set translation status value" do
    pm = create_project_media
    d = create_dynamic_annotation annotated: pm, annotation_type: 'translation_status', set_fields: { translation_status_status: 'pending' }.to_json
    f = DynamicAnnotation::Field.last
    f.status = 'foo'
    assert_equal 'foo', f.value
  end

  test "should send message to user in background" do
    Dynamic.expects(:respond_to_user).once
    pm = create_project_media
    d = create_dynamic_annotation annotation_type: 'translation_request', annotated: pm
    Sidekiq::Testing.inline! do
      stub_config('viber_token', 'test') do
        d.respond_to_user
      end
    end
    Dynamic.unstub(:respond_to_user)
  end

  test "should change status if admin" do
    u = create_user is_admin: true
    t = create_team
    create_team_user user: u, team: t, role: 'contributor'
    pm = create_project_media media: create_claim_media
    d = create_dynamic_annotation annotator: u, annotated: pm, annotation_type: 'translation_status', set_fields: { translation_status_status: 'pending' }.to_json
    
    with_current_user_and_team(u, t) do
      assert_nothing_raised do
        d = Dynamic.find(d.id)
        d.set_fields = { translation_status_status: 'ready' }.to_json
        d.save!
      end
    end
  end

  test "should get translation source language" do
    pm = create_project_media
    create_annotation_type annotation_type: 'translation'
    at = create_annotation_type annotation_type: 'language'
    create_field_instance name: 'language', annotation_type_object: at
    d = create_dynamic_annotation annotation_type: 'translation', annotated: pm
    assert_nil d.from_language('pt')
    create_dynamic_annotation annotated: pm, annotation_type: 'language', set_fields: { language: 'pt' }.to_json
    assert_equal 'Português', d.from_language('pt')
  end

  test "should not create translation request for the same Viber message" do
    DynamicAnnotation::FieldInstance.delete_all
    create_translation_status_stuff
    tr = DynamicAnnotation::AnnotationType.where(annotation_type: 'translation_request').last || create_annotation_type(annotation_type: 'translation_request')
    create_field_instance(name: 'translation_request_type', annotation_type_object: tr)
    create_field_instance(name: 'translation_request_raw_data', annotation_type_object: tr)
    create_field_instance(name: 'translation_request_id', annotation_type_object: tr)
    pm = nil
   
    assert_difference 'ProjectMedia.count', 2 do
      assert_nothing_raised do
        create_project_media set_annotation: { annotation_type: 'translation_request', set_fields: { translation_request_type: 'viber', translation_request_raw_data: '{}', translation_request_id: '123456' }.to_json }.to_json
        create_project_media set_annotation: { annotation_type: 'translation_request', set_fields: { translation_request_type: 'viber', translation_request_raw_data: '{}', translation_request_id: '654321' }.to_json }.to_json
      end
    end

    assert_no_difference 'ProjectMedia.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_project_media set_annotation: { annotation_type: 'translation_request', set_fields: { translation_request_type: 'viber', translation_request_raw_data: '{}', translation_request_id: '123456' }.to_json }.to_json
      end
    end
  end

  test "should not create duplicate translation request id because of database partial index" do
    at = create_annotation_type
    fi1 = create_field_instance name: 'foo', annotation_type_object: at
    fi2 = create_field_instance name: 'translation_request_id', annotation_type_object: at

    assert_nothing_raised do
      create_field value: '123', field_name: 'translation_request_id', skip_validation: true, annotation_type: at.annotation_type, field_type: fi2.field_type
      create_field value: '123', field_name: 'foo', skip_validation: true, annotation_type: at.annotation_type, field_type: fi1.field_type
      create_field value: '123', field_name: 'foo', skip_validation: true, annotation_type: at.annotation_type, field_type: fi1.field_type
    end
    
    assert_raises ActiveRecord::RecordNotUnique do
      create_field value: '123', field_name: 'translation_request_id', skip_validation: true, annotation_type: at.annotation_type, field_type: fi2.field_type
    end
  end

  private

  def create_translation_status_stuff
    [DynamicAnnotation::FieldType, DynamicAnnotation::AnnotationType, DynamicAnnotation::FieldInstance].each { |klass| klass.delete_all }
    ft1 = create_field_type(field_type: 'select', label: 'Select')
    ft2 = create_field_type(field_type: 'text', label: 'Text')
    at = create_annotation_type annotation_type: 'translation_status', label: 'Translation Status'
    create_field_instance annotation_type_object: at, name: 'translation_status_status', label: 'Translation Status', field_type_object: ft1, optional: false, settings: { options_and_roles: { pending: 'contributor', in_progress: 'contributor', translated: 'contributor', ready: 'editor', error: 'editor' } }
    create_field_instance annotation_type_object: at, name: 'translation_status_note', label: 'Translation Status Note', field_type_object: ft2, optional: true
    create_field_instance annotation_type_object: at, name: 'translation_status_approver', label: 'Translation Status Approver', field_type_object: ft2, optional: true
  end
end
