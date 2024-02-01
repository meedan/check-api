class UserType < DefaultObject
  description "User type"

  implements GraphQL::Types::Relay::Node

  field :dbid, GraphQL::Types::Int, null: true
  field :email, GraphQL::Types::String, null: true
  field :profile_image, GraphQL::Types::String, null: true
  field :name, GraphQL::Types::String, null: true
  field :last_active_at, GraphQL::Types::Int, null: true
  field :is_bot, GraphQL::Types::Boolean, null: true
  field :is_active, GraphQL::Types::Boolean, null: true
  field :number_of_teams, GraphQL::Types::Int, null: true

  field :source, SourceType, null: true

  def source
    Source.find(object.source_id)
  end
end
