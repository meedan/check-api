module TagMutations
  create_fields = GraphqlCrudOperations.define_annotation_mutation_fields.merge({ tag: '!str' })
  update_fields = GraphqlCrudOperations.define_annotation_mutation_fields.merge({ tag: 'str' })

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('tag', create_fields, update_fields, ['source', 'project_media', 'team', 'tag_text_object'])
  BulkCreate = GraphqlCrudOperations.define_bulk_create(Tag, create_fields, ['team', 'check_search_team'])
end
