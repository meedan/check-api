ProjectMediaUserType = GraphqlCrudOperations.define_default_type do
  name 'ProjectMediaUser'
  description 'A mapping between users and project medias'

  interfaces [NodeIdentification.interface]

  field :project_media_id, types.Int
  field :user_id, types.Int
  field :project_media, ProjectMediaType
  field :user, UserType
  field :read, types.Boolean
end
