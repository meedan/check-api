module TeamMutations

  Create = GraphQL::Relay::Mutation.define do
    name 'CreateTeam'
    input_field :archived, !types.Boolean
    input_field :logo, !types.String
    input_field :name, !types.String

    return_field :team, TeamType

    resolve -> (inputs, ctx) {
      root = RootLevel::STATIC
      attr = inputs.keys.inject({}) do |memo, key|
        memo[key] = inputs[key] unless key == "clientMutationId"
        memo
      end

      team = Team.create(attr)

      { team: team }
    }
  end

  Update = GraphQL::Relay::Mutation.define do
    name 'UpdateTeam'
    input_field :archived, types.Boolean
    input_field :logo, types.String
    input_field :name, types.String

    input_field :id, !types.ID

    return_field :team, TeamType

    resolve -> (inputs, ctx) {
      team = NodeIdentification.object_from_id((inputs[:id]), ctx)
      attr = inputs.keys.inject({}) do |memo, key|
        memo[key] = inputs[key] unless key == "clientMutationId" || key == 'id'
        memo
      end

      team.update(attr)
      { team: team }
    }
  end

  Destroy = GraphQL::Relay::Mutation.define do
    name "DestroyTeam"

    input_field :id, !types.ID

    resolve -> (inputs, ctx) {
      team = NodeIdentification.object_from_id((inputs[:id]), ctx)
      team.destroy
      { }
    }
  end
end
