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

  settings_fields = {
    slack_notifications_enabled: 'str',
    slack_webhook: 'str',
    slack_notifications: 'str',
    language: 'str',
    languages: 'json',
    list_columns: 'json',
    tipline_inbox_filters: 'str',
    suggested_matches_filters: 'str',
    outgoing_urls_utm_code: 'str',
    shorten_outgoing_urls: 'bool'
  }

  update_fields = fields.merge(settings_fields).merge({
    name: 'str',
    add_auto_task: 'json',
    media_verification_statuses: 'json',
    set_team_tasks: 'json',
    rules: 'str',
    remove_auto_task: 'str', # label
    empty_trash: 'int',
    report: 'json',
  })

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('team', create_fields, update_fields, ['check_search_team', 'check_search_trash', 'check_search_spam', 'check_search_unconfirmed', 'public_team'])
end
