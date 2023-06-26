class ClaimDescriptionType < DefaultObject
  description "ClaimDescription type"

  implements NodeIdentification.interface

  field :dbid, GraphQL::Types::Integer, null: true
  field :description, GraphQL::Types::String, null: true
  field :context, GraphQL::Types::String, null: true, method_conflict_warning: false
  field :user, UserType, null: true
  field :project_media, ProjectMediaType, null: true
  field :fact_check, FactCheckType, null: true
end
