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
      team.context_team = project.context_team
      team.current_user = project.current_user
      team
    }
  end

  connection :medias, MediaType.connection_type, property: :eager_loaded_medias

  connection :sources, -> { SourceType.connection_type } do
    resolve ->(project, _args, _ctx) {
      project.sources
    }
  end

  connection :annotations, -> { AnnotationType.connection_type } do
    resolve ->(project, _args, _ctx) {
      project.annotations
    }
  end
end
