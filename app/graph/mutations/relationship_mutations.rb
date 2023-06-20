module RelationshipMutations
  MUTATION_TARGET = 'relationship'.freeze
  PARENTS = [
    { source_project_media: ProjectMediaType },
    { target_project_media: ProjectMediaType },
  ].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      argument :source_id, Integer, required: false, camelize: false
      argument :target_id, Integer, required: false, camelize: false
      argument :relationship_source_type, String, required: false, camelize: false
      argument :relationship_target_type, String, required: false, camelize: false
    end
  end

  class Create < CreateMutation
    include SharedCreateAndUpdateFields

    argument :relationship_type, JsonString, required: false, camelize: false
  end

  class Update < UpdateMutation
    include SharedCreateAndUpdateFields
  end

  class Destroy < DestroyMutation; end

  BulkUpdate = GraphqlCrudOperations.define_bulk_update_or_destroy(:update, Relationship, { action: '!str', source_id: "!int" }, ['source_project_media'])
  BulkDestroy = GraphqlCrudOperations.define_bulk_update_or_destroy(:destroy, Relationship, { source_id: "!int", add_to_project_id: "int" }, ['source_project_media'])
end
