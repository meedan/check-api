module SourceMutations

  Create = GraphQL::Relay::Mutation.define do
    name 'CreateSource'
    input_field :avatar, types.String
    input_field :slogan, types.String
    input_field :name, !types.String

    return_field :source, SourceType

    resolve -> (inputs, _ctx) {
      attr = inputs.keys.inject({}) do |memo, key|
        memo[key] = inputs[key] unless key == "clientMutationId"
        memo
      end

      source = Source.create(attr)

      { source: source }
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
      source = NodeIdentification.object_from_id((inputs[:id]), ctx)
      attr = inputs.keys.inject({}) do |memo, key|
        memo[key] = inputs[key] unless key == "clientMutationId" || key == 'id'
        memo
      end

      source.update(attr)
      { source: source }
    }
  end

  Destroy = GraphQL::Relay::Mutation.define do
    name "DestroySource"

    input_field :id, !types.ID

    resolve -> (inputs, ctx) {
      source = NodeIdentification.object_from_id((inputs[:id]), ctx)
      source.destroy
      { }
    }
  end
end
