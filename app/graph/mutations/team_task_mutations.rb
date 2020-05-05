module TeamTaskMutations
  fields = {
    label: '!str',
    task_type: 'str',
    description: 'str',
    json_options: 'str',
    json_project_ids: 'str',
    json_schema: 'str',
    keep_completed_tasks: 'bool'
  }

  create_fields = fields.merge({
    team_id: '!int'
  })

  update_fields = fields

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('team_task', create_fields, update_fields, ['team'])
end
