module MediaMutations
  create_fields = {
    url: !types.String,
    account_id: !types.Int,
    project_id: !types.Int,
    user_id: !types.Int
  }
    
  update_fields = {
    url: types.String,
    account_id: types.Int,
    project_id: types.Int,
    user_id: types.Int,
    id: !types.ID
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('media', create_fields, update_fields)
end
