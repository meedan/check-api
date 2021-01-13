DuplicateTeamMutation = GraphQL::Relay::Mutation.define do
  name 'DuplicateTeamMutation'

  input_field :team_id, !types.ID
  input_field :custom_slug, types.String
  input_field :custom_name, types.String

  return_field :team, TeamType

  resolve -> (_root, inputs, ctx) {
    _type_name, id = CheckGraphql.decode_id(inputs['team_id'])
    user = User.current
    ability = Ability.new(user)
    team = GraphqlCrudOperations.load_if_can(Team, id, ctx)
    raise I18n.t('team_clone.user_not_authorized') if ability.cannot?(:duplicate, team)
    new_team = Team.duplicate(team, inputs['custom_slug'], inputs['custom_name'])
    { team: new_team }
  }
end
