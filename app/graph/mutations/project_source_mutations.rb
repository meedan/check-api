module ProjectSourceMutations
  create_fields = {  
    source_id: '!int',
    project_id: '!int'
  }

  update_fields = {  
    source_id: 'int',
    project_id: 'int',
    id: '!id'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('project_source', create_fields, update_fields)
end
