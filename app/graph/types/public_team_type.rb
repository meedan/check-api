class PublicTeamType < DefaultObject
  description "Public team type"

  implements GraphQL::Types::Relay::Node

  field :name, GraphQL::Types::String, null: false
  field :slug, GraphQL::Types::String, null: false
  field :description, GraphQL::Types::String, null: true
  field :dbid, GraphQL::Types::Int, null: true
  field :avatar, GraphQL::Types::String, null: true
  field :private, GraphQL::Types::Boolean, null: true
  field :team_graphql_id, GraphQL::Types::String, null: true

  field :medias_count, GraphQL::Types::Int, null: true

  def medias_count
    archived_count(object) ? 0 : object.medias_count
  end

  field :trash_count, GraphQL::Types::Int, null: true

  def trash_count
    archived_count(object) ? 0 : object.trash_count
  end

  field :unconfirmed_count, GraphQL::Types::Int, null: true

  def unconfirmed_count
    archived_count(object) ? 0 : object.unconfirmed_count
  end

  field :spam_count, GraphQL::Types::Int, null: true

  def spam_count
    archived_count(object) ? 0 : object.spam_count
  end

  private

  def archived_count(team)
    team.private && (!User.current || (!User.current.is_admin && TeamUser.where(team_id: team.id, user_id: User.current.id).last.nil?))
  end
end
