module RelationshipMutations
  create_fields = {
    source_id: 'int',
    target_id: 'int',
    relationship_type: 'json',
    relationship_source_type: 'str',
    relationship_target_type: 'str'
  }

  update_fields = {
    source_id: 'int',
    target_id: 'int',
    relationship_source_type: 'str',
    relationship_target_type: 'str'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('relationship', create_fields, update_fields, ['source_project_media', 'target_project_media'])
end
