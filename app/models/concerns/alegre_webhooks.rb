class AlegreCallbackError < StandardError
end

module AlegreWebhooks
  extend ActiveSupport::Concern

  module ClassMethods
    def valid_request?(request)
      token = request.params['token'] || request.query_parameters['token']
      !token.blank? && token == CheckConfig.get('alegre_token')
    end

    def is_from_alegre_callback(request)
      request.params.dig('data', 'item', 'callback_url').to_s.include?("/presto/receive/add_item") || request.params.dig('data', 'is_shortcircuited_callback')
    end

    def webhook(request)
      key = nil
      begin
        doc_id = request.params.dig('data', 'requested', 'id')
        # search for doc_id on completed full-circuit callbacks
        doc_id = request.params.dig('data', 'item', 'id') if doc_id.nil?
        # search for doc_id on completed short-circuit callbacks (i.e. items already known to Alegre but added context TODO make these the same structure)
        doc_id = request.params.dig('data', 'item', 'raw', 'doc_id') if doc_id.nil?
        raise 'Unexpected params format' if doc_id.blank?
        if is_from_alegre_callback(request)
          Bot::Alegre.process_alegre_callback(request.params)
        else
          redis = Redis.new(REDIS_CONFIG)
          key = "alegre:webhook:#{doc_id}"
          redis.lpush(key, request.params.to_json)
        end
      rescue StandardError => e
        CheckSentry.notify(AlegreCallbackError.new(e.message), params: { alegre_response: request.params })
      ensure
        redis.expire(key, 1.day.to_i) if !key.nil?
      end
    end
  end
end
