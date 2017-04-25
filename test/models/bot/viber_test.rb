require File.join(File.expand_path(File.dirname(__FILE__)), '..', '..', 'test_helper')
require 'sidekiq/testing'

class Bot::ViberTest < ActiveSupport::TestCase
  def setup
    super
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
      @bot.send_image_message('123456', OpenStruct.new(url: 'http://meedan.com/image.png'))
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
    create_dynamic_annotation annotation_type: 'translation_request', set_fields: { translation_request_type: 'viber', translation_request_raw_data: { sender: '123456' }.to_json }.to_json, annotated: pm
    
    d = nil
    stub_config('viber_token', nil) do
      d = create_dynamic_annotation annotation_type: 'translation', annotated: pm
    end
    
    Bot::Viber.any_instance.expects(:send_text_message).once
    Bot::Viber.any_instance.expects(:send_image_message).once

    Dynamic.respond_to_user(d.id)

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
end 
