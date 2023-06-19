module FeedTeamMutations
  create_fields = {}

  update_fields = {
    saved_search_id: 'int',
    requests_filters: 'json',
    shared: 'bool',
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('feed_team', create_fields, update_fields, ['feed'])
end
