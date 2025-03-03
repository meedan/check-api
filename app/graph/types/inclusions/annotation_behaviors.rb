module Types::Inclusions
  module AnnotationBehaviors
    extend ActiveSupport::Concern

    included do
      implements GraphQL::Types::Relay::Node

      global_id_field :id

      field :id, GraphQL::Types::ID, null: false
      field :annotation_type, GraphQL::Types::String, null: true, camelize: false
      field :annotated_id, GraphQL::Types::String, null: true, camelize: false
      field :annotated_type, GraphQL::Types::String, null: true, camelize: false
      field :content, GraphQL::Types::String, null: true
      field :dbid, GraphQL::Types::String, null: true

      field :permissions, GraphQL::Types::String, null: true

      def permissions
        object.permissions(context[:ability], object.annotation_type_class)
      end

      field :created_at, GraphQL::Types::String, null: true, camelize: false

      def created_at
        object.created_at.to_i.to_s
      end

      field :updated_at, GraphQL::Types::String, null: true, camelize: false

      def updated_at
        object.updated_at.to_i.to_s
      end

      field :medias,
            ::ProjectMediaType.connection_type,
            null: true

      def medias
        object.entity_objects
      end

      field :annotator, ::AnnotatorType, null: true
      field :version, ::VersionType, null: true

      field :assignments, ::UserType.connection_type, null: true

      def assignments
        object.assigned_users
      end

      field :annotations, ::AnnotationUnion.connection_type, null: true do
        argument :annotation_type, GraphQL::Types::String, required: true, camelize: false
      end

      field :locked, GraphQL::Types::Boolean, null: true

      field :project, ::ProjectType, null: true

      field :team, ::TeamType, null: true

      field :file_data, ::JsonStringType, null: true, camelize: false

      field :data, ::JsonStringType, null: true

      field :parsed_fragment, ::JsonStringType, null: true, camelize: false
    end
  end
end
