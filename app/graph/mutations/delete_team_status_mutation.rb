DeleteTeamStatusMutation = GraphQL::Relay::Mutation.define do
  name 'DeleteTeamStatus'

  input_field :team_id, !types.ID
  input_field :status_id, !types.String
  input_field :fallback_status_id, !types.String

  return_field :team, TeamType

  resolve -> (_root, inputs, ctx) {
    _type_name, id = CheckGraphql.decode_id(inputs['team_id'])
    team = GraphqlCrudOperations.load_if_can(Team, id, ctx)
    team.delete_custom_media_verification_status(inputs['status_id'], inputs['fallback_status_id'])
    { team: team }
  }
end
