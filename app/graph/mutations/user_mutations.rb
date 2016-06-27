module UserMutations
  create_fields = {
    email: !types.String,
    profile_image: types.String,
    login: !types.String,
    name: !types.String
  }

  update_fields = {
    email: types.String,
    profile_image: types.String,
    login: types.String,
    name: types.String,
    id: !types.ID
  }
  
  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('user', create_fields, update_fields)
end
