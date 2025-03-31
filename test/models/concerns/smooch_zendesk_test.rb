require_relative '../../test_helper'

class FakeSmoochZendesk
  include SmoochZendesk

  class << self
    # Mock out config, which is normally set in the Smooch class as
    # RequestStore.store[:smooch_bot_settings]
    def config
      { "smooch_app_id" => 'app-id' }
    end

    def replace_placeholders(uid, text)
      text
    end
  end
end

class SmoochZendeskTest < ActiveSupport::TestCase
  test "#zendesk_send_message_to_user sends a Sentry error for each error returned on failed response" do
    errors = {
      code: "invalid_syntax",
      description: "pt_BR is not a valid parameter"
    }.with_indifferent_access

    fake_api_error = SmoochApi::ApiError.new(response_body: "{\"error\": #{errors.to_json}}")
    SmoochApi::ConversationApi.any_instance.stubs(:post_message).raises(fake_api_error)

    mock_error = mock('error')
    Bot::Smooch::SmoochMessageDeliveryError.expects(:new).with('(invalid_syntax) pt_BR is not a valid parameter').returns(mock_error)
    CheckSentry.expects(:notify).with(mock_error, has_entries(smooch_app_id: 'app-id', uid: 'phone-12345:123456', smooch_body: anything, errors: errors))

    FakeSmoochZendesk.zendesk_send_message_to_user('phone-12345:123456', 'fake text')
  end

  test "should return nil when it tries to get the ID of a message that was not sent because was blank" do
    response = FakeSmoochZendesk.zendesk_send_message_to_user('abc123', '')
    assert_nil Bot::Smooch.get_id_from_send_response(response)
  end
end
