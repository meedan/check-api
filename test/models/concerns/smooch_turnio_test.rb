require 'test_helper'

class FakeSmoochTurnio
  include SmoochTurnio

  class << self
    # Mock out config, which is normally set in the Smooch class as
    # RequestStore.store[:smooch_bot_settings]
    def config
      {'turnio_secret' => 'secret-12345', 'turnio_phone' => 'phone-12345'}
    end
  end
end

class SmoochTurnioTest < ActiveSupport::TestCase
  test "#preprocess_turnio_message processes delivered messages, including falling back to message recipient_id when top-level is not available" do
    payload = {
      "statuses": [
        {
          "conversation": {
            "id": "fcd809f3194ed089c83d09129d664623",
            "origin": {
              "type": "user_initiated"
            }
          },
          "id": "gBGGFBmZaYRvAglfBtKPeos4sV4",
          "message": {
            "recipient_id": "15551234567"
          },
          "pricing": {
            "billable": true,
            "category": "user_initiated",
            "pricing_model": "CBP"
          },
          "status": "delivered",
          "timestamp": "1676930082",
          "type": "message"
        }
      ]
    }

    message = FakeSmoochTurnio.preprocess_turnio_message(payload.to_json)

    assert_equal 'message:delivery:channel', message['trigger']
    assert_equal 'gBGGFBmZaYRvAglfBtKPeos4sV4', message['message']['_id']
    assert_equal 'secret-12345', message['app']['_id']
    assert_equal 'phone-12345:15551234567', message['appUser']['_id']
    assert message['turnIo']
  end

  test "#preprocess_turnio_message processes delivery failures, including falling back to message recipient_id when top-level is not available" do
    payload = {
      "statuses": [
        {
          "conversation": {
            "id": "fcd809f3194ed089c83d09129d664623",
            "origin": {
              "type": "user_initiated"
            }
          },
          "id": "gBGGFBmZaYRvAglfBtKPeos4sV4",
          "message": {
            "recipient_id": "15551234567"
          },
          "pricing": {
            "billable": true,
            "category": "user_initiated",
            "pricing_model": "CBP"
          },
          "status": "failed",
          "timestamp": "1676930082",
          "type": "message"
        }
      ]
    }

    message = FakeSmoochTurnio.preprocess_turnio_message(payload.to_json)

    assert_equal 'message:delivery:failure', message['trigger']
    assert_equal 'gBGGFBmZaYRvAglfBtKPeos4sV4', message['message']['_id']
    assert_equal 'secret-12345', message['app']['_id']
    assert_equal 'phone-12345:15551234567', message['appUser']['_id']
    assert_equal 470, message.dig('error', 'underlyingError', 'errors', 0, 'code')
    assert message['turnIo']
  end
end
