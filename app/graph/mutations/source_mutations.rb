module SourceMutations
  create_fields = {  
    avatar: 'str',
    slogan: 'str',
    name: '!str'
  }

  update_fields = {
    avatar: 'str',
    slogan: 'str',
    name: 'str',
    id: '!id'
  }
  
  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('source', create_fields, update_fields)
end
