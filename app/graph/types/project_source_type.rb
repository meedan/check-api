ProjectSourceType = GraphqlCrudOperations.define_default_type do
  name 'ProjectSource'
  description 'ProjectSource type'

  interfaces [NodeIdentification.interface]

  field :id, field: GraphQL::Relay::GlobalIdField.new('ProjectSource')
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

  instance_exec :project_source, &GraphqlCrudOperations.field_log

  instance_exec :project_source, &GraphqlCrudOperations.field_log_count

  instance_exec :project_source, &GraphqlCrudOperations.field_published

  instance_exec :project_source, &GraphqlCrudOperations.field_annotations

  instance_exec :project_source, &GraphqlCrudOperations.field_annotations_count

  instance_exec :project_source, &GraphqlCrudOperations.field_value

# End of fields
end
