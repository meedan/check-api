module Mutations::Inclusions
  module AnnotationBehaviors
    extend ActiveSupport::Concern

    included do
      argument :fragment, GraphQL::Types::String, required: false
      argument :annotated_id, GraphQL::Types::String, required: false, camelize: false
      argument :annotated_type, GraphQL::Types::String, required: false, camelize: false
    end
  end
end
