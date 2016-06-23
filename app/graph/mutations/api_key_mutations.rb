module ApiKeyMutations

  Create = GraphQL::Relay::Mutation.define do
    name 'CreateApiKey'
    input_field :application, !types.String

    return_field :api_key, ApiKeyType

    resolve -> (inputs, _ctx) {
      GraphqlCrudOperations.create('api_key', inputs)
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
      GraphqlCrudOperations.update('api_key', inputs, ctx)
    }
  end

  Destroy = GraphQL::Relay::Mutation.define do
    name "DestroyApiKey"

    input_field :id, !types.ID

    resolve -> (inputs, ctx) {
      GraphqlCrudOperations.destroy(inputs, ctx)
    }
  end
end
