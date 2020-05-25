FlagType = GraphqlCrudOperations.define_annotation_type('flag', { flag: 'str' }) do
  description 'Annotation holding various flags about the content (spam, violence, etc.)' # TODO List all actual flags
end
