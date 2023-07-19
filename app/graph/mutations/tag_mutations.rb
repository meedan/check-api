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

    include Mutations::Inclusions::AnnotationBehaviors
  end

  class Create < Mutations::CreateMutation
    include SharedCreateAndUpdateFields

    argument :tag, GraphQL::Types::String, required: true
  end

  class Update < Mutations::UpdateMutation
    include SharedCreateAndUpdateFields

    argument :tag, GraphQL::Types::String, required: false
  end

  class Destroy < Mutations::DestroyMutation; end

  class CreateTagsBulkInput < BaseInputObject
    include SharedCreateAndUpdateFields

    argument :tag, GraphQL::Types::String, required: true
  end

  module Bulk
    PARENTS = [
      'team',
      { check_search_team: CheckSearchType }
    ].freeze

    class Create < Mutations::BulkCreateMutation
      argument :inputs, [CreateTagsBulkInput, null: true], required: false

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
end
