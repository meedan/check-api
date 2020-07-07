module ProjectMediaMutations
  fields = {
    media_id: 'int',
    add_to_project_id: 'int',
    related_to_id: 'int'
  }

  create_fields = fields.merge({
    url: 'str',
    quote: 'str',
    quote_attributions: 'str',
    set_annotation: 'str',
    set_tasks_responses: 'json',
    media_type: 'str'
  })

  update_fields = fields.merge({
    refresh_media: 'int',
    archived: 'int',
    metadata: 'str'
  })

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('project_media', create_fields, update_fields, ['check_search_team', 'check_search_trash', 'relationships_target', 'relationships_source', 'related_to', 'team'])
end
