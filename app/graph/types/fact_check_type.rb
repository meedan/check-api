class FactCheckType < DefaultObject
  description "FactCheck type"

  implements NodeIdentification.interface

  field :dbid, GraphQL::Types::Integer, null: true
  field :title, GraphQL::Types::String, null: true
  field :summary, GraphQL::Types::String, null: true
  field :url, GraphQL::Types::String, null: true
  field :language, GraphQL::Types::String, null: true
  field :user, UserType, null: true
  field :claim_description, ClaimDescriptionType, null: true
end
