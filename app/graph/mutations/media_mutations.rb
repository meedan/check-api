module MediaMutations

  Create = GraphQL::Relay::Mutation.define do
    name 'CreateMedia'
    input_field :url, !types.String
    input_field :account_id, !types.Int
    input_field :project_id, !types.Int
    input_field :user_id, !types.Int

    return_field :media, MediaType

    resolve -> (inputs, _ctx) {
      GraphqlCrudOperations.create('media', inputs)
    }
  end

  Update = GraphQL::Relay::Mutation.define do
    name 'UpdateMedia'
    input_field :url, types.String
    input_field :account_id, types.Int
    input_field :project_id, types.Int
    input_field :user_id, types.Int

    input_field :id, !types.ID

    return_field :media, MediaType

    resolve -> (inputs, ctx) {
      GraphqlCrudOperations.update('media', inputs, ctx)
    }
  end

  Destroy = GraphQL::Relay::Mutation.define do
    name "DestroyMedia"

    input_field :id, !types.ID

    resolve -> (inputs, ctx) {
      GraphqlCrudOperations.destroy(inputs, ctx)
    }
  end
end
