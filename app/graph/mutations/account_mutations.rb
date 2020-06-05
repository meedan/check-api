module AccountMutations

  # TODO Refresh action should be a separate mutation
  update_fields = {
    refresh_account: 'int'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('account', {}, update_fields)
end
