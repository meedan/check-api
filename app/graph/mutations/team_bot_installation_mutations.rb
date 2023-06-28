module TeamBotInstallationMutations
  MUTATION_TARGET = 'team_bot_installation'.freeze
  PARENTS = ['team', 'bot_user'].freeze

  class Create < Mutations::CreateMutation
    argument :team_id, GraphQL::Types::Int, required: true, camelize: false
    argument :user_id, GraphQL::Types::Int, required: true, camelize: false
  end

  class Update < Mutations::UpdateMutation
    argument :json_settings, GraphQL::Types::String, required: false, camelize: false
    argument :lock_version, GraphQL::Types::Int, required: false, camelize: false
  end

  class Destroy < Mutations::DestroyMutation; end
end
