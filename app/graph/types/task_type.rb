class TaskType < BaseObject
  include Types::Inclusions::AnnotationBehaviors

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
    obj.nil? ? nil : Loaders::FirstResponseLoader.for.load(obj.id)
  end

  field :first_response_value, GraphQL::Types::String, null: true

  def first_response_value
    obj = object.load || object
    return "" if obj.nil?
    Loaders::FirstResponseLoader.for.load(obj.id).then do |response|
      next nil if response.nil?
      Loaders::AnnotationFieldsLoader.for.load(response.id).then do |fields|
        field = response.get_fields(fields).select{ |f| f.field_name =~ /^response/ }.first
        field&.to_s
      end
    end
  end

  field :jsonoptions, GraphQL::Types::String, null: true

  def jsonoptions
    obj = object.load || object
    obj.jsonoptions unless obj.nil?
  end

  field :options, JsonStringType, null: true

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
