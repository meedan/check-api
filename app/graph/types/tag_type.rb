TagType = GraphqlCrudOperations.define_annotation_type('tag', { tag: 'str', tag_text: 'str', fragment: 'str' }) do
  description 'Annotation representing a single tag for an item.'
  field :tag_text_object, TagTextType
end
