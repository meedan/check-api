module AccountMutations
  create_fields = {
    url: '!str',
    source_id: '!int',
    user_id: '!int'
  }

  update_fields = {
    url: 'str',
    source_id: 'int',
    user_id: 'int',
    id: '!id'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('account', create_fields, update_fields)
end
