TeamTaskType = GraphqlCrudOperations.define_default_type do
  name 'TeamTask'
  description 'A Task template that is applied to items of a Team.'

  interfaces [NodeIdentification.interface]

  field :label, types.String
  field :description, types.String
  field :options, JsonStringType
  field :project_ids, JsonStringType # TODO Why not an array of Int?
  field :required, types.Boolean # TODO Remove
  field :team_id, types.Int
  field :team, TeamType
  field :json_schema, types.String # TODO Convert to JsonStringType?

  field :type do # TODO Consider enum type https://graphql.org/learn/schema/#enumeration-types
    type types.String

    resolve -> (task, _args, _ctx) {
      task.task_type
    }
  end

  field :dbid, types.Int, 'Database id of this record'
end
