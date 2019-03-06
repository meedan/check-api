module AccountSourceMutations
  create_fields = {
    account_id: 'int',
    source_id: '!int',
    url: 'str'
  }

  update_fields = {
    account_id: 'int',
    source_id: 'int'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('account_source', create_fields, update_fields, ['source'])
end
