class ProjectType < DefaultObject
  description "Project type"

  implements NodeIdentification.interface

  field :avatar, GraphQL::Types::String, null: true
  field :description, GraphQL::Types::String, null: true
  field :title, GraphQL::Types::String, null: false
  field :dbid, GraphQL::Types::Int, null: true
  field :permissions, GraphQL::Types::String, null: true
  field :pusher_channel, GraphQL::Types::String, null: true
  field :medias_count, GraphQL::Types::Int, null: true
  field :search_id, GraphQL::Types::String, null: true
  field :url, GraphQL::Types::String, null: true
  field :search, CheckSearchType, null: true
  field :team, TeamType, null: true
  field :project_group_id, GraphQL::Types::Int, null: true
  field :project_group, ProjectGroupType, null: true
  field :privacy, GraphQL::Types::Int, null: true
  field :is_default, GraphQL::Types::Boolean, null: true

  field :assignments_count, GraphQL::Types::Int, null: true

  def assignments_count
    object.reload.assignments_count
  end

  field :project_medias,
        ProjectMediaType.connection_type,
        null: true

  def project_medias
    object.project_medias.order("id DESC")
  end

  field :assigned_users,
        UserType.connection_type,
        null: true

  def assigned_users
    object.assigned_users
  end
end
