module SourceMutations

  Create = GraphQL::Relay::Mutation.define do
    name 'CreateSource'
    input_field :avatar, types.String
    input_field :slogan, types.String
    input_field :name, !types.String

    return_field :source, SourceType

    resolve -> (inputs, _ctx) {
      GraphqlCrudOperations.create('source', inputs)
    }
  end

  Update = GraphQL::Relay::Mutation.define do
    name 'UpdateSource'
    input_field :avatar, types.String
    input_field :slogan, types.String
    input_field :name, types.String

    input_field :id, !types.ID

    return_field :source, SourceType

    resolve -> (inputs, ctx) {
      GraphqlCrudOperations.update('source', inputs, ctx)
    }
  end

  Destroy = GraphQL::Relay::Mutation.define do
    name "DestroySource"

    input_field :id, !types.ID

    resolve -> (inputs, ctx) {
      GraphqlCrudOperations.destroy(inputs, ctx)
    }
  end
end
