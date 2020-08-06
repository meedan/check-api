module ProjectMediaMutations
  fields = {
    media_id: 'int',
    related_to_id: 'int'
  }

  create_fields = fields.merge({
    url: 'str',
    quote: 'str',
    quote_attributions: 'str',
    add_to_project_id: 'int',
    set_annotation: 'str',
    set_tasks_responses: 'json',
    media_type: 'str'
  })

  update_fields = fields.merge({
    refresh_media: 'int',
    archived: 'int',
    previous_project_id: 'int',
    metadata: 'str',
    read: 'bool'
  })

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('project_media', create_fields, update_fields, ['project', 'check_search_project', 'project_was', 'check_search_project_was', 'check_search_team', 'check_search_trash', 'relationships_target', 'relationships_source', 'related_to', 'team'])

  BulkUpdate = GraphqlCrudOperations.define_bulk_update(ProjectMedia, { archived: 'bool', previous_project_id: 'int' }, ['team', 'project', 'check_search_project', 'check_search_team', 'check_search_trash'])
end
