class AlegreCallbackError < StandardError
end
module AlegreWebhooks
  extend ActiveSupport::Concern
  module ClassMethods
    def webhook(request)
      #at this point, we know that the data is stored and ready for querying, so we can safely query based on package of:
      # return requests.post(f"{check_api_host}/api/webhooks/alegre", json={
      #     "action": action,
      #     "model_type": model_type,
      #     "data": data,
      # })
      begin
        doc_id = request.params["data"]["requested"]["body"]["id"]
        redis = Redis.new(REDIS_CONFIG)
        redis.lpush(doc_id, request.params.to_json)
        redis.expire(doc_id, 1.day.to_i)
      rescue StandardError => e
        CheckSentry.notify(AlegreCallbackError.new(e.message), { alegre_response: body })
      end
    end
  end
end
