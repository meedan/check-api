module DynamicAnnotation::AnnotationTypeManager
  def self.generate_mutation_classes_for_annotation_type(type)
    klass = type.camelize
    mutation_target =  "dynamic_annotation_#{type}"

    Object.class_eval <<-TES
      DynamicAnnotation#{klass} = Dynamic unless defined?(DynamicAnnotation#{klass})

      class DynamicAnnotation#{klass}Type < BaseObject
        include Types::Inclusions::AnnotationBehaviors

        graphql_name "#{mutation_target.capitalize}"

        def id
          object.relay_id('annotation')
        end

        field :lock_version, GraphQL::Types::Int, null: true
        field :locked, GraphQL::Types::Boolean, null: true
      end unless defined? DynamicAnnotation#{klass}Type

      module DynamicAnnotation#{klass}Mutations
        MUTATION_TARGET = "#{mutation_target}".freeze
        PARENTS = ['project_media', 'source'].freeze

        module SharedCreateAndUpdateFields
          extend ActiveSupport::Concern
          include Mutations::Inclusions::AnnotationBehaviors

          included do
            argument :action, GraphQL::Types::String, required: false
            argument :fragment, GraphQL::Types::String, required: false
            argument :set_attribution, GraphQL::Types::String, required: false, camelize: false
            argument :action_data, GraphQL::Types::String, required: false, camelize: false

            field :versionEdge, VersionType.edge_type, null: true
            field :dynamic, DynamicType, null: true
            field :dynamicEdge, DynamicType.edge_type, null: true
          end
        end

        class Create < Mutations::CreateMutation
          include SharedCreateAndUpdateFields

          argument :set_fields, GraphQL::Types::String, required: true, camelize: false
        end unless defined? Create

        class Update < Mutations::UpdateMutation
          include SharedCreateAndUpdateFields

          argument :set_fields, GraphQL::Types::String, required: false, camelize: false
          argument :lock_version, GraphQL::Types::Int, required: false, camelize: false
          argument :assigned_to_ids, GraphQL::Types::String, required: false, camelize: false
          argument :locked, GraphQL::Types::Boolean, required: false
        end unless defined? Update

        class Destroy < Mutations::DestroyMutation; end  unless defined? Destroy
      end
    TES
  end
end
