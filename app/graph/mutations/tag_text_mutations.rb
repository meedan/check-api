module TagTextMutations
  create_fields = {
    team_id: '!int',
    text: '!str'
  }

  update_fields = {
    text: 'str'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('tag_text', create_fields, update_fields, ['team'])
end
