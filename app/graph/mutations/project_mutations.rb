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
      argument :description, String, required: false
      argument :project_group_id, Integer, required: false, camelize: false
    end
  end

  class Create < CreateMutation
    include SharedCreateAndUpdateFields

    argument :title, String, required: true
    argument :team_id, Integer, required: false, camelize: false
  end

  class Update < UpdateMutation
    include SharedCreateAndUpdateFields

    argument :title, String, required: false
    argument :assigned_to_ids, String, required: false, camelize: false
    argument :assignment_message, String, required: false, camelize: false
    argument :previous_project_group_id, Integer, required: false, camelize: false
    argument :previous_default_project_id, Integer, required: false, camelize: false
    argument :privacy, Integer, required: false
    argument :is_default, Boolean, required: false, camelize: false
  end

  class Destroy < DestroyMutation
    argument :items_destination_project_id, Integer, required: false, camelize: false
  end
end
