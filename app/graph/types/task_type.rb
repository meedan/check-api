TaskType = GraphqlCrudOperations.define_annotation_type('task', { label: 'str', type: 'str', annotated_type: 'str', description: 'str', json_schema: 'str', slug: 'str' }) do
  field :first_response do
    type AnnotationType

    resolve -> (task, _args, _ctx) {
      obj = task.load || task
      obj.nil? ? nil : obj.first_response_obj
    }
  end

  field :first_response_value do
    type types.String

    resolve -> (task, _args, _ctx) {
      obj = task.load || task
      obj.nil? ? "" : obj.first_response
    }
  end

  field :jsonoptions do
    type types.String

    resolve -> (task, _args, _ctx) {
      obj = task.load || task
      obj.jsonoptions unless obj.nil?
    }
  end

  field :options do
    type JsonStringType

    resolve -> (task, _args, _ctx) {
      obj = task.load || task
      obj.options unless obj.nil?
    }
  end

  field :project_media do
    type ProjectMediaType

    resolve -> (task, _args, _ctx) {
      obj = task.load || task
      obj.annotated if !obj.nil? && obj.annotated_type == 'ProjectMedia'
    }
  end

  field :team_task_id, types.Int

  field :team_task, TeamTaskType

  field :order, types.Int

  field :fieldset, types.String

  field :show_in_browser_extension, types.Boolean

  connection :responses, -> { AnnotationType.connection_type }
end
