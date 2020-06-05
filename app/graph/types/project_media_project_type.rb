# TODO Rename to 'TeamMediaProject'
ProjectMediaProjectType = GraphqlCrudOperations.define_default_type do
  name 'ProjectMediaProject'
  description 'Association between a project and a media.'

  interfaces [NodeIdentification.interface]

  field :project_id, types.Int # TODO Remove
  field :project_media_id, types.Int # TODO Remove
  field :project, ProjectType, 'Project'
  field :project_media, ProjectMediaType, 'TeamMedia' # TODO Rename to 'team_media'
end
