class WebhookType < DefaultObject
  description "Webhook type"

  implements GraphQL::Types::Relay::Node

  field :dbid, GraphQL::Types::Int, null: true
  field :name, GraphQL::Types::String, null: true
  field :events, GraphQL::Types::String, null: true
  field :request_url, GraphQL::Types::String, null: true
  field :headers, GraphQL::Types::String, null: true

  def events
    object.get_events.to_json
  end

  def request_url
    object.get_request_url
  end

  def headers
    object.get_headers.to_json
  end
end
