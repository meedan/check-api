# TODO Rename to 'TeamMediaProject'
ProjectMediaProjectType = GraphqlCrudOperations.define_default_type do
  name 'ProjectMediaProject'
  description 'Association between a project and an item.'

  interfaces [NodeIdentification.interface]

  field :project_id, types.Int, 'Project database id'
  field :project_media_id, types.Int, 'Item database id'
  field :project, ProjectType, 'Project'
  field :project_media, ProjectMediaType, 'Item'

  field :dbid, types.Int, 'Database id of this record'
end
