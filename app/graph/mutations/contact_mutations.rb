module ContactMutations
  create_fields = {
    location: 'str',
    phone: 'str',
    web: 'str',
    team_id: 'int'
  }

  update_fields = {
    location: 'str',
    phone: 'str',
    web: 'str',
    team_id: 'int'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('contact', create_fields, update_fields)
end
