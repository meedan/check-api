module TaskMutations
  create_fields = {
    label: '!str',
    type: '!str',
    description: 'str',
    jsonoptions: 'str',
    annotated_id: 'str',
    annotated_type: 'str'
  }

  update_fields = {
    label: 'str',
    type: 'str',
    description: 'str',
    jsonoptions: 'str',
    annotated_id: 'str',
    annotated_type: 'str',
    id: '!id'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('task', create_fields, update_fields, ['project_media', 'source', 'project'])
end
