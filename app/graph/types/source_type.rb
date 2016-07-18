SourceType = GraphQL::ObjectType.define do
  name 'Source'
  description 'Source type'

  interfaces [NodeIdentification.interface]

  field :id, field: GraphQL::Relay::GlobalIdField.new('Source')
  field :updated_at, types.String
  field :created_at, types.String
  field :avatar, !types.String
  field :slogan, !types.String
  field :name, !types.String
  connection :accounts, -> { AccountType.connection_type } do
    resolve ->(source, _args, _ctx) {
      source.accounts
    }
  end

  connection :project_sources, -> { ProjectSourceType.connection_type } do
    resolve ->(source, _args, _ctx) {
      source.project_sources
    }
  end

  connection :projects, -> { ProjectType.connection_type } do
    resolve ->(source, _args, _ctx) {
      source.projects
    }
  end

# End of fields
end
