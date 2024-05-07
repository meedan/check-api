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
      begin
        doc_id = body.dig('data', 'requested', 'id')
        # search for doc_id on completed full-circuit callbacks
        doc_id = body.dig('data', 'item', 'id') if doc_id.nil?
        # search for doc_id on completed short-circuit callbacks (i.e. items already known to Alegre but added context TODO make these the same structure)
        doc_id = body.dig('data', 'item', 'raw', 'doc_id') if doc_id.nil?
        CheckSentry.notify(AlegreCallbackError.new("Tracing Webhook NOT AN ERROR"), params: {is_raised_from_error: false, doc_id: doc_id, is_not_a_bug_is_a_temporary_log_to_sentry: true, alegre_response: request.params, body: body })
        raise 'Unexpected params format' if doc_id.blank?
        if is_from_alegre_search_result_callback(body)
          Bot::Alegre.process_alegre_callback(body)
        else
          key = "alegre:webhook:#{doc_id}"
          redis.lpush(key, body.to_json)
        end
        
      rescue StandardError => e
        CheckSentry.notify(AlegreCallbackError.new(e.message), params: { is_raised_from_error: true, alegre_response: request.params })
      ensure
        redis.expire(key, 1.day.to_i) if !key.nil?
      end
    end
  end
end
