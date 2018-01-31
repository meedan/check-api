module AnnotationMutations
  create_fields = {
    content: '!str',
    annotation_type: '!str',
    annotated_id: 'str',
    annotated_type: 'str'
  }

  update_fields = {
    content: 'str',
    annotation_type: 'str',
    annotated_id: 'str',
    annotated_type: 'str',
    assigned_to_id: 'int',
    id: '!id'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('annotation', create_fields, update_fields, ['source', 'project_media', 'project', 'project_source'])
end
