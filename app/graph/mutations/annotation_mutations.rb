module AnnotationMutations
  MUTATION_TARGET = 'annotation'.freeze
  PARENTS = ['source', 'project_media', 'project', 'task'].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      argument :locked, GraphQL::Types::Boolean, required: false
      argument :annotated_id, String, required: false, camelize: false
      argument :annotated_type, String, required: false, camelize: false
    end
  end

  class Create < Mutations::CreateMutation
    include SharedCreateAndUpdateFields

    argument :content, String, required: true
    argument :annotation_type, String, required: true, camelize: false
  end

  class Destroy < Mutations::DestroyMutation; end
end
