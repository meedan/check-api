module ProjectMutations
  create_fields = {
    lead_image: 'str',
    description: 'str',
    title: '!str',
  }

  update_fields = {
    lead_image: 'str',
    description: 'str',
    title: 'str',
    id: '!id'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('project', create_fields, update_fields, ['team'])
end
