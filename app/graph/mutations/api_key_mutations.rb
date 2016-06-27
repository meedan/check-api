module ApiKeyMutations
  create_fields = { application: !types.String }

  update_fields = {  
    application: types.String,
    expire_at: types.String,
    access_token: types.String,
    id: !types.ID
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('api_key', create_fields, update_fields)
end
