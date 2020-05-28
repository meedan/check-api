module TagMutations
  create_fields = GraphqlCrudOperations.define_annotation_mutation_fields.merge({ tag: '!str' })
  update_fields = GraphqlCrudOperations.define_annotation_mutation_fields.merge({ tag: 'str' })

  Create, Update, Destroy, BulkCreate = GraphqlCrudOperations.define_crud_operations('tag', create_fields, update_fields, ['source', 'project_media', 'project_source', 'team'], true)
end
