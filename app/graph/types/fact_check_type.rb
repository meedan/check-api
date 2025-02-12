class FactCheckType < DefaultObject
  description "FactCheck type"

  implements GraphQL::Types::Relay::Node

  field :dbid, GraphQL::Types::Int, null: true
  field :title, GraphQL::Types::String, null: true
  field :summary, GraphQL::Types::String, null: true
  field :url, GraphQL::Types::String, null: true
  field :language, GraphQL::Types::String, null: true
  field :user, UserType, null: true
  field :claim_description, ClaimDescriptionType, null: true
  field :tags, [GraphQL::Types::String, null: true], null: true
  field :rating, GraphQL::Types::String, null: true
  field :imported, GraphQL::Types::Boolean, null: true
  field :report_status, GraphQL::Types::String, null: true
  field :trashed, GraphQL::Types::Boolean, null: true
  
  field :author, UserType, null: true

  # FIXME: Return actual article creator
  def author
    object.user
  end
end
