ProjectGroupType = GraphqlCrudOperations.define_default_type do
  name 'ProjectGroup'
  description 'Project group type'

  interfaces [NodeIdentification.interface]

  field :dbid, types.Int
  field :title, types.String
  field :team_id, types.Int
  field :team, TeamType

  connection :projects, ProjectType.connection_type
end
