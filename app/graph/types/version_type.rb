class VersionType < DefaultObject
  description "Version type"

  implements NodeIdentification.interface

  field :dbid, Integer, null: true
  field :item_type, String, null: true
  field :item_id, String, null: true
  field :event, String, null: true
  field :event_type, String, null: true
  field :object_after, String, null: true
  field :meta, String, null: true
  field :object_changes_json, String, null: true
  field :associated_graphql_id, String, null: true

  field :user, UserType, null: true

  def user
    object.user
  end

  field :annotation, "AnnotationType", null: true

  def annotation
    object.annotation
  end

  field :task, "TaskType", null: true

  def task
    object.task
  end

  field :tag, "TagType", null: true

  def tag
    Tag.find(object.annotation.id) unless object.annotation.nil?
  end
end
