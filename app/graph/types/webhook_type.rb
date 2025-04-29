class WebhookType < DefaultObject
  description "Represents a Webhook, a BotUser with events and request url"

  implements GraphQL::Types::Relay::Node

  field :dbid, GraphQL::Types::Int, null: true
  field :name, GraphQL::Types::String, null: true
  field :events, JsonStringType, null: true
  field :request_url, GraphQL::Types::String, null: true
  field :headers, JsonStringType, null: true

  def events
    object.get_events
  end

  def request_url
    object.get_request_url
  end

  def headers
    object.get_headers
  end
end
