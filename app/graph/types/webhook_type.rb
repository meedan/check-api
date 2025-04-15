class WebhookType < DefaultObject
  description "Webhook type"

  implements GraphQL::Types::Relay::Node

  field :dbid, GraphQL::Types::Int, null: true
  field :name, GraphQL::Types::String, null: true
end
