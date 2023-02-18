require 'bot/smooch'
require 'json'

class SmoochTiplineMessageWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'smooch'

  def perform(message_json, payload_json)
    app_id = payload_json.dig('app', '_id')
    User.current = BotUser.smooch_user
    Bot::Smooch.get_installation(
      Bot::Smooch.installation_setting_id_keys,
      app_id
    )

    event = nil
    cached_message = Rails.cache.read("smooch:original:#{message_json.dig('_id')}")
    begin
      event = JSON.parse(cached_message).dig('fallback_template')
    rescue TypeError, JSON::ParserError
      event = nil
    end

    tm = TiplineMessage.from_smooch_payload(message_json, payload_json, event)
    tm.save

    User.current = nil
  end
end
