class MediaType < DefaultObject
  description "Media type"

  implements NodeIdentification.interface

  field :url, GraphQL::Types::String, null: true
  field :quote, GraphQL::Types::String, null: true
  field :account_id, GraphQL::Types::Integer, null: true
  field :dbid, GraphQL::Types::Integer, null: true
  field :domain, GraphQL::Types::String, null: true
  field :pusher_channel, GraphQL::Types::String, null: true
  field :embed_path, GraphQL::Types::String, null: true
  field :thumbnail_path, GraphQL::Types::String, null: true
  field :picture, GraphQL::Types::String, null: true
  field :type, GraphQL::Types::String, null: true
  field :file_path, GraphQL::Types::String, null: true
  field :metadata, JsonString, null: true

  field :account, AccountType, null: true

  def account
    object.account
  end
end
