class TagType < BaseObject
  include Types::Inclusions::AnnotationBehaviors

  def id
    object.relay_id('tag')
  end

  field :tag, GraphQL::Types::String, null: true
  field :tag_text, GraphQL::Types::String, null: true
  field :fragment, GraphQL::Types::String, null: true

  field :tag_text_object, TagTextType, null: true
end
