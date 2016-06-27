module SourceMutations
  create_fields = {  
    avatar: types.String,
    slogan: types.String,
    name: !types.String
  }

  update_fields = {
    avatar: types.String,
    slogan: types.String,
    name: types.String,
    id: !types.ID
  }
  
  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('source', create_fields, update_fields)
end
