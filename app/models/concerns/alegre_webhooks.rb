module AlegreWebhooks
  extend ActiveSupport::Concern

  module ClassMethods
    def get_alegre_type(request)
      case request.params["action"]
      when "audio__Model"
        return "audio"
      when "image__Model"
        return "image"
      when "video__Model"
        return "video"
      when "mean_tokens__Model"
        return "text"
      when "fptg__Model"
        return "text"
      when "indian_sbert__Model"
        return "text"
      end
    end

    def webhook(request)
      #at this point, we know that the data is stored and ready for querying, so we can safely query based on package of:
      # return requests.post(f"{check_api_host}/api/webhooks/alegre", json={
      #     "action": action,
      #     "model_type": model_type,
      #     "data": data,
      # })
      type = get_alegre_type(request)
      pm = ProjectMedia.find(request.params["data"]["requested"]["body"]["context"]["project_media_id"])
      suggested_or_confirmed = Bot::Alegre.get_items_with_similarity(type, pm, Bot::Alegre.get_threshold_for_query(type, pm), 'body')
      Rails.logger.info("[Alegre Bot] [ProjectMedia ##{pm.id}] [Similarity 4/5] suggested_or_confirmed for #{pm.id} is #{suggested_or_confirmed.inspect}")
      confirmed = Bot::Alegre.get_items_with_similarity(type, pm, Bot::Alegre.get_threshold_for_query(type, pm, true))
      Rails.logger.info("[Alegre Bot] [ProjectMedia ##{pm.id}] [Similarity 5/5] confirmed for #{pm.id} is #{confirmed.inspect}")
      Bot::Alegre.merge_suggested_and_confirmed(suggested_or_confirmed, confirmed, pm)
    end
  end
end