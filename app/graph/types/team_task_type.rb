TeamTaskType = GraphqlCrudOperations.define_default_type do
  name 'TeamTask'
  description 'A Task template that is applied to items of a Team.'

  interfaces [NodeIdentification.interface]

  field :dbid, types.Int, 'Database id of this record'
  field :label, types.String
  field :description, types.String
  field :options, JsonStringType
  field :project_ids, JsonStringType # TODO Why not an array of Int?
  field :required, types.Boolean
  field :team_id, types.Int
  field :team, TeamType
  field :json_schema, types.String # TODO Convert to JsonStringType?

  field :type do
    type types.String

    resolve -> (task, _args, _ctx) {
      task.task_type
    }
  end
end
