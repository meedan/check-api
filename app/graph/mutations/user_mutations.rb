module UserMutations
  create_fields = {
    email: '!str',
    profile_image: 'str',
    login: '!str',
    name: '!str',
    current_team_id: 'int',
    password: '!str',
    password_confirmation: '!str'
  }

  update_fields = {
    email: 'str',
    profile_image: 'str',
    name: 'str',
    current_team_id: 'int',
    password: 'str',
    password_confirmation: 'str',
    id: '!id'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('user', create_fields, update_fields)
end
