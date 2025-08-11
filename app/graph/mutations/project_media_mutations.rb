module ProjectMediaMutations
  MUTATION_TARGET = 'project_media'.freeze
  PARENTS = [
    'team',
    { check_search_team: CheckSearchType },
    { check_search_trash: CheckSearchType },
    { check_search_spam: CheckSearchType },
    { check_search_unconfirmed: CheckSearchType },
    { related_to: ProjectMediaType },
  ].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      argument :media_id, GraphQL::Types::Int, required: false, camelize: false
      argument :related_to_id, GraphQL::Types::Int, required: false, camelize: false
      argument :project_id, GraphQL::Types::Int, required: false, camelize: false, deprecation_reason: "Deprecate folder feature."

      field :affected_id, GraphQL::Types::ID, null: true
    end
  end

  class Create < Mutations::CreateMutation
    include SharedCreateAndUpdateFields

    argument :url, GraphQL::Types::String, required: false
    argument :quote, GraphQL::Types::String, required: false
    argument :quote_attributions, GraphQL::Types::String, required: false, camelize: false
    argument :media_id, GraphQL::Types::Int, required: false, camelize: false
    argument :team_id, GraphQL::Types::Int, required: false, camelize: false
    argument :channel, JsonStringType, required: false
    argument :media_type, GraphQL::Types::String, required: false, camelize: false

    # Set fields
    argument :set_annotation, GraphQL::Types::String, required: false, camelize: false
    argument :set_claim_description, GraphQL::Types::String, required: false, camelize: false
    argument :set_fact_check, JsonStringType, required: false, camelize: false
    argument :set_tasks_responses, JsonStringType, required: false, camelize: false
    argument :set_tags, JsonStringType, required: false, camelize: false
    argument :set_title, GraphQL::Types::String, required: false, camelize: false
    argument :set_status, GraphQL::Types::String, required: false, camelize: false # Status identifier (for example, "in_progress")
    argument :set_original_claim, GraphQL::Types::String, required: false, camelize: false
  end

  class Update < Mutations::UpdateMutation
    include SharedCreateAndUpdateFields

    argument :refresh_media, GraphQL::Types::Int, required: false, camelize: false
    argument :archived, GraphQL::Types::Int, required: false
    argument :source_id, GraphQL::Types::Int, required: false, camelize: false
    argument :read, GraphQL::Types::Boolean, required: false
    argument :custom_title, GraphQL::Types::String, required: false, camelize: false
    argument :title_field, GraphQL::Types::String, required: false, camelize: false
  end

  module Bulk
    PARENTS = [
      'team',
      { check_search_team: CheckSearchType },
      { check_search_trash: CheckSearchType },
      { check_search_spam: CheckSearchType },
      { check_search_unconfirmed: CheckSearchType },
    ].freeze

    class Update < Mutations::BulkUpdateMutation
      argument :action, GraphQL::Types::String, required: true
      argument :params, GraphQL::Types::String, required: false
    end

    class MarkRead < Mutations::BaseMutation
      define_shared_bulk_behavior(:mark_read, self, MUTATION_TARGET, GraphqlCrudOperations.hashify_parent_types(PARENTS))

      description "Allow multiple items to be marked as read or unread."

      graphql_name "BulkProjectMediaMarkRead"

      field :updated_objects, [ProjectMediaType, null: true], null: true, camelize: false

      argument :read, GraphQL::Types::Boolean, "A boolean value for ProjectMedia read value", required: true, camelize: false
    end
  end
end
