module ProjectMutations
  create_fields = {
    lead_image: '!str',
    description: '!str',
    title: '!str',
    user_id: 'int'
  }

  update_fields = {
    lead_image: 'str',
    description: 'str',
    title: 'str',
    user_id: 'int',
    id: '!id'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('project', create_fields, update_fields)
end
