TaskType = GraphqlCrudOperations.define_annotation_type('task', { label: 'str', type: 'str', description: 'str', json_schema: 'str' }) do
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

  field :log_count do
    type types.Int

    resolve -> (task, _args, _ctx) {
      obj = task.load || task
      obj.nil? ? 0 : (obj.log_count || 0)
    }
  end

  field :suggestions_count, types.Int
  field :pending_suggestions_count, types.Int

  connection :log, -> { VersionType.connection_type } do
    resolve ->(task, _args, _ctx) {
      obj = task.load || task
      obj.log unless obj.nil?
    }
  end

  connection :responses, -> { AnnotationType.connection_type }
end
