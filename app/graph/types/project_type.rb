ProjectType = GraphqlCrudOperations.define_default_type do
  name 'Project'
  description 'Project type'

  implements NodeIdentification.interface

  field :avatar, String, null: true
  field :description, String, null: true
  field :title, String, null: false
  field :dbid, Integer, null: true
  field :permissions, String, null: true
  field :get_slack_channel, String, null: true
  field :pusher_channel, String, null: true
  field :medias_count, Integer, null: true
  field :search_id, String, null: true
  field :url, String, null: true
  field :search, CheckSearchType, null: true
  field :auto_tasks, JsonStringType, null: true
  field :team, TeamType, null: true
  field :get_slack_events, JsonStringType, null: true
  field :project_group_id, Integer, null: true
  field :project_group, ProjectGroupType, null: true

  field :assignments_count, Integer, null: true

  def assignments_count
    object.reload.assignments_count
  end

  field :project_medias, ProjectMediaType.connection_type, null: true, connection: true

  def project_medias
    object.project_medias.order('id DESC')
  end

  field :assigned_users, UserType.connection_type, null: true, connection: true

  def assigned_users
    object.assigned_users
  end
end
