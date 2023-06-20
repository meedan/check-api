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
            argument :action, String, required: false, camelize: false
            argument :fragment, String, required: false, camelize: false
            argument :annotated_id, String, required: false, camelize: false
            argument :annotated_type, String, required: false, camelize: false
            argument :set_attribution, String, required: false, camelize: false
            argument :action_data, String, required: false, camelize: false

            field :versionEdge, VersionType.edge_type, null: true
          end
        end

        class Create < CreateMutation
          include SharedCreateAndUpdateFields

          argument :set_fields, String, required: true, camelize: false

          field :dynamic, DynamicType, null: true
          field :dyndynamicEdge, DynamicType.edge_type, null: true
        end unless defined? Create

        class Update < UpdateMutation
          include SharedCreateAndUpdateFields

          argument :set_fields, String, required: false, camelize: false
          argument :lock_version, Integer, required: false, camelize: false
          argument :assigned_to_ids, String, required: false, camelize: false
          argument :locked, Boolean, required: false, camelize: false
        end unless defined? Update

        class Destroy < DestroyMutation; end  unless defined? Destroy
      end
    TES
  end
end
