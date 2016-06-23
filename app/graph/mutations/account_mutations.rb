module AccountMutations

  Create = GraphQL::Relay::Mutation.define do
    name 'CreateAccount'
    input_field :url, !types.String
    input_field :source_id, !types.Int
    input_field :user_id, !types.Int

    return_field :account, AccountType

    resolve -> (inputs, _ctx) {
      GraphqlCrudOperations.create('account', inputs)
    }
  end

  Update = GraphQL::Relay::Mutation.define do
    name 'UpdateAccount'
    input_field :url, types.String
    input_field :source_id, types.Int
    input_field :user_id, types.Int
    input_field :id, !types.ID

    return_field :account, AccountType

    resolve -> (inputs, ctx) {
      GraphqlCrudOperations.update('account', inputs, ctx)
    }
  end

  Destroy = GraphQL::Relay::Mutation.define do
    name "DestroyAccount"

    input_field :id, !types.ID

    resolve -> (inputs, ctx) {
      GraphqlCrudOperations.destroy(inputs, ctx)
    }
  end
end
