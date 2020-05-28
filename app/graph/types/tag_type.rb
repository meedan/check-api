TagType = GraphqlCrudOperations.define_annotation_type('tag', { tag: 'str', tag_text: 'str', fragment: 'str' }) do
  field :tag_text_object, TagTextType
end
