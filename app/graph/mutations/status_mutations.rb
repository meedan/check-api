module StatusMutations
  create_fields = {
    status: '!str',
    annotated_id: 'str',
    annotated_type: 'str'
  }

  update_fields = {
    status: 'str',
    annotated_id: 'str',
    annotated_type: 'str',
    assigned_to_id: 'int',
    id: '!id'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('status', create_fields, update_fields, ['project_media', 'source'])
end
