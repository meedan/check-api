class AccountSourceType < DefaultObject
  description "AccountSource type"

  implements NodeIdentification.interface

  field :account_id, GraphQL::Types::Int, null: true
  field :source_id, GraphQL::Types::Int, null: true

  field :source, SourceType, null: true
  field :account, AccountType, null: true
end
