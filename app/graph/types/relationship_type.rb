class RelationshipType < BaseObject
  description "A relationship between two items"
  implements NodeIdentification.interface

  global_id_field :id

  field :dbid, Integer, null: true
  field :target_id, Integer, null: true
  field :source_id, Integer, null: true
  field :permissions, String, null: true
  field :relationship_type, String, null: true

  field :target, ProjectMediaType, null: true
  field :source, ProjectMediaType, null: true
end
