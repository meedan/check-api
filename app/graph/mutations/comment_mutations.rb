module CommentMutations

  Create = GraphQL::Relay::Mutation.define do
    name 'CreateComment'
    input_field :text, !types.String
    input_field :context_id, types.String
    input_field :context_type, types.String
    input_field :annotated_id, types.String
    input_field :annotated_type, types.String

    return_field :comment, CommentType

    resolve -> (inputs, _ctx) {
      GraphqlCrudOperations.create('comment', inputs)
    }
  end

  Update = GraphQL::Relay::Mutation.define do
    name 'UpdateComment'
    input_field :text, types.String
    input_field :context_id, types.String
    input_field :context_type, types.String
    input_field :annotated_id, types.String
    input_field :annotated_type, types.String
    input_field :version_index, types.Int
    input_field :annotation_type, types.String

    input_field :id, !types.ID

    return_field :comment, CommentType

    resolve -> (inputs, ctx) {
      GraphqlCrudOperations.update('comment', inputs, ctx)
    }
  end

  Destroy = GraphQL::Relay::Mutation.define do
    name "DestroyComment"

    input_field :id, !types.ID

    resolve -> (inputs, ctx) {
      GraphqlCrudOperations.destroy(inputs, ctx)
    }
  end
end
