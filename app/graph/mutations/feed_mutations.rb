module FeedMutations
  fields = {
    description: 'str',
    tags: 'json',
    saved_search_id: 'int',
    published: 'bool',
    licenses: 'int',
  }

  create_fields = fields.merge({
    name: '!str',
  })

  update_fields = fields.merge({
    name: 'str',
  })

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('feed', create_fields, update_fields, ['team'])
end
