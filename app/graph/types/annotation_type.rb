class AnnotationType < AnnotationObject
  field :annotation, String, null: true

  field :project_media, ProjectMediaType, null: true, resolve: ->(**_inputs) do
    object.annotated if object.annotated_type == "ProjectMedia"
  end

  field :attribution, UserType.connection_type, null: true, resolve: ->(**_inputs) {
              ids = object.attribution.split(",").map(&:to_i)
              User.where(id: ids)
            }

  field :lock_version, Integer, null: true

  field :locked, Boolean, null: true
end
