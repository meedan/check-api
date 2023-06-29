module FeedMutations
  fields = {
    description: 'str',
    tags: 'array_str',
    saved_search_id: 'int',
    published: 'bool',
    discoverable: 'bool',
  }

  create_fields = fields.merge({
    name: '!str',
    licenses: '!array_int',
  })

  update_fields = fields.merge({
    name: 'str',
  })

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('feed', create_fields, update_fields, ['team'])
end
