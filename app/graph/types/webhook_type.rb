class WebhookType < DefaultObject
  description "Webhook type"

  implements GraphQL::Types::Relay::Node

  field :dbid, GraphQL::Types::Int, null: true
  field :name, GraphQL::Types::String, null: true
  field :events, GraphQL::Types::String, null: true
  field :get_request_url, GraphQL::Types::String, null: true

  def get_request_url
    object.get_request_url
  end
end
