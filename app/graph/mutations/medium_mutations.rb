module MediumMutations

  Create = GraphQL::Relay::Mutation.define do
    name 'CreateMedium'
    input_field :data, !types.String
    input_field :url, !types.String
    input_field :account_id, !types.Int
    input_field :project_id, !types.Int
    input_field :user_id, !types.Int

    return_field :medium, MediumType

    resolve -> (inputs, ctx) {
      root = RootLevel::STATIC
      attr = inputs.keys.inject({}) do |memo, key|
        memo[key] = inputs[key] unless key == "clientMutationId"
        memo
      end

      medium = Medium.create(attr)

      { medium: medium }
    }
  end

  Update = GraphQL::Relay::Mutation.define do
    name 'UpdateMedium'
    input_field :data, types.String
    input_field :url, types.String
    input_field :account_id, types.Int
    input_field :project_id, types.Int
    input_field :user_id, types.Int

    input_field :id, !types.ID

    return_field :medium, MediumType

    resolve -> (inputs, ctx) {
      medium = NodeIdentification.object_from_id((inputs[:id]), ctx)
      attr = inputs.keys.inject({}) do |memo, key|
        memo[key] = inputs[key] unless key == "clientMutationId" || key == 'id'
        memo
      end

      medium.update(attr)
      { medium: medium }
    }
  end

  Destroy = GraphQL::Relay::Mutation.define do
    name "DestroyMedium"

    input_field :id, !types.ID

    resolve -> (inputs, ctx) {
      medium = NodeIdentification.object_from_id((inputs[:id]), ctx)
      medium.destroy
      { }
    }
  end
end
