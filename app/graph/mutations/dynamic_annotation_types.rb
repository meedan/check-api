module DynamicAnnotation::AnnotationTypeManager
  def self.generate_mutation_classes_for_annotation_type(type)
    klass = type.camelize
    mutation_target =  "dynamic_annotation_#{type}"

    Object.class_eval <<-TES
      DynamicAnnotation#{klass} = Dynamic unless defined?(DynamicAnnotation#{klass})

      class DynamicAnnotation#{klass}Type < AnnotationType
        graphql_name "#{mutation_target.capitalize}"
      end unless defined? DynamicAnnotation#{klass}Type

      module DynamicAnnotation#{klass}Mutations
        MUTATION_TARGET = "#{mutation_target}".freeze
        PARENTS = ['project_media', 'source', 'project'].freeze

        module SharedCreateAndUpdateFields
          extend ActiveSupport::Concern

          included do
            argument :action, GraphQL::Types::String, required: false, camelize: false
            argument :fragment, GraphQL::Types::String, required: false, camelize: false
            argument :annotated_id, GraphQL::Types::String, required: false, camelize: false
            argument :annotated_type, GraphQL::Types::String, required: false, camelize: false
            argument :set_attribution, GraphQL::Types::String, required: false, camelize: false
            argument :action_data, GraphQL::Types::String, required: false, camelize: false

            field :versionEdge, VersionType.edge_type, null: true
          end
        end

        class Create < Mutations::CreateMutation
          include SharedCreateAndUpdateFields

          argument :set_fields, GraphQL::Types::String, required: true, camelize: false

          field :dynamic, DynamicType, null: true
          field :dyndynamicEdge, DynamicType.edge_type, null: true
        end unless defined? Create

        class Update < Mutations::UpdateMutation
          include SharedCreateAndUpdateFields

          argument :set_fields, GraphQL::Types::String, required: false, camelize: false
          argument :lock_version, GraphQL::Types::Int, required: false, camelize: false
          argument :assigned_to_ids, GraphQL::Types::String, required: false, camelize: false
          argument :locked, GraphQL::Types::Boolean, required: false, camelize: false
        end unless defined? Update

        class Destroy < Mutations::DestroyMutation; end  unless defined? Destroy
      end
    TES
  end
end
