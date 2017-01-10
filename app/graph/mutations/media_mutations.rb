module MediaMutations
  create_fields = {
    url: 'str',
    account_id: 'int',
    project_id: 'int',
    user_id: 'int',
    quote: 'str'
  }

  update_fields = {
    url: 'str',
    account_id: 'int',
    project_id: 'int',
    user_id: 'int',
    quote: 'str',
    id: '!id'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('media', create_fields, update_fields, ['project'])
end
