class AlegreCallbackError < StandardError
end

module AlegreWebhooks
  extend ActiveSupport::Concern

  module ClassMethods
    def valid_request?(request)
      token = request.params['token'] || request.query_parameters['token']
      !token.blank? && token == CheckConfig.get('alegre_token')
    end

    def webhook(request)
      begin
        doc_id = request.params.dig('data', 'requested', 'body', 'id')
        raise 'Unexpected params format' if doc_id.blank?
        redis = Redis.new(REDIS_CONFIG)
        key = "alegre:webhook:#{doc_id}"
        redis.lpush(key, request.params.to_json)
        redis.expire(key, 1.day.to_i)
      rescue StandardError => e
        CheckSentry.notify(AlegreCallbackError.new(e.message), { alegre_response: request.params })
      end
    end
  end
end
