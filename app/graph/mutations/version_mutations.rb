module VersionMutations
  MUTATION_TARGET = 'version'.freeze
  PARENTS = ['project_media', 'source'].freeze

  class Destroy < DestroyMutation; end
end
