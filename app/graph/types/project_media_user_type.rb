module Types
  class ProjectMediaUserType < DefaultObject
    description "A mapping between users and project medias"

    implements GraphQL::Types::Relay::NodeField

    field :project_media_id, Integer, null: true
    field :user_id, Integer, null: true
    field :project_media, ProjectMediaType, null: true
    field :user, UserType, null: true
    field :read, Boolean, null: true
  end
end
