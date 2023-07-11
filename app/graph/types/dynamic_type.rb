class DynamicType < BaseObject
  include Types::Inclusions::AnnotationBehaviors

  def id
    object.relay_id('dynamic')
  end

  field :lock_version, GraphQL::Types::Int, null: true
  field :sent_count, GraphQL::Types::Int, null: true # For "report_design" annotations
end
