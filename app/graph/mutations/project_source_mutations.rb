module ProjectSourceMutations
  create_fields = {
    source_id: 'int',
    project_id: '!int',
    url: 'str',
    name: 'str'
  }

  update_fields = {
    source_id: 'int',
    project_id: 'int'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('project_source', create_fields, update_fields, ['project', 'check_search_team', 'check_search_project'])
end
