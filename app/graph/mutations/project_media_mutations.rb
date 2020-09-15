module ProjectMediaMutations
  fields = {
    media_id: 'int',
    related_to_id: 'int'
  }

  create_fields = fields.merge({
    url: 'str',
    quote: 'str',
    quote_attributions: 'str',
    add_to_project_id: 'int',
    set_annotation: 'str',
    set_tasks_responses: 'json',
    media_type: 'str'
  })

  update_fields = fields.merge({
    refresh_media: 'int',
    archived: 'int',
    previous_project_id: 'int',
    read: 'bool'
  })

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('project_media', create_fields, update_fields, ['project', 'check_search_project', 'project_was', 'check_search_project_was', 'check_search_team', 'check_search_trash', 'relationships_target', 'relationships_source', 'related_to', 'team'])

  BulkUpdate = GraphqlCrudOperations.define_bulk_update(ProjectMedia, { archived: 'bool', previous_project_id: 'int' }, ['team', 'project', 'check_search_project', 'check_search_team', 'check_search_trash'])

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
end
