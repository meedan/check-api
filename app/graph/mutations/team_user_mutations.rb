module TeamUserMutations
  create_fields = {
    user_id: '!int',
    team_id: '!int'
  }

  update_fields = {
    user_id: 'int',
    team_id: 'int',
    id: '!id'
  }
  
  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('team_user', create_fields, update_fields)
end
