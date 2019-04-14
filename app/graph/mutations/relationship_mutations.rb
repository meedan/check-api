module RelationshipMutations
  create_fields = {
    source_id: 'int',
    target_id: 'int',
    relationship_type: 'json'
  }

  update_fields = {
    current_id: 'int',
    source_id: 'int',
    target_id: 'int'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('relationship', create_fields, update_fields, ['source_project_media', 'target_project_media', 'current_project_media', 'relationships_target', 'relationships_source'])
end
