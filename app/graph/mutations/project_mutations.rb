module ProjectMutations

  Create = GraphQL::Relay::Mutation.define do
    name 'CreateProject'
    input_field :lead_image, types.String
    input_field :description, types.String
    input_field :title, !types.String
    input_field :user_id, !types.Int

    return_field :project, ProjectType

    resolve -> (inputs, _ctx) {
      attr = inputs.keys.inject({}) do |memo, key|
        memo[key] = inputs[key] unless key == "clientMutationId"
        memo
      end

      project = Project.create(attr)

      { project: project }
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
      project = NodeIdentification.object_from_id((inputs[:id]), ctx)
      attr = inputs.keys.inject({}) do |memo, key|
        memo[key] = inputs[key] unless key == "clientMutationId" || key == 'id'
        memo
      end

      project.update(attr)
      { project: project }
    }
  end

  Destroy = GraphQL::Relay::Mutation.define do
    name "DestroyProject"

    input_field :id, !types.ID

    resolve -> (inputs, ctx) {
      project = NodeIdentification.object_from_id((inputs[:id]), ctx)
      project.destroy
      { }
    }
  end
end
