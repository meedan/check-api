# TODO Remove
ProjectSourceType = GraphqlCrudOperations.define_default_type do
  name 'ProjectSource'

  interfaces [NodeIdentification.interface]

  field :dbid, types.Int
  field :source_id, types.Int
  field :project_id, types.Int
  field :permissions, types.String

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

  instance_exec :project_source, &GraphqlCrudOperations.field_published
end
