module ProjectMediaMutations
  MUTATION_TARGET = 'project_media'.freeze
  PARENTS = [
    'project',
    'team',
    'project_group',
    # TODO: consolidate parent class logic if present elsewhere
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
      argument :media_id, Integer, required: false, camelize: false
      argument :related_to_id, Integer, required: false, camelize: false

      field :affectedId, GraphQL::Types::ID, null: true
    end
  end

  class Create < CreateMutation
    include SharedCreateAndUpdateFields

    argument :url, String, required: false
    argument :quote, String, required: false
    argument :quote_attributions, String, required: false, camelize: false
    argument :project_id, Integer, required: false, camelize: false
    argument :media_id, Integer, required: false, camelize: false
    argument :team_id, Integer, required: false, camelize: false
    argument :channel, JsonString, required: false
    argument :media_type, String, required: false, camelize: false

    # Set fields
    argument :set_annotation, String, required: false, camelize: false
    argument :set_claim_description, String, required: false, camelize: false
    argument :set_fact_check, JsonString, required: false, camelize: false
    argument :set_tasks_responses, JsonString, required: false, camelize: false
    argument :set_tags, JsonString, required: false, camelize: false
    argument :set_title, String, required: false, camelize: false
    argument :set_status, String, required: false, camelize: false # Status identifier (for example, "in_progress")
  end

  class Update < UpdateMutation
    include SharedCreateAndUpdateFields

    argument :refresh_media, Integer, required: false, camelize: false
    argument :archived, Integer, required: false
    argument :previous_project_id, Integer, required: false, camelize: false
    argument :project_id, Integer, required: false, camelize: false
    argument :source_id, Integer, required: false, camelize: false
    argument :read, Boolean, required: false
  end

  class Destroy < DestroyMutation; end

  class Replace < BaseMutation
    graphql_name "ReplaceProjectMedia"

    argument :project_media_to_be_replaced_id, ID, required: true, camelize: false
    argument :new_project_media_id, ID, required: true, camelize: false

    field :old_project_media_deleted_id, ID, null: true, camelize: false
    field :new_project_media, ProjectMediaType, null: true, camelize: false

    def resolve(**inputs)
      old = GraphqlCrudOperations.object_from_id_if_can(
        inputs[:project_media_to_be_replaced_id],
        context[:ability]
      )
      new = GraphqlCrudOperations.object_from_id_if_can(
        inputs[:new_project_media_id],
        context[:ability]
      )
      old.replace_by(new)
      {
        old_project_media_deleted_id: old.graphql_id,
        new_project_media: new
      }
    end
  end

  class BulkUpdate < BaseMutation
    graphql_name "UpdateProjectMedias"

    argument :ids, [ID], required: true
    argument :action, String, required: true
    argument :params, String, required: false

    field :ids, [ID], null: false # not sure about false
    field :updated_objects, [ProjectMediaType], null: false

    # This only doesn't have related_to - is that meaningful?
    parents = [
      'team',
      'project',
      'project_group',
      # TODO: consolidate parent class logic if present elsewhere
      { project_was: ProjectType },
      { check_search_project: CheckSearchType },
      { check_search_project_was: CheckSearchType },
      { check_search_team: CheckSearchType },
      { check_search_trash: CheckSearchType },
      { check_search_spam: CheckSearchType },
      { check_search_unconfirmed: CheckSearchType },
    ]
    set_parent_returns(self, parents)

    def resolve(**inputs)
      GraphqlCrudOperations.apply_bulk_update_or_destroy(
        inputs,
        context,
        'update',
        ProjectMedia
      )
    end
  end
end
