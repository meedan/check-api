AccountType = GraphqlCrudOperations.define_default_type do
  name 'Account'
  description 'Account type'

  interfaces [NodeIdentification.interface]

  field :data, types.String
  field :dbid, types.Int
  field :url, !types.String
  field :provider, types.String
  field :uid, types.String
  field :user_id, types.Int
  field :permissions, types.String
  field :image, types.String
  field :user do
    type UserType

    resolve -> (account, _args, _ctx) {
      account.user
    }
  end

  connection :medias, -> { MediaType.connection_type } do
    resolve ->(account, _args, _ctx) {
      account.medias
    }
  end

  field :metadata do
    type JsonStringType

    resolve ->(account, _args, _ctx) {
      account.metadata
    }
  end

# End of fields
end
