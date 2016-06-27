module UserMutations
  create_fields = {
    email: '!str',
    profile_image: 'str',
    login: '!str',
    name: '!str'
  }

  update_fields = {
    email: 'str',
    profile_image: 'str',
    login: 'str',
    name: 'str',
    id: '!id'
  }
  
  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('user', create_fields, update_fields)
end
