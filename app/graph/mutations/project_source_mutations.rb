module ProjectSourceMutations

  Create = GraphQL::Relay::Mutation.define do
    name 'CreateProjectSource'
    input_field :source_id, !types.Int
    input_field :project_id, !types.Int

    return_field :project_source, ProjectSourceType

    resolve -> (inputs, _ctx) {
      GraphqlCrudOperations.create('project_source', inputs)
    }
  end

  Update = GraphQL::Relay::Mutation.define do
    name 'UpdateProjectSource'
    input_field :source_id, types.Int
    input_field :project_id, types.Int

    input_field :id, !types.ID

    return_field :project_source, ProjectSourceType

    resolve -> (inputs, ctx) {
      GraphqlCrudOperations.update('project_source', inputs, ctx)
    }
  end

  Destroy = GraphQL::Relay::Mutation.define do
    name "DestroyProjectSource"

    input_field :id, !types.ID

    resolve -> (inputs, ctx) {
      GraphqlCrudOperations.destroy(inputs, ctx)
    }
  end
end
