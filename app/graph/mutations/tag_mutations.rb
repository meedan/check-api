module TagMutations
  MUTATION_TARGET = 'tag'.freeze
  PARENTS = [
    'source',
    'project_media',
    'team',
    { tag_text_object: TagText },
  ].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      # TODO: Extract these into annotation mutation module
      argument :fragment, String, required: false
      argument :annotated_id, String, required: false, camelize: false
      argument :annotated_type, String, required: false, camelize: false
    end
  end

  class Create < CreateMutation
    include SharedCreateAndUpdateFields

    argument :tag, String, required: true
  end

  class Update < UpdateMutation
    include SharedCreateAndUpdateFields

    argument :tag, String, required: false
  end

  class Destroy < DestroyMutation; end

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
