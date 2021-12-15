module ProjectMutations
  create_fields = {
    description: 'str',
    title: '!str',
    team_id: 'int',
    project_group_id: 'int'
  }

  update_fields = {
    description: 'str',
    title: 'str',
    assigned_to_ids: 'str',
    assignment_message: 'str',
    project_group_id: 'int',
    previous_project_group_id: 'int',
    privacy: 'int',
    is_default: 'bool'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('project', create_fields, update_fields, ['team', 'check_search_team', 'project_group', 'project_group_was'])
end
