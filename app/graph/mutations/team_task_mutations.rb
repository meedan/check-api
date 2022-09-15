module TeamTaskMutations
  fields = {
    label: '!str',
    task_type: 'str',
    description: 'str',
    json_options: 'str',
    json_schema: 'str',
    keep_completed_tasks: 'bool',
    order: 'int',
    fieldset: 'str',
    associated_type: 'str',
    show_in_browser_extension: 'bool',
    conditional_info: 'str',
    required: 'bool',
    options_diff: 'json',
  }

  create_fields = fields.merge({
    team_id: '!int'
  })

  update_fields = fields

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('team_task', create_fields, update_fields, ['team'])
end
