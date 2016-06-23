module AccountMutations

  Create = GraphQL::Relay::Mutation.define do
    name 'CreateAccount'
    input_field :url, !types.String
    input_field :source_id, !types.Int
    input_field :user_id, !types.Int

    return_field :account, AccountType

    resolve -> (inputs, _ctx) {
      attr = inputs.keys.inject({}) do |memo, key|
        memo[key] = inputs[key] unless key == "clientMutationId"
        memo
      end

      account = Account.create(attr)

      { account: account }
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
      account = NodeIdentification.object_from_id((inputs[:id]), ctx)
      attr = inputs.keys.inject({}) do |memo, key|
        memo[key] = inputs[key] unless key == "clientMutationId" || key == 'id'
        memo
      end

      account.update(attr)
      { account: account }
    }
  end

  Destroy = GraphQL::Relay::Mutation.define do
    name "DestroyAccount"

    input_field :id, !types.ID

    resolve -> (inputs, ctx) {
      account = NodeIdentification.object_from_id((inputs[:id]), ctx)
      account.destroy
      { }
    }
  end
end
