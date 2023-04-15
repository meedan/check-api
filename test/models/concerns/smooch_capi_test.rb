require_relative '../../test_helper'

class SmoochCapiTest < ActiveSupport::TestCase
  def setup
    WebMock.disable_net_connect! allow: /#{CheckConfig.get('storage_endpoint')}/

    RequestStore.store[:smooch_bot_provider] = 'CAPI'

    @config = {
      smooch_template_namespace: 'abcdef',
      capi_verify_token: '123456',
      capi_whatsapp_business_account_id: '123456',
      capi_permanent_token: '123456',
      capi_phone_number_id: '123456',
      capi_phone_number: '123456'
    }.with_indifferent_access

    RequestStore.store[:smooch_bot_settings] = @config

    @uid = '123456:654321'

    @incoming_text_message_payload = {
      object: 'whatsapp_business_account',
      entry: [
        {
          id: '987654',
          changes: [
            {
              value: {
                messaging_product: 'whatsapp',
                metadata: {
                  display_phone_number: '123456',
                  phone_number_id: '012345'
                },
                contacts: [
                  {
                    profile: {
                      name: 'John'
                    },
                    wa_id: '654321'
                  }
                ],
                messages: [
                  {
                    from: '654321',
                    id: '456789',
                    timestamp: Time.now.to_i.to_s,
                    text: {
                      body: 'Hello'
                    },
                    type: 'text'
                  }
                ]
              },
              field: 'messages'
            }
          ]
        }
      ]
    }.to_json
  end

  def teardown
  end

  test 'should format template message' do
    assert_kind_of String, Bot::Smooch.format_template_message('template_name', ['foo', 'bar'], nil, 'fallback', 'en')
  end

  test 'should process verification request' do
    assert_equal 'capi:verification', Bot::Smooch.run(nil)
  end

  test 'should get user data' do
    user_data = Bot::Smooch.api_get_user_data(@uid, @incoming_text_message_payload)
    assert_equal @uid, user_data.dig(:clients, 0, :displayName)
  end

  test 'should preprocess incoming text message' do
    preprocessed_message = Bot::Smooch.preprocess_message(@incoming_text_message_payload)
    assert_equal @uid, preprocessed_message.dig('appUser', '_id') 
  end

  test 'should get app name' do
    assert_equal 'CAPI', Bot::Smooch.api_get_app_name('app_id')
  end

  test 'should send message' do
    WebMock.stub_request(:post, 'https://graph.facebook.com/v15.0/123456/messages').to_return(status: 200, body: { id: '123456' }.to_json)
    assert_equal 200, Bot::Smooch.send_message_to_user(@uid, 'Test').code.to_i
  end

  test 'should store media' do
    WebMock.stub_request(:get, 'https://graph.facebook.com/v15.0/123456').to_return(status: 200, body: { url: 'https://wa.test/media' }.to_json)
    WebMock.stub_request(:get, 'https://wa.test/media').to_return(status: 200, body: File.read(File.join(Rails.root, 'test', 'data', 'rails.png')))
    assert_match /capi\/123456/, Bot::Smooch.store_media('123456', 'image/png')
  end
end
