module ProjectMediaProjectMutations
  create_fields = {
    project_id: '!int',
    project_media_id: '!int'
  }

  update_fields = {}

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('project_media_project', create_fields, update_fields, ['project', 'check_search_project'])
end
