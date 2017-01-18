module ProjectMutations
  create_fields = {
    lead_image: 'str',
    description: 'str',
    title: '!str',
    team_id: 'int'
  }

  update_fields = {
    lead_image: 'str',
    description: 'str',
    title: 'str',
    set_slack_channel: 'str',
    information: 'str',
    id: '!id'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('project', create_fields, update_fields, ['team'])
end
