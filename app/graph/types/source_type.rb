class SourceType < DefaultObject
  include Types::Inclusions::TaskAndAnnotationFields

  description "Source type"

  implements GraphQL::Types::Relay::Node

  field :image, GraphQL::Types::String, null: true
  field :description, GraphQL::Types::String, null: false
  field :name, GraphQL::Types::String, null: false
  field :dbid, GraphQL::Types::Int, null: true
  field :user_id, GraphQL::Types::Int, null: true
  field :permissions, GraphQL::Types::String, null: true
  field :pusher_channel, GraphQL::Types::String, null: true
  field :lock_version, GraphQL::Types::Int, null: true
  field :medias_count, GraphQL::Types::Int, null: true
  field :accounts_count, GraphQL::Types::Int, null: true
  field :overridden, JsonString, null: true
  field :archived, GraphQL::Types::Int, null: true

  field :accounts, AccountType.connection_type, null: true

  field :account_sources,
        AccountSourceType.connection_type,
        null: true

  def account_sources
    object.account_sources.order(id: :asc)
  end

  field :medias,
        ProjectMediaType.connection_type,
        null: true

  def medias
    object.media
  end

  field :medias_count, GraphQL::Types::Int, null: true
  field :collaborators, UserType.connection_type, null: true
end
