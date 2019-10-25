module TagMutations
  create_fields = {
    tag: '!str',
    fragment: 'str',
    annotated_id: 'str',
    annotated_type: 'str'
  }

  update_fields = {
    tag: 'str',
    fragment: 'str',
    annotated_id: 'str',
    annotated_type: 'str'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('tag', create_fields, update_fields, ['source', 'project_media', 'project_source', 'team'])
end
