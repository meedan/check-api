module AnnotationMutations
  MUTATION_TARGET = 'annotation'.freeze
  PARENTS = ['source', 'project_media', 'project', 'task'].freeze

  class Destroy < Mutations::DestroyMutation; end
end
