module ProjectMutations
  create_fields = {
    lead_image: types.String,
    description: types.String,
    title: !types.String,
    user_id: !types.Int
  }

  update_fields = {
    lead_image: types.String,
    description: types.String,
    title: types.String,
    user_id: types.Int,
    id: !types.ID
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('project', create_fields, update_fields)
end
