module ProjectMediaMutations
  fields = {
    media_id: 'int',
    project_id: 'int',
    related_to_id: 'int'
  }

  create_fields = fields.merge({
    url: 'str',
    quote: 'str',
    quote_attributions: 'str',
    set_annotation: 'str', # TODO Action should be a separate mutation
    set_tasks_responses: 'json', # TODO Action should be a separate mutation
    media_type: 'str'
  })

  update_fields = fields.merge({
    previous_project_id: 'int', # TODO Action should be a separate mutation
    copy_to_project_id: 'int', # TODO Action should be a separate mutation
    add_to_project_id: 'int', # TODO Action should be a separate mutation
    remove_from_project_id: 'int', # TODO Action should be a separate mutation
    refresh_media: 'int', # TODO Action should be a separate mutation
    archived: 'int',
    metadata: 'json'
  })

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('project_media', create_fields, update_fields, ['project', 'project_was', 'check_search_team', 'check_search_trash', 'check_search_project', 'check_search_project_was', 'relationships_target', 'relationships_source', 'related_to'])
end
