module  TagMutations
  create_fields = {
    tag: '!str',
    context_id: 'str',
    context_type: 'str',
    annotated_id: 'str',
    annotated_type: 'str'
  }
    
  update_fields = {
    tag: 'str',
    context_id: 'str',
    context_type: 'str',
    annotated_id: 'str',
    annotated_type: 'str',
    id: '!id'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('tag', create_fields, update_fields)
end
