module VersionMutations
  MUTATION_TARGET = 'version'.freeze
  PARENTS = ['project_media', 'source'].freeze

  class Destroy < Mutations::DestroyMutation; end
end
