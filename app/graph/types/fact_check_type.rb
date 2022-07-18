FactCheckType = GraphqlCrudOperations.define_default_type do
  name 'FactCheck'
  description 'FactCheck type'

  interfaces [NodeIdentification.interface]

  field :dbid, types.Int
  field :title, types.String
  field :summary, types.String
  field :url, types.String
  field :language, types.String
  field :user, UserType
  field :claim_description, ClaimDescriptionType
end
