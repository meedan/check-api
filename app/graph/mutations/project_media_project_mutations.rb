module ProjectMediaProjectMutations
  create_fields = {
    project_id: '!int',
    project_media_id: '!int'
  }

  update_fields = {
    project_id: '!int',
    previous_project_id: 'int',
    project_media_id: 'int'
  }

  destroy_fields = {
    previous_project_id: 'int'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('project_media_project', create_fields, update_fields, ['project', 'project_was', 'check_search_team', 'check_search_trash', 'check_search_project', 'check_search_project_was', 'team', 'project_media'])
  BulkCreate = GraphqlCrudOperations.define_bulk_create(ProjectMediaProject, create_fields, ['team', 'project'])
  BulkUpdate = GraphqlCrudOperations.define_bulk_update(ProjectMediaProject, update_fields, ['team', 'project', 'project_was', 'check_search_project_was'])
  BulkDestroy = GraphqlCrudOperations.define_bulk_destroy(ProjectMediaProject, destroy_fields, ['team', 'project_was', 'check_search_project_was'])
end
