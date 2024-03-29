class DeleteTeamStatusMutation < Mutations::BaseMutation
  graphql_name "DeleteTeamStatus"

  argument :team_id, GraphQL::Types::ID, required: true, camelize: false
  argument :status_id, GraphQL::Types::String, required: true, camelize: false
  argument :fallback_status_id, GraphQL::Types::String, required: true, camelize: false

  field :team, TeamType, null: true

  def resolve(team_id:, status_id:, fallback_status_id:)
    _type_name, id = CheckGraphql.decode_id(team_id)
            team = GraphqlCrudOperations.load_if_can(Team, id, context)
            team.delete_custom_media_verification_status(
              status_id,
              fallback_status_id
            )
            { team: team }
  end
end
