module ProjectGroupMutations
  update_fields = {
    title: 'str',
    description: 'str'
  }

  create_fields = update_fields.merge({
    title: '!str',
    team_id: '!int'
  })

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('project_group', create_fields, update_fields, ['team'])
end
