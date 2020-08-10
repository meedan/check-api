module ProjectMediaUserMutations
  fields = {
    project_media_id: '!int',
    user_id: 'int', # Fallback to current user if not set
    read: 'bool'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('project_media_user', fields, fields, ['project_media'])
end
