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
      capi_phone_number: '123456',
      team_id: create_team.id,
      smooch_workflows: [
        {
          'smooch_workflow_language' => 'en',
          'smooch_message_smooch_bot_greetings' => 'Hello!',
          'smooch_message_smooch_bot_tos' => {
            'greeting' => 'Send 9 to read the terms of service.',
            'content' => 'Custom terms of service.'
          }
        }
      ]
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

    @message_delivery_payload = {
      object: 'whatsapp_business_account',
      entry: [{
        id: '987654',
        changes: [{
          value: {
            messaging_product: 'whatsapp',
            metadata: {
              display_phone_number: '123456',
              phone_number_id: '012345'
            },
            statuses: [{
              id: 'wamid.123456',
              recipient_id: '654321',
              status: 'delivered',
              timestamp: Time.now.to_i.to_s,
              conversation: {
                id: '987654',
                expiration_timestamp: Time.now.tomorrow.to_i.to_s,
                origin: {
                  type: 'user_initiated'
                }
              },
              pricing: {
                pricing_model: 'CBP',
                billable: true,
                category: 'user_initiated'
              }
            }]
          },
          field: 'messages'
        }]
      }]
    }.to_json

    @message_delivery_error_payload = {
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
                statuses: [
                  {
                    id: 'wamid.123456',
                    status: 'failed',
                    timestamp: Time.now.to_i.to_s,
                    recipient_id: '654321',
                    errors: [
                      {
                        code: 131047,
                        title: 'Message failed to send because more than 24 hours have passed since the customer last replied to this number.',
                        href: 'https://developers.facebook.com/docs/whatsapp/cloud-api/support/error-codes/'
                      }
                    ]
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
    assert_kind_of Hash, Bot::Smooch.format_template_message('template_name', ['foo', 'bar'], nil, 'fallback', 'en')
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
    assert_equal 'message:appUser', preprocessed_message[:trigger]
  end

  test 'should preprocess message delivery event' do
    preprocessed_message = Bot::Smooch.preprocess_message(@message_delivery_payload)
    assert_equal @uid, preprocessed_message.dig('appUser', '_id') 
    assert_equal 'message:delivery:channel', preprocessed_message[:trigger]
  end

  test 'should preprocess failed message delivery event' do
    preprocessed_message = Bot::Smooch.preprocess_message(@message_delivery_error_payload)
    assert_equal @uid, preprocessed_message.dig('appUser', '_id') 
    assert_equal 'message:delivery:failure', preprocessed_message[:trigger]
  end

  test 'should preprocess fallback message' do
    preprocessed_message = Bot::Smooch.preprocess_message({ foo: 'bar' }.to_json)
    assert_equal 'message:other', preprocessed_message[:trigger]
  end

  test 'should get app name' do
    assert_equal 'CAPI', Bot::Smooch.api_get_app_name('app_id')
  end

  test 'should send text message' do
    WebMock.stub_request(:post, 'https://graph.facebook.com/v15.0/123456/messages').to_return(status: 200, body: { id: '123456' }.to_json)
    assert_equal 200, Bot::Smooch.send_message_to_user(@uid, 'Test').code.to_i
  end

  test 'should send interactive message to user' do
    WebMock.stub_request(:post, 'https://graph.facebook.com/v15.0/123456/messages').to_return(status: 200, body: { id: '123456' }.to_json)
    assert_equal 200, Bot::Smooch.send_message_to_user(@uid, { type: 'interactive' }).code.to_i
  end

  test 'should send image message to user' do
    WebMock.stub_request(:post, 'https://graph.facebook.com/v15.0/123456/messages').to_return(status: 200, body: { id: '123456' }.to_json)
    assert_equal 200, Bot::Smooch.send_message_to_user(@uid, 'Test', { 'type' => 'image', 'mediaUrl' => 'https://test.test/image.png' }).code.to_i
  end

  test 'should report delivery error to Sentry' do
    CheckSentry.expects(:notify).once
    WebMock.stub_request(:post, 'https://graph.facebook.com/v15.0/123456/messages').to_return(status: 400, body: { error: 'Error' }.to_json)
    Bot::Smooch.send_message_to_user(@uid, 'Test')
  end

  test 'should store media' do
    WebMock.stub_request(:get, 'https://graph.facebook.com/v15.0/123456').to_return(status: 200, body: { url: 'https://wa.test/media' }.to_json)
    WebMock.stub_request(:get, 'https://wa.test/media').to_return(status: 200, body: File.read(File.join(Rails.root, 'test', 'data', 'rails.png')))
    assert_match /capi\/123456/, Bot::Smooch.store_media('123456', 'image/png')
  end

  test 'should validate Cloud API request' do
    b = BotUser.smooch_user || create_team_bot(name: 'Smooch', login: 'smooch', set_approved: true)
    create_team_bot_installation user_id: b.id, settings: @config

    request = OpenStruct.new(params: { 'hub.mode' => 'subscribe', 'hub.verify_token' => '123456' })
    assert Bot::Smooch.valid_capi_request?(request)

    request = OpenStruct.new(params: { 'token' => '123456', 'entry' => [{ 'id' => '123456' }] })
    assert Bot::Smooch.valid_capi_request?(request)

    request = OpenStruct.new(params: { 'token' => '654321', 'entry' => [{ 'id' => '654321' }] })
    assert !Bot::Smooch.valid_capi_request?(request)
  end

  test 'should return empty string if Cloud API payload is not supported' do
    assert_equal '', Bot::Smooch.get_capi_message_text(nil)
  end

  test 'should report failed statuses to Sentry' do
    message = {
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
                statuses: [
                  {
                    id: 'wamid.123456',
                    status: 'failed',
                    timestamp: Time.now.to_i.to_s,
                    recipient_id: '654321',
                    errors: [
                      {
                        code: 131026,
                        title: 'Receiver is incapable of receiving this message'
                      }
                    ]
                  }
                ]
              },
              field: 'messages'
            }
          ]
        }
      ]
    }.to_json
    CheckSentry.expects(:notify).once
    assert Bot::Smooch.run(message)
  end

  test 'should report to Sentry if payload is not handled' do
    message = {
      object: 'whatsapp_business_account',
      entry: [
        {
          foo: 'bar'
        }
      ]
    }.to_json
    CheckSentry.expects(:notify).once
    assert !Bot::Smooch.run(message)
  end

  test 'should send video message' do
    WebMock.stub_request(:post, 'https://graph.facebook.com/v15.0/123456/messages').to_return(status: 200, body: { id: '123456' }.to_json)
    assert_equal 200, Bot::Smooch.send_message_to_user(@uid, 'Test', { 'type' => 'video', 'mediaUrl' => 'https://test.test/video.mp4' }).code.to_i
  end

  test 'should block user if WhatsApp reports pair rate limit hit' do
    assert !Bot::Smooch.user_blocked?(@uid)
    WebMock.stub_request(:post, 'https://graph.facebook.com/v15.0/123456/messages').to_return(status: 400, body: { error: { message: '(#131056) (Business Account, Consumer Account) pair rate limit hit', code: 131056 } }.to_json)
    Bot::Smooch.send_message_to_user(@uid, 'Test', { 'type' => 'text', 'text' => 'Test' })
    Bot::Smooch.send_message_to_user(@uid, 'Test', { 'type' => 'text', 'text' => 'Test' }) # Race condition
    assert Bot::Smooch.user_blocked?(@uid)
    Bot::Smooch.unblock_user(@uid)
    assert !Bot::Smooch.user_blocked?(@uid)
  end

  test "should ignore reaction message" do
    request = OpenStruct.new(params: {
      "object": "whatsapp_business_account",
      "entry": [
          {
              "id": "121774707564591",
              "changes": [
                  {
                      "value": {
                          "messages": [
                              {
                                  "from": "201060407981",
                                  "timestamp": "1700484874",
                                  "type": "reaction",
                                  "reaction": {
                                      "message_id": "wamid.HBgMMjAxMDYwNDA3OTgxFQIAERgSNjFDMEI3NkY4QzA2Mzc4Q0MwAA==",
                                      "emoji": "👍"
                                  }
                              }
                          ]
                      },
                      "field": "messages"
                  }
              ]
          }
      ],
    }.with_indifferent_access)
    assert Bot::Smooch.should_ignore_capi_request?(request)
  end
end
