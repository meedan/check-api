require_relative '../test_helper'

class TiplineMessageTest < ActiveSupport::TestCase
  def setup
    super
    setup_smooch_bot
  end

  test "has a direction enum for each of the supported trigger mapping values" do
    direction_values = TiplineMessage.defined_enums['direction'].keys.map(&:to_sym)
    supported_trigger_mappings = Bot::Smooch::SUPPORTED_TRIGGER_MAPPING.values.uniq.map(&:to_sym)
    assert direction_values.sort == (supported_trigger_mappings + [:direction_unset]).sort
  end

  test "should validate required fields" do
    [:team_id, :uid, :platform, :language, :direction, :sent_at, :payload, :state].each do |field|
      assert_raises ActiveRecord::RecordInvalid do
        create_tipline_message "#{field}": nil
      end
    end
    assert_difference 'TiplineMessage.count' do
      create_tipline_message
    end
  end

  test "parses from smooch json for a message sent to user (message:delivery:channel)" do
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
    assert_equal @team, tm.team
    assert_equal user_id, tm.uid
    assert_equal @msg_id, tm.external_id
    assert_equal 'en', tm.language
    assert_equal 'WhatsApp', tm.platform
    assert_equal Time.at(1537891147.555), tm.sent_at
    assert_equal payload.with_indifferent_access, tm.payload
    assert_equal 'delivered', tm.state
  end

  test "parses from smooch json for a message sent from user" do
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
    tp = TiplineMessage.from_smooch_payload({},{}, 'newsletter_send')
    assert_equal 'newsletter_send', tp.event
  end

  test "should validate state value" do
    assert_difference 'TiplineMessage.count' do
      create_tipline_message state: 'received'
    end
    assert_raises ActiveRecord::RecordInvalid do
      create_tipline_message state: 'invalid'
    end
  end

  test "should ignore duplicate when saving" do
    id = random_string
    data = {
      uid: random_string,
      team_id: create_team.id,
      language: 'en',
      platform: 'WhatsApp',
      sent_at: DateTime.now,
      payload: {'foo' => 'bar'}
    }
    assert_nothing_raised do
      assert_difference 'TiplineMessage.count' do
        tm = TiplineMessage.new(data)
        tm.direction = :outgoing
        tm.external_id = id
        tm.state = 'sent'
        tm.save_ignoring_duplicate!
      end
      assert_difference 'TiplineMessage.count' do
        tm = TiplineMessage.new(data)
        tm.direction = :outgoing
        tm.external_id = id
        tm.state = 'delivered'
        tm.save_ignoring_duplicate!
      end
      assert_difference 'TiplineMessage.count' do
        tm = TiplineMessage.new(data)
        tm.direction = :incoming
        tm.external_id = random_string
        tm.state = 'received'
        tm.save_ignoring_duplicate!
      end
      assert_no_difference 'TiplineMessage.count' do
        tm = TiplineMessage.new(data)
        tm.direction = :outgoing
        tm.external_id = id
        tm.state = 'sent'
        tm.save_ignoring_duplicate!
      end
      assert_no_difference 'TiplineMessage.count' do
        tm = TiplineMessage.new(data)
        tm.direction = :outgoing
        tm.external_id = id
        tm.state = 'delivered'
        tm.save_ignoring_duplicate!
      end
    end
  end

  test "should block user when rate limit is reached" do
    uid = random_string
    assert !Bot::Smooch.user_blocked?(uid)
    stub_configs({ 'tipline_user_max_messages_per_day' => 2 }) do
      # User sent a message
      create_tipline_message uid: uid, state: 'received'
      assert !Bot::Smooch.user_blocked?(uid)
      # User sent a message
      create_tipline_message uid: uid, state: 'received'
      assert !Bot::Smooch.user_blocked?(uid)
      # Another user sent a message
      create_tipline_message state: 'received'
      assert !Bot::Smooch.user_blocked?(uid)
      # User received a message
      create_tipline_message uid: uid, state: 'delivered'
      assert !Bot::Smooch.user_blocked?(uid)
      # User sent a message and is now over rate limit, so should be blocked
      create_tipline_message uid: uid, state: 'received'
      assert Bot::Smooch.user_blocked?(uid)
    end
  end
end
