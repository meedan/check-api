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
        params = request.params
        puts request.inspect
        doc_id = request.params.dig('data', 'requested', 'id')
        doc_id = request.params.dig('data', 'item', 'id') if doc_id.nil?
        is_from_alegre_callback = request.params.dig('data', 'item', 'callback_url').to_s.include?("/presto/receive/add_item")
        raise 'Unexpected params format' if doc_id.blank?
        if is_from_alegre_callback
          project_media = ProjectMedia.find(request.params.dig('data', 'item', 'raw', 'context', 'project_media_id'))
          confirmed = params.dig('data', 'item', 'raw', 'confirmed')
          field = request.params.dig('data', 'item', 'raw', 'context', 'field')
          project_media, field, confirmed
          key = "alegre:async_results:#{project_media.id}_#{field}_#{confirmed}"
          redis.set(key, Bot::Alegre.cache_items_via_callback(project_media, field, confirmed, results))
          redis.expire(key, 1.day.to_i)
          Bot::Alegre.relate_project_media_callback(project_media, field)
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
#{"model_type":"image","data":{"item":{"id":"Y2hlY2stcHJvamVjdF9tZWRpYS0yMTQt","callback_url":"http://alegre:3100/presto/receive/add_item/image","url":"http://minio:9000/check-api-dev/uploads/uploaded_image/55/09572dedf610aad68090214303c14829.png","text":nil,"raw":{"doc_id":"Y2hlY2stcHJvamVjdF9tZWRpYS0yMTQt","context":{"team_id":49,"project_media_id":214,"has_custom_id":true},"url":"http://minio:9000/check-api-dev/uploads/uploaded_image/55/09572dedf610aad68090214303c14829.png","threshold":0.73,"confirmed":true,"created_at":"2024-03-14T22:05:47.588975","limit":200,"requires_callback":true,"final_task":"search"},"hash_value":"1110101010001011110100000011110010101000000010110101101010100101101111110101101001011010100001011111110101011010010000101010010110101101010110100000001010100101101010111110101000010101011100001110101010101111100001010101001011101010101011010001010101010010"},"results":{"result":[{"id":1,"doc_id":"Y2hlY2stcHJvamVjdF9tZWRpYS0yMTQt","pdq":"1110101010001011110100000011110010101000000010110101101010100101101111110101101001011010100001011111110101011010010000101010010110101101010110100000001010100101101010111110101000010101011100001110101010101111100001010101001011101010101011010001010101010010","url":"http://minio:9000/check-api-dev/uploads/uploaded_image/55/09572dedf610aad68090214303c14829.png","context":[{"team_id":49,"has_custom_id":true,"project_media_id":214}],"score":1.0,"model":"image/pdq"}]}},"token":"[FILTERED]","format":"json","name":"alegre","webhook":{"action":"index","model_type":"image","data":{"item":{"id":"Y2hlY2stcHJvamVjdF9tZWRpYS0yMTQt","callback_url":"http://alegre:3100/presto/receive/add_item/image","url":"http://minio:9000/check-api-dev/uploads/uploaded_image/55/09572dedf610aad68090214303c14829.png","text":nil,"raw":{"doc_id":"Y2hlY2stcHJvamVjdF9tZWRpYS0yMTQt","context":{"team_id":49,"project_media_id":214,"has_custom_id":true},"url":"http://minio:9000/check-api-dev/uploads/uploaded_image/55/09572dedf610aad68090214303c14829.png","threshold":0.73,"confirmed":true,"created_at":"2024-03-14T22:05:47.588975","limit":200,"requires_callback":true,"final_task":"search"},"hash_value":"1110101010001011110100000011110010101000000010110101101010100101101111110101101001011010100001011111110101011010010000101010010110101101010110100000001010100101101010111110101000010101011100001110101010101111100001010101001011101010101011010001010101010010"},"results":{"result":[{"id":1,"doc_id":"Y2hlY2stcHJvamVjdF9tZWRpYS0yMTQt","pdq":"1110101010001011110100000011110010101000000010110101101010100101101111110101101001011010100001011111110101011010010000101010010110101101010110100000001010100101101010111110101000010101011100001110101010101111100001010101001011101010101011010001010101010010","url":"http://minio:9000/check-api-dev/uploads/uploaded_image/55/09572dedf610aad68090214303c14829.png","context":[{"team_id":49,"has_custom_id":true,"project_media_id":214}],"score":1.0,"model":"image/pdq"}]}}}},"time":"2024-03-14 22:05:53 +0000"}