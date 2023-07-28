class DuplicateTeamMutation < Mutations::BaseMutation
  argument :team_id, GraphQL::Types::ID, required: true, camelize: false
  argument :custom_slug, GraphQL::Types::String, required: false, camelize: false
  argument :custom_name, GraphQL::Types::String, required: false, camelize: false

  field :team, TeamType, null: true

  def resolve(team_id:, custom_slug: nil, custom_name: nil)
    _type_name, id = CheckGraphql.decode_id(team_id)
            user = User.current
            ability = Ability.new(user)
            team = GraphqlCrudOperations.load_if_can(Team, id, context)
            if ability.cannot?(:duplicate, team)
              raise I18n.t("team_clone.user_not_authorized")
            end
            new_team =
              Team.duplicate(
                team,
                custom_slug,
                custom_name
              )
            { team: new_team }
  end
end
