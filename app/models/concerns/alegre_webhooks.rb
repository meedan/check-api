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
        puts request.inspect
        doc_id = request.params.dig('data', 'requested', 'id')
        doc_id = request.params.dig('data', 'item', 'id') if doc_id.nil?
        is_from_alegre_callback = request.params.dig('data', 'item', 'callback_url').to_s.include?("/presto/receive/add_item")
        raise 'Unexpected params format' if doc_id.blank?
        if is_from_alegre_callback
          Bot::Alegre.process_alegre_callback(request.params)
        else
          redis = Redis.new(REDIS_CONFIG)
          key = "alegre:webhook:#{doc_id}"
          redis.lpush(key, request.params.to_json)
          redis.expire(key, 1.day.to_i)
        end
      rescue StandardError => e
        CheckSentry.notify(AlegreCallbackError.new(e.message), params: { alegre_response: request.params })
      end
    end
  end
end
