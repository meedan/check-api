module AnnotationMutations
  create_fields = {
    content: '!str',
    annotation_type: '!str',
    context_id: 'str',
    context_type: 'str',
    annotated_id: 'str',
    annotated_type: 'str'
  }
    
  update_fields = {
    content: 'str',
    annotation_type: 'str',
    context_id: 'str',
    context_type: 'str',
    annotated_id: 'str',
    annotated_type: 'str',
    id: '!id'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('annotation', create_fields, update_fields, ['source', 'media'])
end
