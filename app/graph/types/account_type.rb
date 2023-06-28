class AccountType < DefaultObject
  description "Account type"

  implements NodeIdentification.interface

  field :data, GraphQL::Types::String, null: true
  field :dbid, GraphQL::Types::Int, null: true
  field :url, GraphQL::Types::String, null: false
  field :provider, GraphQL::Types::String, null: true
  field :uid, GraphQL::Types::String, null: true
  field :user_id, GraphQL::Types::Int, null: true
  field :permissions, GraphQL::Types::String, null: true
  field :image, GraphQL::Types::String, null: true
  field :user, UserType, null: true

  def user
    object.user
  end

  field :medias, MediaType.connection_type, null: true

  def medias
    object.medias
  end

  field :metadata, JsonString, null: true

  def metadata
    object.metadata
  end
end
