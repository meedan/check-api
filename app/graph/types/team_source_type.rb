TeamSourceType = GraphqlCrudOperations.define_default_type do
  name 'TeamSource'
  description 'TeamSource type'

  interfaces [NodeIdentification.interface]

  field :team_id, types.Int
  field :source_id, types.Int
  field :permissions, types.String
  field :dbid, types.Int

  field :project_id do
    type types.Int

    resolve -> (team_source, _args, _ctx) {
      team_source.projects
    }
  end

  field :source do
    type -> { SourceType }

    resolve -> (team_source, _args, _ctx) {
      team_source.source
    }
  end

  field :team do
    type -> { TeamType }

    resolve -> (team_source, _args, _ctx) {
      team_source.team
    }
  end

  field :user do
    type -> { UserType }

    resolve -> (team_source, _args, _ctx) {
      team_source.user
    }
  end

  instance_exec :project_source, &GraphqlCrudOperations.field_published

# End of fields
end
