ProjectMediaProjectType = GraphqlCrudOperations.define_default_type do
  name 'ProjectMediaProject'
  description 'ProjectMediaProject type'

  interfaces [NodeIdentification.interface]

  field :project_id, types.Int
  field :project_media_id, types.Int
  field :project, ProjectType
  field :project_media, ProjectMediaType
end
