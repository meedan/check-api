module FlagMutations
  create_fields = {
    flag: '!str',
    context_id: 'str',
    context_type: 'str',
    annotated_id: 'str',
    annotated_type: 'str'
  }
    
  update_fields = {
    flag: 'str',
    context_id: 'str',
    context_type: 'str',
    annotated_id: 'str',
    annotated_type: 'str',
    id: '!id'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('flag', create_fields, update_fields, ['media', 'source'])
end
