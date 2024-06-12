class AlegreCallbackError < StandardError
end

module AlegreWebhooks
  extend ActiveSupport::Concern

  module ClassMethods
    def valid_request?(request)
      token = request.params['token'] || request.query_parameters['token']
      !token.blank? && token == CheckConfig.get('alegre_token')
    end

    def is_from_alegre_search_result_callback(params)
      params.dig('data', 'is_shortcircuited_search_result_callback') || params.dig('data', 'is_search_result_callback')
    end

    def parse_body(request)
      JSON.parse(request.body.read)
    end

    def webhook(request)
      key = nil
      body = parse_body(request)
      redis = Redis.new(REDIS_CONFIG)
      doc_id = body.dig('data', 'requested', 'id')
      # search for doc_id on completed full-circuit callbacks
      doc_id = body.dig('data', 'item', 'id') if doc_id.nil?
      # search for doc_id on completed short-circuit callbacks (i.e. items already known to Alegre but added context TODO make these the same structure)
      doc_id = body.dig('data', 'item', 'raw', 'doc_id') if doc_id.nil?
      if doc_id.blank?
        CheckSentry.notify(AlegreCallbackError.new('Unexpected params format from Alegre'), params: {alegre_response: request.params, body: body})
      end
      if is_from_alegre_search_result_callback(body)
        Bot::Alegre.process_alegre_callback(body)
      else
        key = "alegre:webhook:#{doc_id}"
        redis.lpush(key, body.to_json)
        redis.expire(key, 1.day.to_i) if !key.nil?
      end
    end
  end
end
