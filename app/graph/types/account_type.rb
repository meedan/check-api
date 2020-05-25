AccountType = GraphqlCrudOperations.define_default_type do
  name 'Account'
  description 'A social profile belonging to a Source.'

  interfaces [NodeIdentification.interface]

  field :data, types.String, 'TODO'
  field :dbid, types.Int, 'Database id of this record'
  field :url, !types.String, 'Profile URL'
  field :provider, types.String, 'Profile host'
  field :uid, types.String, 'TODO'
  field :user_id, types.Int, 'Creator (id only)'
  field :permissions, types.String, 'CRUD permissions for current user'
  field :image, types.String, 'Picture' # TODO Rename to 'picture'
  field :user do
    type UserType
    description 'Creator'

    resolve -> (account, _args, _ctx) {
      account.user
    }
  end

  connection :medias, -> { MediaType.connection_type } do
    description 'Items published by this account'

    resolve ->(account, _args, _ctx) {
      account.medias
    }
  end

  field :metadata do
    type JsonStringType
    description 'Account metadata'

    resolve ->(account, _args, _ctx) {
      account.metadata
    }
  end
end
