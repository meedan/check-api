module AccountSourceMutations
  create_fields = {
    account_id: 'int',
    source_id: '!int',
    url: 'str'
  }

  update_fields = {
    account_id: 'int',
    source_id: 'int',
    id: '!id'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('project_source', create_fields, update_fields)
end
