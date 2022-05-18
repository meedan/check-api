module TaskMutations
  fields = {
    description: 'str',
    json_schema: 'str',
    order: 'int',
    fieldset: 'str'
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
    response: 'str'
  }.merge(fields)

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('task', create_fields, update_fields, ['project_media', 'source', 'project', 'version'])
end
