MediaType = GraphqlCrudOperations.define_default_type do
  name 'Media'
  description 'The base item type for annotation activity.'

  interfaces [NodeIdentification.interface]

  field :url, types.String, 'Media URL'
  field :quote, types.String, 'Text claim' # TODO Rename to 'claim'
  field :account_id, types.Int, 'Publisher account (id only)'
  field :project_id, types.Int # TODO Remove
  field :domain, types.String, 'TODO'
  field :embed_path, types.String, 'TODO'
  field :thumbnail_path, types.String, 'Thumbnail representing this item' # TODO Rename to 'thumbnail'
  field :picture, types.String, 'Picture representing this item'
  field :type, types.String, 'TODO' # TODO Consider enum type https://graphql.org/learn/schema/#enumeration-types
  field :file_path, types.String, 'TODO'

  field :account do
    type -> { AccountType }
    description 'Publisher account'

    resolve -> (media, _args, _ctx) {
      media.account
    }
  end

  field :metadata do
    type JsonStringType
    description 'Item metadata'

    resolve ->(media, _args, _ctx) {
      media.metadata
    }
  end

  field :dbid, types.Int, 'Database id of this record'
  field :pusher_channel, types.String, 'Channel for push notifications'
end
