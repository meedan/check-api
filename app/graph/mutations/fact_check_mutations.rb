module FactCheckMutations
  create_fields = {
    title: '!str',
    summary: '!str',
    url: 'str',
    language: 'str',
    claim_description_id: '!int',
  }

  update_fields = {
    title: 'str',
    summary: 'str',
    url: 'str',
    language: 'str'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('fact_check', create_fields, update_fields, ['claim_description'])
end
