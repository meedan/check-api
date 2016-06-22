module ProjectSourceMutations

  Create = GraphQL::Relay::Mutation.define do
    name 'CreateProjectSource'
    input_field :source_id, !types.Int
    input_field :project_id, !types.Int

    return_field :project_source, ProjectSourceType

    resolve -> (inputs, ctx) {
      root = RootLevel::STATIC
      attr = inputs.keys.inject({}) do |memo, key|
        memo[key] = inputs[key] unless key == "clientMutationId"
        memo
      end

      project_source = ProjectSource.create(attr)

      { project_source: project_source }
    }
  end

  Update = GraphQL::Relay::Mutation.define do
    name 'UpdateProjectSource'
    input_field :source_id, types.Int
    input_field :project_id, types.Int

    input_field :id, !types.ID

    return_field :project_source, ProjectSourceType

    resolve -> (inputs, ctx) {
      project_source = NodeIdentification.object_from_id((inputs[:id]), ctx)
      attr = inputs.keys.inject({}) do |memo, key|
        memo[key] = inputs[key] unless key == "clientMutationId" || key == 'id'
        memo
      end

      project_source.update(attr)
      { project_source: project_source }
    }
  end

  Destroy = GraphQL::Relay::Mutation.define do
    name "DestroyProjectSource"

    input_field :id, !types.ID

    resolve -> (inputs, ctx) {
      project_source = NodeIdentification.object_from_id((inputs[:id]), ctx)
      project_source.destroy
      { }
    }
  end
end
