class PublicTeamType < DefaultObject
  description "Public team type"

  implements NodeIdentification.interface

  field :name, String, null: false
  field :slug, String, null: false
  field :description, String, null: true
  field :dbid, Integer, null: true
  field :avatar, String, null: true
  field :private, Boolean, null: true
  field :team_graphql_id, String, null: true

  field :pusher_channel, String, null: true

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
