module AccountMutations
  create_fields = {
    url: !types.String,
    source_id: !types.Int,
    user_id: !types.Int
  }

  update_fields = {
    url: types.String,
    source_id: types.Int,
    user_id: types.Int,
    id: !types.ID
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('account', create_fields, update_fields)
end
