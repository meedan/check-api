module CommentMutations

  Create = GraphQL::Relay::Mutation.define do
    name 'CreateComment'
    input_field :text, !types.String
    input_field :context_id, !types.String
    input_field :context_type, !types.String
    input_field :annotated_id, !types.String
    input_field :annotated_type, !types.String

    return_field :comment, CommentType

    resolve -> (inputs, ctx) {
      root = RootLevel::STATIC
      attr = inputs.keys.inject({}) do |memo, key|
        memo[key] = inputs[key] unless key == "clientMutationId"
        memo
      end

      comment = Comment.create(attr)

      { comment: comment }
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
      comment = NodeIdentification.object_from_id((inputs[:id]), ctx)
      attr = inputs.keys.inject({}) do |memo, key|
        memo[key] = inputs[key] unless key == "clientMutationId" || key == 'id'
        memo
      end

      comment.update(attr)
      { comment: comment }
    }
  end

  Destroy = GraphQL::Relay::Mutation.define do
    name "DestroyComment"

    input_field :id, !types.ID

    resolve -> (inputs, ctx) {
      comment = NodeIdentification.object_from_id((inputs[:id]), ctx)
      comment.destroy
      { }
    }
  end
end
