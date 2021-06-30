VersionType = GraphqlCrudOperations.define_default_type do
  name 'Version'
  description 'Version type'

  implements NodeIdentification.interface

  field :dbid, Integer, null: true
  field :item_type, String, null: true
  field :item_id, String, null: true
  field :event, String, null: true
  field :event_type, String, null: true
  field :object_after, String, null: true
  field :meta, String, null: true
  field :object_changes_json, String, null: true
  field :associated_graphql_id, String, null: true
  field :smooch_user_slack_channel_url, String, null: true
  field :smooch_user_external_identifier, String, null: true
  field :smooch_report_received_at, Integer, null: true
  field :smooch_report_update_received_at, Integer, null: true
  field :smooch_user_request_language, String, null: true

  field :user, UserType, null: true

  def user
    object.user
  end

  field :annotation, AnnotationType, null: true

  def annotation
    object.annotation
  end

  field :projects, ProjectType.connection_type, null: true, connection: true

  def projects
    object.projects
  end

  field :teams, TeamType.connection_type, null: true, connection: true

  def teams
    object.teams
  end

  field :task, TaskType, null: true

  def task
    object.task
  end

  field :tag, TagType, null: true

  def tag
    Tag.find(object.annotation.id) unless object.annotation.nil?
  end
end
