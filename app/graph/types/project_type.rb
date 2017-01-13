ProjectType = GraphqlCrudOperations.define_default_type do
  name 'Project'
  description 'Project type'

  interfaces [NodeIdentification.interface]

  field :id, field: GraphQL::Relay::GlobalIdField.new('Project')
  field :avatar, types.String
  field :description, types.String
  field :title, !types.String
  field :dbid, types.Int
  field :permissions, types.String
  field :get_slack_channel, types.String
  field :pusher_channel, types.String
  field :medias_count, types.Int

  field :team do
    type TeamType

    resolve -> (project, _args, _ctx) {
      team = project.team
      team
    }
  end

  connection :project_medias, -> { ProjectMediaType.connection_type } do
    resolve ->(project, _args, _ctx) {
      project.project_medias.to_a
    }
  end

  connection :sources, -> { SourceType.connection_type } do
    resolve ->(project, _args, _ctx) {
      project.sources
    }
  end
end
