module TaskMutations
  create_fields = {
    label: '!str',
    type: '!str',
    required: 'bool',
    assigned_to_ids: 'str',
    description: 'str',
    jsonoptions: 'str',
    annotated_id: 'str',
    annotated_type: 'str'
  }

  update_fields = {
    label: 'str',
    required: 'bool',
    description: 'str',
    response: 'str',
    status: 'str',
    accept_suggestion: 'int',
    reject_suggestion: 'int',
    assigned_to_ids: 'str'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('task', create_fields, update_fields, ['project_media', 'source', 'project', 'first_response_version'])
end
