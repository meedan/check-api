TaskType = GraphqlCrudOperations.define_annotation_type('task', { label: 'str', type: 'str', description: 'str', json_schema: 'str' }) do
  description 'Annotation representing a request for work on an item.'

  # TODO Merge this and 'first_response_value' into 'answer'
  field :first_response, AnnotationType do
    resolve -> (task, _args, _ctx) {
      obj = task.load || task
      obj.nil? ? nil : obj.first_response_obj
    }
  end

  field :first_response_value, types.String do
    resolve -> (task, _args, _ctx) {
      obj = task.load || task
      obj.nil? ? "" : obj.first_response
    }
  end

  # TODO Merge 'options' and 'jsonoptions'
  field :jsonoptions, types.String do
    resolve -> (task, _args, _ctx) {
      obj = task.load || task
      obj.jsonoptions unless obj.nil?
    }
  end

  field :options, JsonStringType do
    resolve -> (task, _args, _ctx) {
      obj = task.load || task
      obj.options unless obj.nil?
    }
  end

  field :project_media, ProjectMediaType do
    resolve -> (task, _args, _ctx) {
      obj = task.load || task
      obj.annotated if !obj.nil? && obj.annotated_type == 'ProjectMedia'
    }
  end

  field :team_task_id, types.Int, 'Team task database id'

  field :log_count, types.Int, 'Count of log entries for this item' do
    resolve -> (task, _args, _ctx) {
      obj = task.load || task
      obj.nil? ? 0 : (obj.log_count || 0)
    }
  end

  field :suggestions_count, types.Int
  field :pending_suggestions_count, types.Int

  connection :log, -> { VersionType.connection_type }, 'Log entries for this item' do
    resolve ->(task, _args, _ctx) {
      obj = task.load || task
      obj.log unless obj.nil?
    }
  end

  connection :responses, -> { AnnotationType.connection_type }
end
