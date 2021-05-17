module SavedSearchMutations
  update_fields = {
    title: 'str',
    filters: 'json'
  }

  create_fields = update_fields.merge({
    title: '!str',
    team_id: '!int'
  })

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('saved_search', create_fields, update_fields, ['team'])
end
