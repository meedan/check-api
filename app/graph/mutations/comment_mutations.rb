module CommentMutations
  create_fields = {
    text: !types.String,
    context_id: types.String,
    context_type: types.String,
    annotated_id: types.String,
    annotated_type: types.String
  }
    
  update_fields = {
    text: types.String,
    context_id: types.String,
    context_type: types.String,
    annotated_id: types.String,
    annotated_type: types.String,
    version_index: types.Int,
    annotation_type: types.String,
    id: !types.ID
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('comment', create_fields, update_fields)
end
