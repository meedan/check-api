module TaskMutations
  fields = {
    description: 'str',
    assigned_to_ids: 'str',
    json_schema: 'str'
  }

  create_fields = {
    label: '!str',
    type: '!str',
    jsonoptions: 'str',
    annotated_id: 'str',
    annotated_type: 'str'
  }.merge(fields)

  update_fields = {
    label: 'str',
    response: 'str',
    accept_suggestion: 'int',
    reject_suggestion: 'int'
  }.merge(fields)

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('task', create_fields, update_fields, ['project_media', 'source', 'project', 'first_response_version'])
end
