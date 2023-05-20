module Types
  class AnnotationType < AnnotationObject
    field :annotation, String, null: true

    field :project_media, ProjectMediaType, null: true, resolve: ->(annotation, _args, _ctx) do
      annotation.annotated if annotation.annotated_type == "ProjectMedia"
    end

    field :attribution, UserType.connection_type, null: true, connection: true, resolve: ->(annotation, _args, _ctx) {
                ids = annotation.attribution.split(",").map(&:to_i)
                User.where(id: ids)
              }

    field :lock_version, Integer, null: true

    field :locked, Boolean, null: true
  end
end
