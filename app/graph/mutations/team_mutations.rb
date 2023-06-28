module TeamMutations
  MUTATION_TARGET = 'team'.freeze
  PARENTS = [
    'public_team',
    { check_search_team: CheckSearchType },
    { check_search_trash: CheckSearchType },
    { check_search_spam: CheckSearchType },
    { check_search_unconfirmed: CheckSearchType },
  ].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      argument :archived, GraphQL::Types::Int, required: false
      argument :private, GraphQL::Types::Boolean, required: false
      argument :description, GraphQL::Types::String, required: false

      field :team_userEdge, TeamUserType.edge_type, camelize: false, null: true
      field :user, UserType, null: true
    end
  end

  class Create < Mutations::CreateMutation
    include SharedCreateAndUpdateFields

    argument :name, GraphQL::Types::String, required: true
    argument :slug, GraphQL::Types::String, required: true
  end

  class Update < Mutations::UpdateMutation
    include SharedCreateAndUpdateFields

    argument :name, GraphQL::Types::String, required: false
    argument :add_auto_task, JsonString, required: false, camelize: false
    argument :media_verification_statuses, JsonString, required: false, camelize: false
    argument :set_team_tasks, JsonString, required: false, camelize: false
    argument :rules, GraphQL::Types::String, required: false
    argument :remove_auto_task, GraphQL::Types::String, required: false, camelize: false # label
    argument :empty_trash, GraphQL::Types::Int, required: false, camelize: false
    argument :report, JsonString, required: false

    # Settings fields
    argument :slack_notifications_enabled, GraphQL::Types::String, required: false, camelize: false
    argument :slack_webhook, GraphQL::Types::String, required: false, camelize: false
    argument :slack_notifications, GraphQL::Types::String, required: false, camelize: false
    argument :language, GraphQL::Types::String, required: false
    argument :languages, JsonString, required: false
    argument :language_detection, GraphQL::Types::Boolean, required: false, camelize: false
    argument :list_columns, JsonString, required: false, camelize: false
    argument :tipline_inbox_filters, GraphQL::Types::String, required: false, camelize: false
    argument :suggested_matches_filters, GraphQL::Types::String, required: false, camelize: false
    argument :outgoing_urls_utm_code, GraphQL::Types::String, required: false, camelize: false
    argument :shorten_outgoing_urls, GraphQL::Types::Boolean, required: false, camelize: false
  end

  class Destroy < Mutations::DestroyMutation; end
end
