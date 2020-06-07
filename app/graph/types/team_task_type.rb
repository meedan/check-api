TeamTaskType = GraphqlCrudOperations.define_default_type do
  name 'TeamTask'
  description 'A task template that is applied to items of a team.'

  interfaces [NodeIdentification.interface]

  field :label, types.String, 'Label'
  field :description, types.String, 'Description'
  field :project_ids, JsonStringType, 'Projects associated with this team task (database ids)' # TODO Convert to [types.Int]
  field :team_id, types.Int, 'Team associated with this team task (database id)'
  field :team, TeamType, 'Team associated with this team task'
  field :options, JsonStringType, 'Task options'
  field :json_schema, types.String, 'JSON Schema for task options' # TODO Convert to JsonStringType and rename to 'options_schema'

  field :type, types.String, 'Task type' do # TODO Convert to enum and document types in doc
    resolve -> (task, _args, _ctx) {
      task.task_type
    }
  end

  field :dbid, types.Int, 'Database id of this record'
end
