module TagMutations
  MUTATION_TARGET = 'tag'.freeze
  PARENTS = [
    'source',
    'project_media',
    'team',
    { tag_text_object: TagTextType },
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

  class CreateTagMutationsBulkInput < BaseInputObject
    argument :fragment, String, required: false
    argument :annotated_id, String, required: false, camelize: false
    argument :annotated_type, String, required: false, camelize: false
    argument :tag, String, required: true
  end

  class BulkCreate < BaseMutation
    include SharedCreateAndUpdateFields

    graphql_name "CreateTagMutations"

    argument :inputs, [CreateTagMutationsBulkInput], required: false

    parents = [
      'team',
      { check_search_team: CheckSearchType }
    ].freeze
    set_parent_returns(self, parents)

    def resolve(**input)
      if input[:inputs].size > 10_000
        raise I18n.t(:bulk_operation_limit_error, limit: 10_000)
      end

      ability = context[:ability] || Ability.new
      if ability.can?(:bulk_create, Tag.new(team: Team.current))
        Tag.bulk_create(input[:inputs], Team.current)
      else
        raise CheckPermissions::AccessDenied, I18n.t(:permission_error)
      end
    end
  end
end
