ClaimDescriptionType = GraphqlCrudOperations.define_default_type do
  name 'ClaimDescription'
  description 'ClaimDescription type'

  interfaces [NodeIdentification.interface]

  field :dbid, types.Int
  field :description, types.String
  field :context, types.String
  field :user, UserType
  field :project_media, ProjectMediaType
  field :fact_check, FactCheckType
end
