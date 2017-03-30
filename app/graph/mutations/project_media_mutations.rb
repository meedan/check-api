module ProjectMediaMutations
  create_fields = {
    media_id: 'int',
    project_id: '!int',
    url: 'str',
    quote: 'str',
    set_annotation: 'str'
  }

  update_fields = {
    media_id: 'int',
    project_id: 'int',
    previous_project_id: 'int',
    refresh_media: 'int',
    embed: 'str',
    id: '!id'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('project_media', create_fields, update_fields, ['project', 'project_was', 'check_search_team', 'check_search_project'])
end
