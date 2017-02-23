VersionType = GraphqlCrudOperations.define_default_type do
  name 'Version'
  description 'Version type'

  interfaces [NodeIdentification.interface]

  field :id, field: GraphQL::Relay::GlobalIdField.new('PaperTrail::Version')
  field :dbid, types.Int
  field :item_type, types.String
  field :item_id, types.String
  field :event, types.String
  field :object_after, types.String

  field :user do
    type -> { UserType }

    resolve ->(version, _args, _ctx) {
      version.user
    }
  end

  field :annotation do
    type -> { AnnotationType }

    resolve ->(version, _args, _ctx) {
      version.annotation
    }
  end
end
