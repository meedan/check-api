module ProjectMutations
  MUTATION_TARGET = 'project'.freeze
  PARENTS = [
    'team',
    'project_group',
    # TODO: consolidate parent class logic if present elsewhere
    { check_search_team: CheckSearchType },
    { previous_default_project: ProjectType },
    { project_group_was: ProjectGroupType },
  ].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      argument :description, GraphQL::Types::String, required: false
      argument :project_group_id, GraphQL::Types::Integer, required: false, camelize: false
    end
  end

  class Create < Mutations::CreateMutation
    include SharedCreateAndUpdateFields

    argument :title, GraphQL::Types::String, required: true
    argument :team_id, GraphQL::Types::Integer, required: false, camelize: false
  end

  class Update < Mutations::UpdateMutation
    include SharedCreateAndUpdateFields

    argument :title, GraphQL::Types::String, required: false
    argument :assigned_to_ids, GraphQL::Types::String, required: false, camelize: false
    argument :assignment_message, GraphQL::Types::String, required: false, camelize: false
    argument :previous_project_group_id, GraphQL::Types::Integer, required: false, camelize: false
    argument :previous_default_project_id, GraphQL::Types::Integer, required: false, camelize: false
    argument :privacy, GraphQL::Types::Integer, required: false
    argument :is_default, GraphQL::Types::Boolean, required: false, camelize: false
  end

  class Destroy < Mutations::DestroyMutation
    argument :items_destination_project_id, GraphQL::Types::Integer, required: false, camelize: false
  end
end
