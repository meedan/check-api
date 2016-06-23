module TeamMutations

  Create = GraphQL::Relay::Mutation.define do
    name 'CreateTeam'
    input_field :archived, types.Boolean
    input_field :logo, types.String
    input_field :name, !types.String

    return_field :team, TeamType

    resolve -> (inputs, _ctx) {
      GraphqlCrudOperations.create('team', inputs)
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
      GraphqlCrudOperations.update('team', inputs, ctx)
    }
  end

  Destroy = GraphQL::Relay::Mutation.define do
    name "DestroyTeam"

    input_field :id, !types.ID

    resolve -> (inputs, ctx) {
      GraphqlCrudOperations.destroy(inputs, ctx)
    }
  end
end
