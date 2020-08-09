module DynamicMutations
  fields = GraphqlCrudOperations.define_annotation_mutation_fields

  create_fields = fields.merge({
    set_fields: '!str',
    annotation_type: '!str'
  })

  update_fields = fields.merge({
    set_fields: 'str',
    annotation_type: 'str', # TODO Can a mutation change the annotation_type?
    lock_version: 'int',
    assigned_to_ids: 'str',
    locked: 'bool'
  })

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('dynamic', create_fields, update_fields, ['project_media', 'source', 'project', 'task', 'version'])
end
