class DynamicType < BaseObject
  implements AnnotationInterface

  # TODO: In future version of GraphQL ruby, we can move
  # this to definition_methods in the annotation interface
  def id
    object.relay_id('dynamic')
  end

  field :lock_version, GraphQL::Types::Int, null: true
  field :sent_count, GraphQL::Types::Int, null: true # For "report_design" annotations
end
