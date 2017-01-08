module ProjectMediaMutations
  create_fields = {
    media_id: '!int',
    project_id: '!int'
  }

  update_fields = {
    media_id: 'int',
    project_id: 'int',
    embed: 'str',
    id: '!id'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('project_media', create_fields, update_fields)
end
