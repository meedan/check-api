class PublicTeamType < DefaultObject
  description "Public team type"

  implements NodeIdentification.interface

  field :name, GraphQL::Types::String, null: false
  field :slug, GraphQL::Types::String, null: false
  field :description, GraphQL::Types::String, null: true
  field :dbid, GraphQL::Types::Int, null: true
  field :avatar, GraphQL::Types::String, null: true
  field :private, GraphQL::Types::Boolean, null: true
  field :team_graphql_id, GraphQL::Types::String, null: true

  field :pusher_channel, GraphQL::Types::String, null: true

  def pusher_channel
    Team.find(object.id).pusher_channel
  end

  field :trash_count,
        Integer,
        null: true,
        resolve: ->(team, _args, _ctx) {
          archived_count(team) ? 0 : team.trash_count
        }
  field :unconfirmed_count,
        Integer,
        null: true,
        resolve: ->(team, _args, _ctx) {
          archived_count(team) ? 0 : team.unconfirmed_count
        }
  field :spam_count,
        Integer,
        null: true,
        resolve: ->(team, _args, _ctx) {
          archived_count(team) ? 0 : team.spam_count
        }

  private

  def archived_count(team)
    team.private &&
      (
        !User.current ||
          (
            !User.current.is_admin &&
              TeamUser
                .where(team_id: team.id, user_id: User.current.id)
                .last
                .nil?
          )
      )
  end
end
