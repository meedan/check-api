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
      pm = ProjectMedia.find(request.params["data"]["requested"]["body"]["context"]["project_media_id"])
      relate_project_media_to_similar_items(pm)
    end
  end
end
