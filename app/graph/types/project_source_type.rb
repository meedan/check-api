ProjectSourceType = GraphQL::ObjectType.define do
  name 'ProjectSource'
  description 'ProjectSource type'

  interfaces [NodeIdentification.interface]

  field :id, field: GraphQL::Relay::GlobalIdField.new('ProjectSource')
  field :updated_at, types.String
  field :created_at, types.String
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

# End of fields
end
