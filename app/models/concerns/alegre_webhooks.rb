class AlegreCallbackError < StandardError
end
module AlegreWebhooks
  extend ActiveSupport::Concern
  module ClassMethods
    def webhook(request)
      begin
        doc_id = request.params["data"]["requested"]["body"]["id"]
        redis = Redis.new(REDIS_CONFIG)
        key = "alegre:webhook:#{doc_id}"
        redis.lpush(key, request.params.to_json)
        redis.expire(key, 1.day.to_i)
      rescue StandardError => e
        CheckSentry.notify(AlegreCallbackError.new(e.message), { alegre_response: body })
      end
    end
  end
end
