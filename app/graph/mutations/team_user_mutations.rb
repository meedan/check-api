module TeamUserMutations

  Create = GraphQL::Relay::Mutation.define do
    name 'CreateTeamUser'
    input_field :user_id, !types.Int
    input_field :team_id, !types.Int

    return_field :team_user, TeamUserType

    resolve -> (inputs, _ctx) {
      GraphqlCrudOperations.create('team_user', inputs)
    }
  end

  Update = GraphQL::Relay::Mutation.define do
    name 'UpdateTeamUser'
    input_field :user_id, types.Int
    input_field :team_id, types.Int

    input_field :id, !types.ID

    return_field :team_user, TeamUserType

    resolve -> (inputs, ctx) {
      GraphqlCrudOperations.update('team_user', inputs, ctx)
    }
  end

  Destroy = GraphQL::Relay::Mutation.define do
    name "DestroyTeamUser"

    input_field :id, !types.ID

    resolve -> (inputs, ctx) {
      GraphqlCrudOperations.destroy(inputs, ctx)
    }
  end
end
