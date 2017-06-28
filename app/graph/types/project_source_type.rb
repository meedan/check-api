ProjectSourceType = GraphqlCrudOperations.define_default_type do
  name 'ProjectSource'
  description 'ProjectSource type'

  interfaces [NodeIdentification.interface]

  field :id, field: GraphQL::Relay::GlobalIdField.new('ProjectSource')
  field :updated_at, types.String
  field :created_at, types.String
  field :source_id, types.Int
  field :project_id, types.Int
  field :permissions, types.String
  field :dbid, types.Int

  field :project do
    type -> { ProjectType }

    resolve -> (project_source, _args, _ctx) {
      project_source.project
    }
  end

  field :source do
    type -> { SourceType }

    resolve -> (project_source, _args, _ctx) {
      project_source.source
    }
  end

  field :user do
    type -> { UserType }

    resolve -> (project_source, _args, _ctx) {
      project_source.user
    }
  end

  field :team do
    type -> { TeamType }

    resolve ->(project_source, _args, _ctx) {
      project_source.project.team
    }
  end

  connection :tags, -> { TagType.connection_type } do
    resolve ->(project_source, _args, _ctx) {
      project_source.get_annotations('tag')
    }
  end

  connection :annotations, -> { AnnotationType.connection_type } do
    argument :annotation_type, !types.String

    resolve ->(project_source, args, _ctx) {
      project_source.get_annotations(args['annotation_type'].split(',').map(&:strip))
    }
  end

  field :annotations_count do
    type types.Int
    argument :annotation_type, !types.String

    resolve ->(project_media, args, _ctx) {
      project_media.get_annotations(args['annotation_type'].split(',').map(&:strip)).count
    }
  end

# End of fields
end
