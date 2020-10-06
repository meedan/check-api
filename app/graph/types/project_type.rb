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
  field :pusher_channel, types.String
  field :medias_count, types.Int
  field :search_id, types.String
  field :url, types.String
  field :search, CheckSearchType
  field :auto_tasks, JsonStringType
  field :team, TeamType
  field :get_slack_events, JsonStringType

  field :assignments_count, types.Int do
    resolve ->(project, _args, _ctx) {
      project.reload.assignments_count
    }
  end

  connection :project_medias, -> { ProjectMediaType.connection_type } do
    resolve ->(project, _args, _ctx) {
      project.project_medias.order('id DESC')
    }
  end

  connection :assigned_users, -> { UserType.connection_type } do
    resolve ->(project, _args, _ctx) {
      project.assigned_users
    }
  end
end
