module VersionMutations
  MUTATION_TARGET = 'version'.freeze
  PARENTS = ['project_media', 'source'].freeze

  class Destroy < Mutation::Destroy; end
end
