AnnotationType = GraphqlCrudOperations.define_annotation_type('annotation', { content: 'str' }) do
  field :project_media do
    type ProjectMediaType

    resolve ->(annotation, _args, _ctx) {
      annotation.annotated_type == 'ProjectMedia' ? annotation.annotated : nil
    }
  end
end
