AnnotationType = GraphqlCrudOperations.define_annotation_type('annotation', { content: 'str' }) do
  field :project_media do
    type ProjectMediaType

    resolve ->(annotation, _args, _ctx) {
      annotation.annotated_type == 'ProjectMedia' ? annotation.annotated : nil
    }
  end

  connection :attribution, -> { UserType.connection_type } do
    resolve ->(annotation, _args, _ctx) {
      ids = annotation.attribution.split(',').map(&:to_i)
      User.where(id: ids)
    }
  end

  field :lock_version, types.Int

  field :locked, types.Boolean

  connection :annotations, -> { AnnotationType.connection_type }
end
