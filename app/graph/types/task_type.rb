class TaskType < BaseObject
  implements AnnotationInterface
  implements GraphQL::Types::Relay::Node

  # TODO: In future version of GraphQL ruby, we can move
  # this to definition_methods in the annotation interface
  def id
    object.relay_id('task')
  end

  field :label, GraphQL::Types::String, null: true
  field :type, GraphQL::Types::String, null: true
  field :annotated_type, GraphQL::Types::String, null: true
  field :description, GraphQL::Types::String, null: true
  field :json_schema, GraphQL::Types::String, null: true
  field :slug, GraphQL::Types::String, null: true

  field :first_response, AnnotationType, null: true

  def first_response
    obj = object.load || object
    obj.nil? ? nil : obj.first_response_obj
  end

  field :first_response_value, GraphQL::Types::String, null: true

  def first_response_value
    obj = object.load || object
    obj.nil? ? "" : obj.first_response
  end

  field :jsonoptions, GraphQL::Types::String, null: true

  def jsonoptions
    obj = object.load || object
    obj.jsonoptions unless obj.nil?
  end

  field :options, JsonString, null: true

  def options
    obj = object.load || object
    obj.options unless obj.nil?
  end

  field :project_media, ProjectMediaType, null: true

  def project_media
    obj = object.load || object
    obj.annotated if !obj.nil? && obj.annotated_type == "ProjectMedia"
  end

  field :team_task_id, GraphQL::Types::Int, null: true

  field :team_task, TeamTaskType, null: true

  field :order, GraphQL::Types::Int, null: true

  field :fieldset, GraphQL::Types::String, null: true

  field :show_in_browser_extension, GraphQL::Types::Boolean, null: true

  field :responses, AnnotationType.connection_type, null: true
end
