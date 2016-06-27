module TeamUserMutations
  create_fields = {
    user_id: !types.Int,
    team_id: !types.Int
  }

  update_fields = {
    user_id: types.Int,
    team_id: types.Int,
    id: !types.ID
  }
  
  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('team_user', create_fields, update_fields)
end
