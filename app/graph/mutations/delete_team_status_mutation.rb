class DeleteTeamStatusMutation < Mutations::BaseMutation
  graphql_name "DeleteTeamStatus"

  argument :team_id, ID, required: true, camelize: false
  argument :status_id, String, required: true, camelize: false
  argument :fallback_status_id, String, required: true, camelize: false

  field :team, TeamType, null: true

  def resolve(**inputs)
    _type_name, id = CheckGraphql.decode_id(inputs[:team_id])
            team = GraphqlCrudOperations.load_if_can(Team, id, context)
            team.delete_custom_media_verification_status(
              inputs[:status_id],
              inputs[:fallback_status_id]
            )
            { team: team }
  end
end
