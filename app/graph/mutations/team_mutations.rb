module TeamMutations
  fields = {
    archived: 'int',
    private: 'bool',
    description: 'str'
  }

  create_fields = fields.merge({
    name: '!str',
    slug: '!str'
  })

  update_fields = fields.merge({
    name: 'str',
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
    outgoing_urls_utm_code: 'str',
    shorten_outgoing_urls: 'bool'
  })

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('team', create_fields, update_fields, ['check_search_team', 'check_search_trash', 'check_search_spam', 'check_search_unconfirmed', 'public_team'])
end
