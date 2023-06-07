class TagType < AnnotationObject
  field :tag, String, null: true
  field :tag_text, String, null: true
  field :fragment, String, null: true

  field :tag_text_object, TagTextType, null: true
end
