module CommentMutations
  create_fields = {
    text: '!str',
    context_id: 'str',
    context_type: 'str',
    annotated_id: 'str',
    annotated_type: 'str'
  }

  update_fields = {
    text: 'str',
    context_id: 'str',
    context_type: 'str',
    annotated_id: 'str',
    annotated_type: 'str',
    id: '!id'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('comment', create_fields, update_fields, ['project_media', 'source', 'project'])
end
