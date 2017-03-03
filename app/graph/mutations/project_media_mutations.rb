module ProjectMediaMutations
  create_fields = {
    media_id: 'int',
    project_id: '!int',
    url: 'str',
    quote: 'str'
  }

  update_fields = {
    media_id: 'int',
    project_id: 'int',
    previous_project_id: 'int',
    embed: 'str',
    id: '!id'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('project_media', create_fields, update_fields, ['project', 'project_was'])
end
