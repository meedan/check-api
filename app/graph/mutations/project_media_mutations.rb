module ProjectMediaMutations
  fields = {
    media_id: 'int',
    related_to_id: 'int'
  }

  set_fields = {
    set_annotation: 'str',
    set_claim_description: 'str',
    set_fact_check: 'json',
    set_tasks_responses: 'json',
    set_tags: 'json'
  }

  create_fields = fields.merge({
    url: 'str',
    quote: 'str',
    quote_attributions: 'str',
    project_id: 'int',
    media_id: 'int',
    team_id: 'int',
    channel: 'int',
    media_type: 'str'
  }).merge(set_fields)

  update_fields = fields.merge({
    refresh_media: 'int',
    archived: 'int',
    previous_project_id: 'int',
    project_id: 'int',
    source_id: 'int',
    read: 'bool'
  })

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('project_media', create_fields, update_fields, ['project', 'check_search_project', 'project_was', 'check_search_project_was', 'check_search_team', 'check_search_trash', 'check_search_unconfirmed', 'related_to', 'team', 'project_group'])

  Replace = GraphQL::Relay::Mutation.define do
    name 'ReplaceProjectMedia'

    input_field :project_media_to_be_replaced_id, !types.ID
    input_field :new_project_media_id, !types.ID

    return_field :old_project_media_deleted_id, types.ID
    return_field :new_project_media, ProjectMediaType

    resolve -> (_root, inputs, ctx) {
      old = GraphqlCrudOperations.object_from_id_if_can(inputs['project_media_to_be_replaced_id'], ctx['ability'])
      new = GraphqlCrudOperations.object_from_id_if_can(inputs['new_project_media_id'], ctx['ability'])
      old.replace_by(new)
      { old_project_media_deleted_id: old.graphql_id, new_project_media: new }
    }
  end

  BulkUpdate = GraphqlCrudOperations.define_bulk_update(ProjectMedia, { action: '!str', params: 'str' }, ['team', 'project', 'check_search_project', 'project_was', 'check_search_project_was', 'check_search_team', 'check_search_trash', 'check_search_unconfirmed', 'project_group'])
end
