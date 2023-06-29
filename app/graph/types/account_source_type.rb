class AccountSourceType < DefaultObject
  description "AccountSource type"

  implements GraphQL::Types::Relay::Node

  field :account_id, GraphQL::Types::Int, null: true
  field :source_id, GraphQL::Types::Int, null: true

  field :source, SourceType, null: true
  field :account, AccountType, null: true
end
