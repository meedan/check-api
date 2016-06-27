module TeamMutations
  create_fields = {
    archived: types.Boolean,
    logo: types.String,
    name: !types.String
  }

  update_fields = {
    archived: types.Boolean,
    logo: types.String,
    name: types.String,
    id: !types.ID
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('team', create_fields, update_fields)
end
