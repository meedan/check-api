ProjectType = GraphqlCrudOperations.define_default_type do
  name 'Project'
  description 'A collection of media items in a team.'

  interfaces [NodeIdentification.interface]

  field :avatar, types.String, 'Picture' # TODO Rename to 'picture'
  field :description, types.String, 'Description'
  field :title, !types.String, 'Name' # TODO Rename to 'name'
  field :get_slack_channel, types.String, 'Slack channel to notify about this project activity' # TODO Rename to 'slack_channel'
  field :pusher_channel, types.String, 'Channel for push notifications'
  field :medias_count, types.Int, 'Items count'
  field :search_id, types.String, 'TODO'
  field :url, types.String, 'Permalink'
  field :search, CheckSearchType, 'Search interface'
  field :auto_tasks, JsonStringType # TODO Why is this here?
  field :team, TeamType, 'Team'

  field :assignments_count, types.Int do
    description 'Count of user assignments'

    resolve ->(project, _args, _ctx) {
      project.reload.assignments_count
    }
  end

  connection :project_medias, -> { ProjectMediaType.connection_type } do
    description 'Medias'

    resolve ->(project, _args, _ctx) {
      project.project_medias.order('id DESC')
    }
  end

  connection :assigned_users, -> { UserType.connection_type } do
    description 'User assignments'

    resolve ->(project, _args, _ctx) {
      project.assigned_users
    }
  end

  field :dbid, types.Int, 'Database id of this record'
  field :permissions, types.String, 'CRUD permissions of this record for current user'
end
