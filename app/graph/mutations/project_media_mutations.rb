module ProjectMediaMutations
  create_fields = {
    media_id: 'int',
    project_id: '!int',
    media_type: 'str',
    url: 'str',
    quote: 'str',
    quote_attributions: 'str',
    set_annotation: 'str',
    set_tasks_responses: 'json',
    related_to_id: 'int'
  }

  update_fields = {
    media_id: 'int',
    project_id: 'int',
    previous_project_id: 'int',
    copy_to_project_id: 'int',
    refresh_media: 'int',
    update_mt: 'int',
    archived: 'int',
    metadata: 'str',
    related_to_id: 'int'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('project_media', create_fields, update_fields, ['project', 'project_was', 'check_search_team', 'check_search_trash', 'check_search_project', 'check_search_project_was', 'relationships_target', 'relationships_source', 'related_to'])
end
