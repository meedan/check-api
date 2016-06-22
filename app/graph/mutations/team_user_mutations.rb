module TeamUserMutations

  Create = GraphQL::Relay::Mutation.define do
    name 'CreateTeamUser'
    input_field :user_id, !types.Int
    input_field :team_id, !types.Int

    return_field :team_user, TeamUserType

    resolve -> (inputs, ctx) {
      root = RootLevel::STATIC
      attr = inputs.keys.inject({}) do |memo, key|
        memo[key] = inputs[key] unless key == "clientMutationId"
        memo
      end

      team_user = TeamUser.create(attr)

      { team_user: team_user }
    }
  end

  Update = GraphQL::Relay::Mutation.define do
    name 'UpdateTeamUser'
    input_field :user_id, types.Int
    input_field :team_id, types.Int

    input_field :id, !types.ID

    return_field :team_user, TeamUserType

    resolve -> (inputs, ctx) {
      team_user = NodeIdentification.object_from_id((inputs[:id]), ctx)
      attr = inputs.keys.inject({}) do |memo, key|
        memo[key] = inputs[key] unless key == "clientMutationId" || key == 'id'
        memo
      end

      team_user.update(attr)
      { team_user: team_user }
    }
  end

  Destroy = GraphQL::Relay::Mutation.define do
    name "DestroyTeamUser"

    input_field :id, !types.ID

    resolve -> (inputs, ctx) {
      team_user = NodeIdentification.object_from_id((inputs[:id]), ctx)
      team_user.destroy
      { }
    }
  end
end
