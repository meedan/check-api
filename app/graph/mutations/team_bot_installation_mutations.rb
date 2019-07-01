module TeamBotInstallationMutations
  create_fields = {
    team_id: '!int',
    user_id: '!int'
  }

  update_fields = {
    json_settings: 'str'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('team_bot_installation', create_fields, update_fields, ['team', 'bot_user'])
end
