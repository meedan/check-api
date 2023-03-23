require_relative '../test_helper'

class TiplineMessageTest < ActiveSupport::TestCase
 test "has a direction enum for each of the supported trigger mapping values" do
  direction_values = TiplineMessage.defined_enums['direction'].keys.map(&:to_sym)
  supported_trigger_mappings = Bot::Smooch::SUPPORTED_TRIGGER_MAPPING.values.uniq.map(&:to_sym)
  assert direction_values.sort == (supported_trigger_mappings + [:direction_unset]).sort
 end

 test "is invalid without required fields" do
   tm = TiplineMessage.new

   assert !tm.valid?

   team = create_team
   tm = TiplineMessage.new(direction: :incoming,
                           team: team,
                           external_id: 'message-id-12345',
                           uid: 'user-id-12345',
                           sent_at: DateTime.now,
                           platform: "Telegram",
                           language: "en",
                           payload: {foo: 'bar'})

   assert tm.valid?
 end

 test "is invalid if it seems to be a duplicate created from a race condition, based on external_id" do
  team = create_team

  TiplineMessage.create(external_id: 'external-id-1', team: team, uid: 'user-id-12345', direction: :incoming, platform: 'whatsapp', language: 'en', sent_at: DateTime.new(2022,1,2), payload: {foo: 'bar'})
  stat = TiplineMessage.new(external_id: 'external-id-1', team: team, uid: 'user-id-12345', direction: :incoming, platform: 'whatsapp', language: 'en', sent_at: DateTime.new(2022,1,3), payload: {foo: 'bar'})
  assert !stat.valid?
 end

 test "parses from smooch json for a message sent to user (message:delivery:channel)" do
  setup_smooch_bot

  @team.set_languages ['en']
  @team.save!

  user_id = random_string

  # For full expected response, see docs at
  # https://docs.smooch.io/rest/v1/#trigger---messagedeliverychannel
  msg = { "_id": @msg_id }
  payload = {
    "trigger": "message:delivery:channel",
    "app": {
        "_id": @app_id
    },
    "appUser": {
        "_id": user_id,
    },
    "conversation": {
        "_id": "105e47578be874292d365ee8"
    },
    "destination": {
        "type": "whatsapp"
    },
    "isFinalEvent": false,
    "externalMessages": [],
    "message": msg,
    "timestamp": 1537891147.555,
    "version": "v1.1"
  }

  tm = TiplineMessage.from_smooch_payload(msg, payload)

  assert tm.outgoing?
  assert_equal tm.team, @team
  assert_equal tm.uid, user_id
  assert_equal tm.external_id, @msg_id
  assert_equal tm.language, 'en'
  assert_equal tm.platform, 'WhatsApp'
  assert_equal tm.sent_at, Time.at(1537891147.555)
  assert_equal payload.with_indifferent_access, tm.payload
 end

 test "parses from smooch json for a message sent from user" do
  setup_smooch_bot

  @team.set_languages ['en']
  @team.save!

  user_id = random_string

  # For full expected response, see docs at
  # https://docs.smooch.io/rest/v1/#trigger---messageappuser-text
  message = {
    "_id": @msg_id,
    "type": "text",
    "role": "appUser",
    "authorId": user_id,
    "received": 1444348338.704,
    "source": {
        "type": "whatsapp"
    }
  }

  payload = {
    "trigger": "message:appUser",
    "app": {
        "_id": @app_id
    },
    "messages": [message],
    "appUser": {
        "_id": user_id,
        "conversationStarted": true,
    },
    "client": {},
    "conversation": {
        "_id": "105e47578be874292d365ee8"
    },
    "version": "v1.1"
  }

  tm = TiplineMessage.from_smooch_payload(message, payload)

  assert tm.incoming?
  assert_equal @team, tm.team
  assert_equal user_id, tm.uid
  assert_equal @msg_id, tm.external_id
  assert_equal 'en', tm.language
  assert_equal 'WhatsApp', tm.platform
  assert_equal Time.at(1444348338.704), tm.sent_at
  assert_equal payload.with_indifferent_access, tm.payload
 end

 # This is to protect against any failures to parse time data - if it's missing,
 # or if the format cannot be parsed. So far we have only seen this in test,
 # but it seems possible in production. If we fall back, we do use our uniqueness
 # protection that is intended to prevent duplicates on race conditions
 test "defaults to current time for sent_at if parsing fails" do
  setup_smooch_bot

  msg = { "_id": @msg_id }
  # payload is missing the timestamp key
  payload = {
    "trigger": "message:delivery:channel",
    "app": {
        "_id": @app_id
    },
    "appUser": {
        "_id": random_string,
    },
    "conversation": {
        "_id": "105e47578be874292d365ee8"
    },
    "destination": {
        "type": "whatsapp"
    },
    "isFinalEvent": false,
    "externalMessages": [],
    "message": msg,
    "version": "v1.1"
  }

  tm = TiplineMessage.from_smooch_payload(msg, payload)
  assert tm.sent_at.present?
 end

 test "sets event when passed" do
    setup_smooch_bot

    tp = TiplineMessage.from_smooch_payload({},{}, 'newsletter_send')
    assert_equal 'newsletter_send', tp.event
 end
end
