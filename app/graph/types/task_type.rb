TaskType = GraphqlCrudOperations.define_annotation_type('task', { label: 'str', type: 'str', annotated_type: 'str', description: 'str', json_schema: 'str' }) do
  field :first_response, AnnotationType, null: true

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

  field :options, JsonStringType, null: true

  def options
    obj = object.load || object
    obj.options unless obj.nil?
  end

  field :project_media, ProjectMediaType, null: true

  def project_media
    obj = object.load || object
    obj.annotated if !obj.nil? && obj.annotated_type == 'ProjectMedia'
  end

  field :team_task_id, Integer, null: true

  field :order, Integer, null: true

  field :log_count, Integer, null: true

  def log_count
    obj = object.load || object
    obj.nil? ? 0 : (obj.log_count || 0)
  end

  field :suggestions_count, Integer, null: true

  field :pending_suggestions_count, Integer, null: true

  field :fieldset, String, null: true

  field :show_in_browser_extension, Boolean, null: true

  field :log, VersionType.connection_type, null: true, connection: true

  def log
    obj = object.load || object
    obj.log unless obj.nil?
  end

  field :responses, AnnotationType.connection_type, null: true, connection: true
end
