MediaType = GraphqlCrudOperations.define_default_type do
  name 'Media'
  description 'Media type'

  interfaces [NodeIdentification.interface]

  field :id, field: GraphQL::Relay::GlobalIdField.new('Media')
  field :url, types.String
  field :quote, types.String
  field :account_id, types.Int
  field :project_id, types.Int
  field :dbid, types.Int
  field :domain, types.String
  field :pusher_channel, types.String
  field :embed_path, types.String
  field :thumbnail_path, types.String
  field :picture, types.String

  field :account do
    type -> { AccountType }

    resolve -> (media, _args, _ctx) {
      media.account
    }
  end
end
