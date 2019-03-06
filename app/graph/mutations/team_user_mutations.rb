module TeamUserMutations
  create_fields = {
    user_id: '!int',
    team_id: '!int',
    status: '!str',
    role: 'str'
  }

  update_fields = {
    user_id: 'int',
    team_id: 'int',
    status: 'str',
    role: 'str'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('team_user', create_fields, update_fields, ['user','team'])
end
