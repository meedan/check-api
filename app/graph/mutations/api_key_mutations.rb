module ApiKeyMutations

  Create = GraphQL::Relay::Mutation.define do
    name 'CreateApiKey'
    input_field :application, !types.String
    input_field :expire_at, !types.String
    input_field :access_token, !types.String

    return_field :api_key, ApiKeyType

    resolve -> (inputs, ctx) {
      root = RootLevel::STATIC
      attr = inputs.keys.inject({}) do |memo, key|
        memo[key] = inputs[key] unless key == "clientMutationId"
        memo
      end

      api_key = ApiKey.create(attr)

      { api_key: api_key }
    }
  end

  Update = GraphQL::Relay::Mutation.define do
    name 'UpdateApiKey'
    input_field :application, types.String
    input_field :expire_at, types.String
    input_field :access_token, types.String

    input_field :id, !types.ID

    return_field :api_key, ApiKeyType

    resolve -> (inputs, ctx) {
      api_key = NodeIdentification.object_from_id((inputs[:id]), ctx)
      attr = inputs.keys.inject({}) do |memo, key|
        memo[key] = inputs[key] unless key == "clientMutationId" || key == 'id'
        memo
      end

      api_key.update(attr)
      { api_key: api_key }
    }
  end

  Destroy = GraphQL::Relay::Mutation.define do
    name "DestroyApiKey"

    input_field :id, !types.ID

    resolve -> (inputs, ctx) {
      api_key = NodeIdentification.object_from_id((inputs[:id]), ctx)
      api_key.destroy
      { }
    }
  end
end
