class DuplicateTeamMutation < Mutations::BaseMutation
  graphql_name "DuplicateTeamMutation"

  argument :team_id, ID, required: true, camelize: false
  argument :custom_slug, String, required: false, camelize: false
  argument :custom_name, String, required: false, camelize: false

  field :team, TeamType, null: true

  def resolve(**inputs)
    _type_name, id = CheckGraphql.decode_id(inputs[:team_id])
            user = User.current
            ability = Ability.new(user)
            team = GraphqlCrudOperations.load_if_can(Team, id, context)
            if ability.cannot?(:duplicate, team)
              raise I18n.t("team_clone.user_not_authorized")
            end
            new_team =
              Team.duplicate(
                team,
                inputs[:custom_slug],
                inputs[:custom_name]
              )
            { team: new_team }
  end
end
