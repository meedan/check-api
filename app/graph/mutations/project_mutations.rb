module ProjectMutations

  Create = GraphQL::Relay::Mutation.define do
    name 'CreateProject'
    input_field :lead_image, types.String
    input_field :description, types.String
    input_field :title, !types.String
    input_field :user_id, !types.Int

    return_field :project, ProjectType

    resolve -> (inputs, _ctx) {
      GraphqlCrudOperations.create('project', inputs)
    }
  end

  Update = GraphQL::Relay::Mutation.define do
    name 'UpdateProject'
    input_field :lead_image, types.String
    input_field :description, types.String
    input_field :title, types.String
    input_field :user_id, types.Int

    input_field :id, !types.ID

    return_field :project, ProjectType

    resolve -> (inputs, ctx) {
      GraphqlCrudOperations.update('project', inputs, ctx)
    }
  end

  Destroy = GraphQL::Relay::Mutation.define do
    name "DestroyProject"

    input_field :id, !types.ID

    resolve -> (inputs, ctx) {
      GraphqlCrudOperations.destroy(inputs, ctx)
    }
  end
end
