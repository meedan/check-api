class FlagType < BaseObject
  include Types::Inclusions::AnnotationBehaviors

  def id
    object.relay_id('flag')
  end

  field :flag, GraphQL::Types::String, null: true
end
