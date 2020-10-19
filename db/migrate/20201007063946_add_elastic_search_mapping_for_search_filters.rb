class AddElasticSearchMappingForSearchFilters < ActiveRecord::Migration
  def change
    started = Time.now.to_i
    index_alias = CheckElasticSearchModel.get_index_alias
    client = $repository.client
    options = {
      index: index_alias,
      body: {
          properties: {
            task_responses: {
              type: 'nested',
              properties: {
                id: { type: 'integer'},
                team_task_id: { type: 'integer'},
                value: { type: 'text', analyzer: 'check', fields: { raw: { type: 'text', analyzer: 'keyword' } } }
              }
            }
          }
      }
    }
    client.indices.put_mapping options
    # Intial team tasks with []
    ProjectMedia.find_in_batches(:batch_size => 2500) do |pms|
      ids = pms.map(&:id)
      body = {
        script: { source: "ctx._source.task_responses = params.task_responses", params: { task_responses: [] } },
        query: { terms: { annotated_id: ids } }
      }
      options[:body] = body
      client.update_by_query options
    end
    # migrate existing data
    Team.find_each do |team|
      # get team tasks
      TeamTask.where(team_id: team.id, task_type: ["free_text", "single_choice", "multiple_choice"])
      .find_in_batches(:batch_size => 2500) do |team_tasks|
        tt_ids = team_tasks.map(&:id)
        Task.where('annotations.annotation_type' => 'task')
        .where('task_team_task_id(annotations.annotation_type, annotations.data) IN (?)', tt_ids)
        .joins("INNER JOIN annotations responses ON responses.annotation_type LIKE 'task_response%'
            AND responses.annotated_type = 'Task'
            AND responses.annotated_id = annotations.id"
            )
        .find_in_batches(:batch_size => 2500) do |tasks|
          tasks_ids = tasks.map(&:id)
          pm_task = {}
          tasks.each{ |t| pm_task[t.id] = { pm: t.annotated_id, team_task_id: t.team_task_id } }
          DynamicAnnotation::Field.select("dynamic_annotation_fields.*, annotations.annotated_id as task_id")
          .joins('INNER JOIN annotations ON dynamic_annotation_fields.annotation_id = annotations.id')
          .where('annotations.annotated_type' => 'Task', 'annotations.annotated_id' => tasks_ids)
          .find_in_batches(:batch_size => 2500) do |fields|
            fields.each do |field|
              if field.field_name =~ /choice/
                value = field.selected_values_from_task_answer
              else
                value = [field.value]
              end
              data = { id: field.annotation_id, value: value , team_task_id: pm_task[field.task_id][:team_task_id] }
              doc_id = Base64.encode64("ProjectMedia/#{pm_task[field.task_id][:pm]}")
              source = "ctx._source.task_responses.add(params.value)"
              client.update index: index_alias, id: doc_id, retry_on_conflict: 3,
                      body: { script: { source: source, params: { value: data } } }
            end
          end
        end
      end
    end
    minutes = ((Time.now.to_i - started) / 60).to_i
    puts "[#{Time.now}] Done in #{minutes} minutes."
  end
end
