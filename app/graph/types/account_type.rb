AccountType = GraphQL::ObjectType.define do
  name 'Account'
  description 'Account type'

  interfaces [NodeIdentification.interface]

  field :id, field: GraphQL::Relay::GlobalIdField.new('Account')
  field :updated_at, types.String
  field :created_at, types.String
  field :data, types.String
  field :url, types.String
  field :source_id, types.Int
  field :user_id, types.Int
    field :user do
    type UserType

    resolve -> (account, args, ctx) {
      account.user
    }
  end
  field :source do
    type -> { SourceType }

    resolve -> (account, args, ctx) {
      account.source
    }
  end

  connection :medias, -> { MediaType.connection_type } do
    resolve ->(account, args, ctx) {
      account.medias
    }
  end

# End of fields
end
