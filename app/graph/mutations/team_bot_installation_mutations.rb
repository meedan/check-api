module TeamBotInstallationMutations
  MUTATION_TARGET = 'team_bot_installation'.freeze
  PARENTS = ['team', 'bot_user'].freeze

  class Create < CreateMutation
    argument :team_id, Integer, required: true, camelize: false
    argument :user_id, Integer, required: true, camelize: false
  end

  class Update < UpdateMutation
    argument :json_settings, String, required: false, camelize: false
    argument :lock_version, Integer, required: false, camelize: false
  end

  class Destroy < DestroyMutation; end
end
