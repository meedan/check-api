AnnotationType = GraphqlCrudOperations.define_annotation_type('annotation', { content: 'str' }) do
  description 'The base type for annotations describing media, claims, sources, and other types including annotations themselves (recursively).'

  # TODO Return the actual type based on `annotated_type`
  # Consider union types https://graphql.org/learn/schema/#union-types
  field :project_media do
    type ProjectMediaType
    description 'Item described by this annotation'

    resolve ->(annotation, _args, _ctx) {
      annotation.annotated_type == 'ProjectMedia' ? annotation.annotated : nil
    }
  end

  connection :attribution, -> { UserType.connection_type } do
    description 'List of users who have contributed to this annotation'

    resolve ->(annotation, _args, _ctx) {
      ids = annotation.attribution.split(',').map(&:to_i)
      User.where(id: ids)
    }
  end
end
