class TaskType < AnnotationObject
  field :label, String, null: true
  field :type, String, null: true
  field :annotated_type, String, null: true
  field :description, String, null: true
  field :json_schema, String, null: true
  field :slug, String, null: true

  field :first_response, "AnnotationType", null: true

  def first_response
    obj = object.load || object
    obj.nil? ? nil : obj.first_response_obj
  end

  field :first_response_value, String, null: true

  def first_response_value
    obj = object.load || object
    obj.nil? ? "" : obj.first_response
  end

  field :jsonoptions, String, null: true

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

  field :team_task_id, Integer, null: true

  field :team_task, TeamTaskType, null: true

  field :order, Integer, null: true

  field :fieldset, String, null: true

  field :show_in_browser_extension, Boolean, null: true

  field :responses, "AnnotationType", connection: true, null: true
end
