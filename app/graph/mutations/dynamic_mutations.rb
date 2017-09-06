module DynamicMutations
  create_fields = {
    set_fields: '!str',
    annotation_type: '!str',
    annotated_id: 'str',
    annotated_type: 'str'
  }

  update_fields = {
    set_fields: 'str',
    annotation_type: 'str',
    annotated_id: 'str',
    annotated_type: 'str',
    id: '!id'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('dynamic', create_fields, update_fields, ['project_media', 'project_source', 'source', 'project'])
end
