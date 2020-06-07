AccountType = GraphqlCrudOperations.define_default_type do
  name 'Account'
  description 'A web site or social account associated with a source.'

  interfaces [NodeIdentification.interface]

  field :data, types.String # TODO Review
  field :url, !types.String, 'Account URL'
  field :provider, types.String, 'Account host'
  field :uid, types.String, 'Account id on host'
  field :image, types.String, 'Picture' # TODO Rename to 'picture'
  connection :medias, -> { MediaType.connection_type }, 'Items published by this account' do
    resolve ->(account, _args, _ctx) {
      account.medias
    }
  end

  field :metadata, JsonStringType, 'Account metadata' do
    resolve ->(account, _args, _ctx) {
      account.metadata
    }
  end

  field :dbid, types.Int, 'Database id of this record'
  field :user_id, types.Int, 'Database id of record creator'
  field :permissions, types.String, 'CRUD permissions of this record for current user'
  field :user, UserType, 'Record creator' do
    resolve -> (account, _args, _ctx) {
      account.user
    }
  end
end
