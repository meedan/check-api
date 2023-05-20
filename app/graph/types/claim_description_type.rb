module Types
  class ClaimDescriptionType < DefaultObject
    description "ClaimDescription type"

    implements GraphQL::Types::Relay::NodeField

    field :dbid, Integer, null: true
    field :description, String, null: true
    field :context, String, null: true, method_conflict_warning: false
    field :user, UserType, null: true
    field :project_media, ProjectMediaType, null: true
    field :fact_check, FactCheckType, null: true
  end
end
