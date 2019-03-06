module SourceMutations
  create_fields = {
    avatar: 'str',
    slogan: '!str',
    name: '!str',
    user_id: 'int'
  }

  update_fields = {
    avatar: 'str',
    slogan: 'str',
    name: 'str',
    refresh_accounts: 'int',
    user_id: 'int',
    lock_version: 'int'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('source', create_fields, update_fields)
end
