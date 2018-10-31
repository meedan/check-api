ProjectType = GraphqlCrudOperations.define_default_type do
  name 'Project'
  description 'Project type'

  interfaces [NodeIdentification.interface]

  field :avatar, types.String
  field :description, types.String
  field :title, !types.String
  field :dbid, types.Int
  field :permissions, types.String
  field :get_slack_channel, types.String
  field :get_languages, types.String
  field :pusher_channel, types.String
  field :medias_count, types.Int
  field :search_id, types.String
  field :auto_tasks, JsonStringType

  field :team do
    type TeamType

    resolve -> (project, _args, _ctx) {
      team = project.team
      team
    }
  end

  connection :project_medias, -> { ProjectMediaType.connection_type } do
    resolve ->(project, _args, _ctx) {
      project.project_medias.order('id DESC')
    }
  end

  connection :project_sources, -> { ProjectSourceType.connection_type } do
    resolve ->(project, _args, _ctx) {
      project.project_sources.to_a
    }
  end

  # TODO Remove this when `check-web` is updated
  connection :sources, -> { SourceType.connection_type } do
    resolve ->(project, _args, _ctx) {
      project.sources
    }
  end

end
