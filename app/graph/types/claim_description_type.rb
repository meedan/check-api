class ClaimDescriptionType < DefaultObject
  description "ClaimDescription type"

  implements GraphQL::Types::Relay::Node

  field :dbid, GraphQL::Types::Int, null: true
  field :description, GraphQL::Types::String, null: true
  field :context, GraphQL::Types::String, null: true, resolver_method: :claim_context
  field :user, UserType, null: true
  field :project_media, ProjectMediaType, null: true
  field :project_media_was, ProjectMediaType, null: true
  field :fact_check, FactCheckType, null: true do
    argument :report_status, GraphQL::Types::String, required: false, camelize: false
  end

  def fact_check(report_status: nil)
    ability = context[:ability] || Ability.new
    status = object.project_media&.report_status
    can_read = ability.can?(:read, object) || status == 'published'
    (can_read && (!report_status || status == report_status)) ? object.fact_check : nil
  end
end
