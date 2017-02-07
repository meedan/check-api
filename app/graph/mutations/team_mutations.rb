module TeamMutations
  create_fields = {
    archived: 'bool',
    private: 'bool',
    logo: 'str',
    name: '!str',
    slug: '!str',
    description: 'str',
    contact: 'str'
  }

  update_fields = {
    archived: 'bool',
    private: 'bool',
    logo: 'str',
    name: 'str',
    description: 'str',
    set_slack_notifications_enabled: 'str',
    set_slack_webhook: 'str',
    set_slack_channel: 'str',
    contact: 'str',
    id: '!id'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('team', create_fields, update_fields)
end
