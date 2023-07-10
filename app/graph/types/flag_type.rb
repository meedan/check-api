class FlagType < BaseObject
  implements AnnotationInterface
  implements GraphQL::Types::Relay::Node

  # TODO: In future version of GraphQL ruby, we can move
  # this to definition_methods in the annotation interface
  def id
    object.relay_id('flag')
  end

  field :flag, GraphQL::Types::String, null: true
end
