module ProjectSourceMutations
  create_fields = {  
    source_id: !types.Int,
    project_id: !types.Int
  }

  update_fields = {  
    source_id: types.Int,
    project_id: types.Int,
    id: !types.ID
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('project_source', create_fields, update_fields)
end
