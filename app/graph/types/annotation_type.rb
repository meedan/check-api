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

  field :smooch_slack_url do
    type types.String

    resolve ->(annotation, _args, _ctx) {
      annotation.load.get_field_value('smooch_slack_url') if annotation.annotation_type == 'smooch'
    }
  end

end
