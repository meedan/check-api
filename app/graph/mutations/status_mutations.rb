module StatusMutations
  create_fields = {
    status: '!str',
    context_id: 'str',
    context_type: 'str',
    annotated_id: 'str',
    annotated_type: 'str'
  }
    
  update_fields = {
    status: 'str',
    context_id: 'str',
    context_type: 'str',
    annotated_id: 'str',
    annotated_type: 'str',
    id: '!id'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('status', create_fields, update_fields, ['media', 'source'])
end
