class TagType < BaseObject
  implements AnnotationInterface

  # TODO: In future version of GraphQL ruby, we can move
  # this to definition_methods in the annotation interface
  def id
    object.relay_id('tag')
  end

  field :tag, GraphQL::Types::String, null: true
  field :tag_text, GraphQL::Types::String, null: true
  field :fragment, GraphQL::Types::String, null: true

  field :tag_text_object, TagTextType, null: true
end
