module ProjectMediaProjectMutations
  create_fields = {
    project_id: '!int',
    project_media_id: '!int'
  }

  update_fields = {
    project_id: 'int',
    previous_project_id: 'int'
  }

  Create, Update, Destroy, BulkCreate = GraphqlCrudOperations.define_crud_operations('project_media_project', create_fields, update_fields, ['project', 'project_was', 'check_search_team', 'check_search_trash', 'check_search_project', 'check_search_project_was', 'team'], true)
end
