class AccountType < DefaultObject
  description "Account type"

  implements GraphQL::Types::Relay::Node

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
    user = object.user
    ability = context[:ability] || Ability.new
    user if user && ability.can?(:read, user)
  end

  field :medias, MediaType.connection_type, null: true

  def medias
    return object.medias if User.current&.is_admin?
    object.medias.where(id: ProjectMedia.where(team_id: User.current&.cached_teams.to_a).select(:media_id))
  end

  field :metadata, JsonStringType, null: true
end
