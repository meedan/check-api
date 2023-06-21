module TeamBotInstallationMutations
  MUTATION_TARGET = 'team_bot_installation'.freeze
  PARENTS = ['team', 'bot_user'].freeze

  class Create < Mutation::Create
    argument :team_id, Integer, required: true, camelize: false
    argument :user_id, Integer, required: true, camelize: false
  end

  class Update < Mutation::Update
    argument :json_settings, String, required: false, camelize: false
    argument :lock_version, Integer, required: false, camelize: false
  end

  class Destroy < Mutation::Destroy; end
end
