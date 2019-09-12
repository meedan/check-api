TeamTaskType = GraphqlCrudOperations.define_default_type do
  name 'TeamTask'
  description 'Team task type'

  interfaces [NodeIdentification.interface]

  field :dbid, types.Int
  field :label, types.String
  field :description, types.String
  field :options, JsonStringType
  field :project_ids, JsonStringType
  field :required, types.Boolean
  field :team_id, types.Int
  field :team, TeamType
  field :json_schema, types.String

  field :type do
    type types.String

    resolve -> (task, _args, _ctx) {
      task.task_type
    }
  end
end
