namespace :check do
  namespace :migrate do
    task migrate_task_responses: :environment do
      started = Time.now.to_i
      failed_items = []
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      # Get latest team id
      last_team_id = Rails.cache.read('check:migrate:migrate_task_responses:team_id') || 0
      teams_count = Team.where('id > ?', last_team_id).count
      progressbar = ProgressBar.create(:total => teams_count)
      Team.where('id > ?', last_team_id).find_each do |team|
        progressbar.increment
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
            print '.'
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
                begin
                  client.update index: index_alias, id: doc_id, retry_on_conflict: 3,
                          body: { script: { source: source, params: { value: data } } }
                rescue Exception => e
                  failed_items << {error: e, obj_id: pm_task[field.task_id][:pm], task_id: field.task_id}
                end
              end
            end
          end
        end
        # log last team id
        Rails.cache.write('check:migrate:migrate_task_responses:team_id', team.id)
      end
      if failed_items.size > 0
        pp failed_items
        puts "Failed to index #{failed_items.size} items"
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
