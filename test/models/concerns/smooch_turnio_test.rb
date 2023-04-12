require 'test_helper'

class FakeSmoochTurnio
  include SmoochTurnio

  class << self
    # Mock out config, which is normally set in the Smooch class as
    # RequestStore.store[:smooch_bot_settings]
    def config
      { "turnio_secret" => "secret-12345", "turnio_phone" => "phone-12345" }
    end
  end
end

class SmoochTurnioTest < ActiveSupport::TestCase
  test "#preprocess_turnio_message coerces sent messages into Smooch payload format (text)" do
    payload = {
      contacts: [{ profile: { name: "example username" }, wa_id: "15551234567" }],
      messages: [
        {
          from: "15551234567",
          id: "id-example-123456",
          text: {
            body: "Hi"
          },
          timestamp: "1677027447",
          type: "text"
        }
      ]
    }

    new_payload = FakeSmoochTurnio.preprocess_turnio_message(payload.to_json)
    message = new_payload['messages'][0]

    assert_equal 'message:appUser', new_payload['trigger']
    assert_equal 'secret-12345', new_payload['app']['_id']
    assert new_payload['turnIo']

    assert_equal 'id-example-123456', message['_id']
    assert_equal 'text', message['type']
    assert_equal 'phone-12345:15551234567', message['authorId']
    assert_equal 'example username', message['name']
    assert_equal 'Hi', message['text']
    assert_equal 'whatsapp', message['source']['type']
    assert_equal 'id-example-123456', message['source']['originalMessageId']
    assert_equal 1677027447, message['received']
  end

  test "#preprocess_turnio_message coerces delivered messages into Smooch payload format, including falling back to message recipient_id when top-level is not available" do
    payload = {
      statuses: [
        {
          conversation: {
            id: "fcd809f3194ed089c83d09129d664623",
            origin: {
              type: "user_initiated"
            }
          },
          id: "gBGGFBmZaYRvAglfBtKPeos4sV4",
          message: {
            recipient_id: "15551234567"
          },
          pricing: {
            billable: true,
            category: "user_initiated",
            pricing_model: "CBP"
          },
          status: "delivered",
          timestamp: "1676930082",
          type: "message"
        }
      ]
    }

    message = FakeSmoochTurnio.preprocess_turnio_message(payload.to_json)

    assert_equal "message:delivery:channel", message["trigger"]
    assert_equal "gBGGFBmZaYRvAglfBtKPeos4sV4", message["message"]["_id"]
    assert_equal "secret-12345", message["app"]["_id"]
    assert_equal "phone-12345:15551234567", message["appUser"]["_id"]
    assert_equal "whatsapp", message["destination"]["type"]
    assert_equal 1676930082, message["timestamp"]
    assert message["turnIo"]
  end

  test "#preprocess_turnio_message coerces failed messages into Smooch payload format, including falling back to message recipient_id when top-level is not available" do
    payload = {
      statuses: [
        {
          conversation: {
            id: "fcd809f3194ed089c83d09129d664623",
            origin: {
              type: "user_initiated"
            }
          },
          id: "gBGGFBmZaYRvAglfBtKPeos4sV4",
          message: {
            recipient_id: "15551234567"
          },
          pricing: {
            billable: true,
            category: "user_initiated",
            pricing_model: "CBP"
          },
          status: "failed",
          timestamp: "1676930082",
          type: "message"
        }
      ]
    }

    message = FakeSmoochTurnio.preprocess_turnio_message(payload.to_json)

    assert_equal "message:delivery:failure", message["trigger"]
    assert_equal "gBGGFBmZaYRvAglfBtKPeos4sV4", message["message"]["_id"]
    assert_equal "secret-12345", message["app"]["_id"]
    assert_equal "phone-12345:15551234567", message["appUser"]["_id"]
    assert_equal 470, message.dig("error", "underlyingError", "errors", 0, "code")
    assert_equal "whatsapp", message["destination"]["type"]
    assert_equal 1676930082, message["timestamp"]
    assert message["turnIo"]
  end

  test "#preprocess_turnio_message coerces messages of unrecognized type into valid json" do
    payload = {}

    message = FakeSmoochTurnio.preprocess_turnio_message(payload.to_json)

    assert_equal 'message:other', message['trigger']
    assert_equal 'secret-12345', message['app']['_id']
    assert_equal '', message['appUser']['_id']
    assert message['appUser']['conversationStarted']
    assert message['turnIo']
  end

  test "#turnio_send_message_to_user sends a Sentry error for each error returned on failed response" do
    errors = [
      {
        code: 2000,
        details: { body: "number of localizable_params (3) does not match the expected number of params (1)" },
        href: "https://developers.facebook.com/docs/whatsapp/faq#faq_1612022582274564",
        title: "Number of parameters does not match the expected number of params"
      },
      {
        code: 4000,
        details: { body: "some sort of fake error" },
        href: "https://example.com/errors",
        title: "Facebook returns an array so presumably this happens in real life"
      }
    ]
    WebMock.stub_request(:post, 'https://whatsapp.turn.io/v1/messages').to_return(status: 500, body: "{\"errors\": #{errors.to_json}}")

    mock_error = mock('error')
    Bot::Smooch::TurnioMessageDeliveryError.expects(:new).with('(2000) Number of parameters does not match the expected number of params').returns(mock_error)
    Bot::Smooch::TurnioMessageDeliveryError.expects(:new).with('(4000) Facebook returns an array so presumably this happens in real life').returns(mock_error)
    CheckSentry.expects(:notify).with(mock_error, uid: 'phone-12345:123456', error: errors[0].with_indifferent_access, type: 'template', template_name: 'template_123', template_language: 'en')
    CheckSentry.expects(:notify).with(mock_error, uid: 'phone-12345:123456', error: errors[1].with_indifferent_access, type: 'template', template_name: 'template_123', template_language: 'en')

    FakeSmoochTurnio.turnio_send_message_to_user('phone-12345:123456',
      {
        type: 'template',
        template: {
          name: 'template_123',
          language: {
            code: 'en'
          }
        }
      }
    )
  end
end
