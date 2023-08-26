module ProjectMediaMutations
  MUTATION_TARGET = 'project_media'.freeze
  PARENTS = [
    'project',
    'team',
    'project_group',
    { project_was: ProjectType },
    { check_search_project: CheckSearchType },
    { check_search_project_was: CheckSearchType },
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

      field :affected_id, GraphQL::Types::ID, null: true
    end
  end

  class Create < Mutations::CreateMutation
    include SharedCreateAndUpdateFields

    argument :url, GraphQL::Types::String, required: false
    argument :quote, GraphQL::Types::String, required: false
    argument :quote_attributions, GraphQL::Types::String, required: false, camelize: false
    argument :project_id, GraphQL::Types::Int, required: false, camelize: false
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
  end

  class Update < Mutations::UpdateMutation
    include SharedCreateAndUpdateFields

    argument :refresh_media, GraphQL::Types::Int, required: false, camelize: false
    argument :archived, GraphQL::Types::Int, required: false
    argument :previous_project_id, GraphQL::Types::Int, required: false, camelize: false
    argument :project_id, GraphQL::Types::Int, required: false, camelize: false
    argument :source_id, GraphQL::Types::Int, required: false, camelize: false
    argument :read, GraphQL::Types::Boolean, required: false
  end

  class Destroy < Mutations::DestroyMutation; end

  class Replace < Mutations::BaseMutation
    graphql_name "ReplaceProjectMedia"

    argument :project_media_to_be_replaced_id, GraphQL::Types::ID, required: true, camelize: false
    argument :new_project_media_id, GraphQL::Types::ID, required: true, camelize: false

    field :old_project_media_deleted_id, GraphQL::Types::ID, null: true, camelize: false
    field :new_project_media, ProjectMediaType, null: true, camelize: false

    def resolve(project_media_to_be_replaced_id:, new_project_media_id:)
      old_object = GraphqlCrudOperations.object_from_id_if_can(
        project_media_to_be_replaced_id,
        context[:ability]
      )
      new_object = GraphqlCrudOperations.object_from_id_if_can(
        new_project_media_id,
        context[:ability]
      )
      old_object.replace_by(new_object)
      {
        old_project_media_deleted_id: old_object.graphql_id,
        new_project_media: new_object
      }
    end
  end

  module Bulk
    PARENTS = [
      'team',
      'project',
      'project_group',
      { project_was: ProjectType },
      { check_search_project: CheckSearchType },
      { check_search_project_was: CheckSearchType },
      { check_search_team: CheckSearchType },
      { check_search_trash: CheckSearchType },
      { check_search_spam: CheckSearchType },
      { check_search_unconfirmed: CheckSearchType },
    ].freeze

    class Update < Mutations::BulkUpdateMutation
      argument :action, GraphQL::Types::String, required: true
      argument :params, GraphQL::Types::String, required: false
    end

    class MarkRead < Mutations::BulkMarkReadMutation
      description "Allow multiple items to be marked as read or unread."

      graphql_name "BulkProjectMediaMarkRead"

      argument :read, GraphQL::Types::Boolean, required: true, camelize: false
    end
  end
end
