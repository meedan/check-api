module Types
  class FactCheckType < DefaultObject
    description "FactCheck type"

    implements GraphQL::Types::Relay::NodeField

    field :dbid, Integer, null: true
    field :title, String, null: true
    field :summary, String, null: true
    field :url, String, null: true
    field :language, String, null: true
    field :user, UserType, null: true
    field :claim_description, ClaimDescriptionType, null: true
  end
end
