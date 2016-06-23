module MediaMutations

  Create = GraphQL::Relay::Mutation.define do
    name 'CreateMedia'
    input_field :url, !types.String
    input_field :account_id, !types.Int
    input_field :project_id, !types.Int
    input_field :user_id, !types.Int

    return_field :media, MediaType

    resolve -> (inputs, _ctx) {
      attr = inputs.keys.inject({}) do |memo, key|
        memo[key] = inputs[key] unless key == "clientMutationId"
        memo
      end

      media = Media.create(attr)

      { media: media }
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
      media = NodeIdentification.object_from_id((inputs[:id]), ctx)
      attr = inputs.keys.inject({}) do |memo, key|
        memo[key] = inputs[key] unless key == "clientMutationId" || key == 'id'
        memo
      end

      media.update(attr)
      { media: media }
    }
  end

  Destroy = GraphQL::Relay::Mutation.define do
    name "DestroyMedia"

    input_field :id, !types.ID

    resolve -> (inputs, ctx) {
      media = NodeIdentification.object_from_id((inputs[:id]), ctx)
      media.destroy
      { }
    }
  end
end
