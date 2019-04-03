module DynamicMutations
  fields = {
    annotated_id: 'str',
    annotated_type: 'str',
    set_attribution: 'str'
  }

  create_fields = fields.merge({
    set_fields: '!str',
    annotation_type: '!str'
  })

  update_fields = fields.merge({
    set_fields: 'str',
    annotation_type: 'str',
    lock_version: 'int',
    assigned_to_ids: 'str',
    locked: 'bool'
  })

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('dynamic', create_fields, update_fields, ['project_media', 'project_source', 'source', 'project', 'task'])
end
