module FlagMutations
  create_fields = {
    flag: '!str',
    annotated_id: 'str',
    annotated_type: 'str'
  }

  update_fields = {
    flag: 'str',
    annotated_id: 'str',
    annotated_type: 'str'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('flag', create_fields, update_fields, ['project_media', 'source'])
end
