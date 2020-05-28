module FlagMutations
  create_fields = GraphqlCrudOperations.define_annotation_mutation_fields.merge({ flag: '!str' })
  update_fields = GraphqlCrudOperations.define_annotation_mutation_fields.merge({ flag: 'str' })

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('flag', create_fields, update_fields, ['project_media', 'source'])
end
