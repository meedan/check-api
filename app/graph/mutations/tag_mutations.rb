module TagMutations
  # create_fields = { fragment: "str", annotated_id: "str", annotated_type: "str" }.merge({ tag: '!str' })
  create_fields = GraphqlCrudOperations.define_annotation_mutation_fields.merge({ tag: '!str' })
  # update_fields = { fragment: "str", annotated_id: "str", annotated_type: "str" }.merge({ tag: 'str' })
  update_fields = GraphqlCrudOperations.define_annotation_mutation_fields.merge({ tag: 'str' })

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('tag', create_fields, update_fields, ['source', 'project_media', 'team', 'tag_text_object'])

  CreateTagMutationsBulkInput = GraphQL::InputObjectType.define do
    name "CreateTagMutationsBulkInput"

    argument :fragment, types.String
    argument :annotated_id, types.String
    argument :annotated_type, types.String
    argument :tag, !types.String
  end

  # BulkCreate = GraphqlCrudOperations.define_bulk_create(Tag, create_fields, ['team', 'check_search_team'])
  BulkCreate = GraphQL::Relay::Mutation.define do
    name "CreateTagMutations"

    input_field :inputs, types[CreateTagMutationsBulkInput]

    GraphqlCrudOperations
      .define_parent_returns(['team', 'check_search_team'])
      .each do |field_name, field_class|
        return_field(field_name, field_class)
      end

    resolve ->(_root, input, ctx) {
              if input[:inputs].size > 10_000
                raise I18n.t(:bulk_operation_limit_error, limit: 10_000)
              end

              ability = ctx[:ability] || Ability.new
              if ability.can?(:bulk_create, Tag.new(team: Team.current))
                Tag.bulk_create(input["inputs"], Team.current)
              else
                raise CheckPermissions::AccessDenied,
                      I18n.t(:permission_error)
              end
            }
  end
end
