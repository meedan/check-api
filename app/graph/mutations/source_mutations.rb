module SourceMutations
  create_fields = {
    avatar: 'str',
    slogan: '!str',
    name: '!str',
    user_id: 'int',
    add_to_project_media_id: 'int',
    urls: 'str',
    validate_primary_link_exist: 'bool'
  }

  update_fields = {
    avatar: 'str',
    slogan: 'str',
    name: 'str',
    refresh_accounts: 'int',
    user_id: 'int',
    add_to_project_media_id: 'int',
    lock_version: 'int'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('source', create_fields, update_fields, ['project_media'])
end
