class MediaType < DefaultObject
  description "Media type"

  implements GraphQL::Types::Relay::Node

  field :url, GraphQL::Types::String, null: true
  field :quote, GraphQL::Types::String, null: true
  field :account_id, GraphQL::Types::Int, null: true
  field :dbid, GraphQL::Types::Int, null: true
  field :domain, GraphQL::Types::String, null: true
  field :embed_path, GraphQL::Types::String, null: true
  field :thumbnail_path, GraphQL::Types::String, null: true
  field :picture, GraphQL::Types::String, null: true
  field :type, GraphQL::Types::String, null: true
  field :file_path, GraphQL::Types::String, null: true
  field :metadata, JsonStringType, null: true

  field :account, AccountType, null: true
end
