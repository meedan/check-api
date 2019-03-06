module TeamBotInstallationMutations
  create_fields = {
    team_id: '!int',
    team_bot_id: '!int'
  }

  update_fields = {
    json_settings: 'str'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('team_bot_installation', create_fields, update_fields, ['team', 'team_bot'])
end
