module ClaimDescriptionMutations
  create_fields = {
    description: '!str',
    project_media_id: '!int',
  }

  update_fields = {
    description: '!str',
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('claim_description', create_fields, update_fields, ['project_media'])
end
