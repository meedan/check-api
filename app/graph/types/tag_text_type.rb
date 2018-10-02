TagTextType = GraphqlCrudOperations.define_default_type do
  name 'TagText'
  description 'Tag text type'

  interfaces [NodeIdentification.interface]

  field :dbid, types.Int
  field :text, types.String
  field :tags_count, types.Int
  field :teamwide, types.Boolean
end
