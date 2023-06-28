module AnnotationMutations
  MUTATION_TARGET = 'annotation'.freeze
  PARENTS = ['source', 'project_media', 'project', 'task'].freeze

  class Create < Mutations::CreateMutation
    argument :content, GraphQL::Types::String, required: true
    argument :annotation_type, GraphQL::Types::String, required: true, camelize: false
    argument :locked, GraphQL::Types::Boolean, required: false
    argument :annotated_id, GraphQL::Types::String, required: false, camelize: false
  end

  class Destroy < Mutations::DestroyMutation; end
end
