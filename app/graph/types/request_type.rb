class RequestType < DefaultObject
  description "Request type"

  implements NodeIdentification.interface

  field :dbid, Integer, null: true
  field :last_submitted_at, Integer, null: true
  field :request_type, String, null: true
  field :content, String, null: true
  field :last_called_webhook_at, String, null: true
  field :fact_checked_by, String, null: true
  field :subscribed, Boolean, null: true
  field :medias_count, Integer, null: true
  field :requests_count, Integer, null: true
  field :subscriptions_count, Integer, null: true
  field :project_medias_count, Integer, null: true
  field :title, String, null: true
  field :similar_to_request, RequestType, null: true
  field :media_type, String, null: true

  field :feed, FeedType, null: true

  def feed
    RecordLoader.for(Feed).load(object.feed_id)
  end

  field :media, MediaType, null: true

  def media
    RecordLoader.for(Media).load(object.media_id)
  end

  field :medias, MediaType.connection_type, null: true

  field :similar_requests,
        RequestType.connection_type,
        null: true do
    argument :media_id, Integer, required: false
  end

  def similar_requests(**args)
    requests =
      object.similar_requests.where(
        webhook_url: nil,
        last_called_webhook_at: nil
      )
    requests = requests.where(media_id: args[:media_id].to_i) unless args[
      :media_id
    ].blank?
    requests
  end
end
