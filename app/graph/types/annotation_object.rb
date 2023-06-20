class AnnotationObject < BaseObject
  class << self
    def define_shared_behavior(subclass, mutation_target)
      subclass.class_variable_set(:@@mutation_target, mutation_target)
    end
  end

  implements NodeIdentification.interface

  field :id, ID, null: false

  field :annotation_type, String, null: true
  field :annotated_id, String, null: true
  field :annotated_type, String, null: true
  field :content, String, null: true
  field :dbid, String, null: true

  def id
    object.relay_id(self.class.class_variable_get(:@@mutation_target))
  end

  field :permissions, String, null: true

  def permissions
    object.permissions(context[:ability], object.annotation_type_class)
  end

  field :created_at, String, null: true

  def created_at
    object.created_at.to_i.to_s
  end

  field :updated_at, String, null: true

  def updated_at
    object.updated_at.to_i.to_s
  end

  field :medias,
        ProjectMediaType.connection_type,
        null: true

  def medias
    object.entity_objects
  end

  field :annotator, AnnotatorType, null: true
  field :version, VersionType, null: true

  field :assignments, UserType.connection_type, null: true

  def assignments
    object.assigned_users
  end

  field :annotations,
        AnnotationUnion.connection_type,
        null: true do
    argument :annotation_type, String, required: true
  end

  def annotations(**args)
    Annotation.where(
      annotation_type: args[:annotation_type],
      annotated_type: ["Annotation", object.annotation_type.camelize],
      annotated_id: object.id
    )
  end

  field :locked, Boolean, null: true

  field :project, ProjectType, null: true

  field :team, TeamType, null: true

  field :file_data, JsonString, null: true

  field :data, JsonString, null: true

  field :parsed_fragment, JsonString, null: true
end
