module VersionMutations
  create_fields = {
    item_type: 'str',
    item_id: 'str',
    event: 'str'
  }

  update_fields = {
    item_type: 'str',
    item_id: 'str',
    event: 'str',
    id: '!id'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('version', create_fields, update_fields)
end
