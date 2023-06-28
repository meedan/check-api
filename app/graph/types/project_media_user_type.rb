class ProjectMediaUserType < DefaultObject
  description "A mapping between users and project medias"

  implements NodeIdentification.interface

  field :project_media_id, GraphQL::Types::Int, null: true
  field :user_id, GraphQL::Types::Int, null: true
  field :project_media, ProjectMediaType, null: true
  field :user, UserType, null: true
  field :read, GraphQL::Types::Boolean, null: true
end
