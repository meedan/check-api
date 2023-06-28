class AnnotationType < AnnotationObject
  define_shared_behavior(self, 'annotation')

  field :annotation, GraphQL::Types::String, null: true

  field :project_media, ProjectMediaType, null: true

  def project_media
    object.annotated if object.annotated_type == "ProjectMedia"
  end

  field :attribution, UserType.connection_type, null: true

  def attribution
    ids = object.attribution.split(",").map(&:to_i)
    User.where(id: ids)
  end

  field :lock_version, GraphQL::Types::Int, null: true

  field :locked, GraphQL::Types::Boolean, null: true
end
