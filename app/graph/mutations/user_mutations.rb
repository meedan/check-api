module UserMutations
  fields = {
    profile_image: 'str',
    current_team_id: 'int',
  }

  create_fields = fields.merge({
    email: '!str',
    login: '!str',
    name: '!str',
    password: '!str',
    password_confirmation: '!str'
  });

  update_fields = fields.merge({
    email: 'str',
    name: 'str',
    current_project_id: 'int',
    password: 'str',
    password_confirmation: 'str',
    send_email_notifications: 'bool',
    send_successful_login_notifications: 'bool',
    send_failed_login_notifications: 'bool',
    accept_terms: 'bool'
  });

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('user', create_fields, update_fields)
end
