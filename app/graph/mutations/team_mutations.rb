module TeamMutations
  create_fields = {
    archived: 'int',
    private: 'bool',
    name: '!str',
    slug: '!str',
    description: 'str'
  }

  update_fields = {
    archived: 'int',
    private: 'bool',
    name: 'str',
    description: 'str',
    slack_notifications_enabled: 'str',
    slack_webhook: 'str',
    add_auto_task: 'json',
    media_verification_statuses: 'json',
    set_team_tasks: 'json',
    rules: 'str',
    slack_notifications: 'str',
    remove_auto_task: 'str', # label
    empty_trash: 'int',
    report: 'json',
    language: 'str',
    languages: 'json',
    list_columns: 'json',
    tipline_inbox_filters: 'str',
    suggested_matches_filters: 'str',
    trends_filters: 'str',
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('team', create_fields, update_fields, ['check_search_team', 'check_search_trash', 'check_search_spam', 'check_search_unconfirmed', 'public_team'])
end
