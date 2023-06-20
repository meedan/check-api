module AccountMutations
  MUTATION_TARGET = 'account'.freeze
  PARENTS = [].freeze

  class Update < UpdateMutation
    argument :refresh_account, Int, required: false, camelize: false
  end
end
