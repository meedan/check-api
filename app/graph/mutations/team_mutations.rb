module TeamMutations
  create_fields = {
    archived: 'bool',
    private: 'bool',
    name: '!str',
    slug: '!str',
    description: 'str',
    contact: 'str'
  }

  update_fields = {
    archived: 'bool',
    private: 'bool',
    name: 'str',
    description: 'str',
    slack_notifications_enabled: 'str',
    slack_webhook: 'str',
    slack_channel: 'str',
    add_auto_task: 'json',
    add_media_verification_statuses: 'json',
    set_team_tasks: 'json',
    rules: 'str',
    disclaimer: 'str',
    introduction: 'str',
    use_disclaimer: 'bool',
    use_introduction: 'bool',
    remove_auto_task: 'str', # label
    contact: 'str',
    empty_trash: 'int'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('team', create_fields, update_fields, ['check_search_team', 'check_search_trash', 'public_team'])
end
