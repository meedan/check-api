module CommentMutations
  create_fields = {
    text: '!str',
    annotated_id: 'str',
    annotated_type: 'str'
  }

  update_fields = {
    text: 'str',
    annotated_id: 'str',
    annotated_type: 'str'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('comment', create_fields, update_fields, ['project_media', 'project_source', 'source', 'project', 'task', 'comment_version'])
end
