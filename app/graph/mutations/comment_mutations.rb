module CommentMutations
  create_fields = GraphqlCrudOperations.define_annotation_mutation_fields.merge({ text: '!str' })
  update_fields = GraphqlCrudOperations.define_annotation_mutation_fields.merge({ text: 'str' })

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('comment', create_fields, update_fields, ['project_media', 'source', 'project', 'task', 'comment_version'])
end
