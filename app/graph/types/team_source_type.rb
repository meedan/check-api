TeamSourceType = GraphqlCrudOperations.define_default_type do
  name 'TeamSource'
  description 'TeamSource type'

  interfaces [NodeIdentification.interface]

  field :team_id, types.Int
  field :source_id, types.Int
  field :permissions, types.String
  field :dbid, types.Int

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

# End of fields
end
