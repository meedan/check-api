module TeamTaskMutations
  MUTATION_TARGET = 'team_task'.freeze
  PARENTS = ['team'].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      argument :label, GraphQL::Types::String, required: true
      argument :description, GraphQL::Types::String, required: false
      argument :order, GraphQL::Types::Integer, required: false
      argument :fieldset, GraphQL::Types::String, required: false
      argument :required, GraphQL::Types::Boolean, required: false
      argument :task_type, GraphQL::Types::String, required: false, camelize: false
      argument :json_options, GraphQL::Types::String, required: false, camelize: false
      argument :json_schema, GraphQL::Types::String, required: false, camelize: false
      argument :keep_completed_tasks, GraphQL::Types::Boolean, required: false, camelize: false
      argument :associated_type, GraphQL::Types::String, required: false, camelize: false
      argument :show_in_browser_extension, GraphQL::Types::Boolean, required: false, camelize: false
      argument :conditional_info, GraphQL::Types::String, required: false, camelize: false
      argument :options_diff, JsonString, required: false, camelize: false
    end
  end

  class Create < Mutations::CreateMutation
    include SharedCreateAndUpdateFields

    argument :team_id, GraphQL::Types::Integer, required: true, camelize: false
  end

  class Update < Mutations::UpdateMutation
    include SharedCreateAndUpdateFields
  end

  class Destroy < Mutations::DestroyMutation; end
end
