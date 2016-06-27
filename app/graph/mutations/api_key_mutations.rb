module ApiKeyMutations
  create_fields = { application: '!str' }

  update_fields = {  
    application: 'str',
    expire_at: 'str',
    access_token: 'str',
    id: '!id'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('api_key', create_fields, update_fields)
end
