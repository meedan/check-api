namespace :check do
  namespace :migrate do
    task migrate_task_responses: :environment do
      started = Time.now.to_i
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      # Get latest team id
      last_team_id = Rails.cache.read('check:migrate:migrate_task_responses:team_id') || 0
      teams_count = Team.where('id > ?', last_team_id).count
      progressbar = ProgressBar.create(:total => teams_count)
      Team.where('id > ?', last_team_id).find_each do |team|
        progressbar.increment
        # get team tasks
        requires_types = ['single_choice', 'multiple_choice','geolocation', 'datetime', 'file_upload']
        tt_ids = TeamTask.where(team_id: team.id, task_type: requires_types).map(&:id)
        last_pm_id = Rails.cache.read("check:migrate:migrate_task_responses:#{team.id}:project_media_id") || 0
        ProjectMedia.where(team_id: team.id).where('id > ?', last_pm_id).find_in_batches(:batch_size => 2500) do |project_medias|
          pm_ids = project_medias.map(&:id)
          project_medias_tasks = {}
          # collect tasks with answers [single/multiple] choices
          Task.where('annotations.annotation_type': 'task', 'annotations.annotated_type': 'ProjectMedia', 'annotations.annotated_id': pm_ids)
          .where('task_team_task_id(annotations.annotation_type, annotations.data) IN (?)', tt_ids)
          .joins("INNER JOIN annotations responses ON responses.annotation_type LIKE 'task_response%'
              AND responses.annotated_type = 'Task'
              AND responses.annotated_id = annotations.id"
              )
          .find_in_batches(:batch_size => 2500) do |tasks|
            tasks_ids = tasks.map(&:id)
            pm_task = {}
            tasks.each{ |t| pm_task[t.id] = { pm: t.annotated_id, team_task_id: t.team_task_id, fieldset: t.fieldset } }
            DynamicAnnotation::Field.select("dynamic_annotation_fields.*, annotations.annotated_id as task_id")
            .joins('INNER JOIN annotations ON dynamic_annotation_fields.annotation_id = annotations.id')
            .where('annotations.annotated_type' => 'Task', 'annotations.annotated_id' => tasks_ids)
            .find_in_batches(:batch_size => 2500) do |fields|
              fields.each do |field|
                if field.field_name =~ /choice/
                  value = field.selected_values_from_task_answer
                else
                  value = field.to_s
                end
                data = { id: field.task_id, value: value, field_type: field.field_type , team_task_id: pm_task[field.task_id][:team_task_id], fieldset: pm_task[field.task_id][:fieldset]}
                if project_medias_tasks[pm_task[field.task_id][:pm]].nil?
                  project_medias_tasks[pm_task[field.task_id][:pm]] = [data]
                else
                  project_medias_tasks[pm_task[field.task_id][:pm]] << data
                end
              end
            end
          end
          # collect tasks with zero answer [single/multiple] choices
          Task.where('annotations.annotation_type': 'task', 'annotations.annotated_type': 'ProjectMedia', 'annotations.annotated_id': pm_ids)
          .where('task_team_task_id(annotations.annotation_type, annotations.data) IN (?)', tt_ids)
          .joins("LEFT JOIN annotations responses ON responses.annotation_type LIKE 'task_response%'
              AND responses.annotated_type = 'Task'
              AND responses.annotated_id = annotations.id"
              )
          .where('responses.id' => nil)
          .find_in_batches(:batch_size => 2500) do |tasks|
            tasks.each do |task|
              data = { id: task.id, team_task_id: task.team_task_id, fieldset: task.fieldset }
              if project_medias_tasks[task.annotated_id].nil?
                project_medias_tasks[task.annotated_id] = [data]
              else
                project_medias_tasks[task.annotated_id] << data
              end
            end
          end
          # collect free text tasks (team tasks and created tasks) with answers
          Task.where('annotations.annotation_type': 'task', 'annotations.annotated_type': 'ProjectMedia', 'annotations.annotated_id': pm_ids)
          .joins("INNER JOIN annotations responses ON responses.annotation_type LIKE 'task_response_free_text%'
              AND responses.annotated_type = 'Task'
              AND responses.annotated_id = annotations.id"
              )
          .find_in_batches(:batch_size => 2500) do |tasks|
            tasks_ids = tasks.map(&:id)
            pm_task = {}
            tasks.each{ |t| pm_task[t.id] = { pm: t.annotated_id, team_task_id: t.team_task_id, fieldset: t.fieldset } }
            DynamicAnnotation::Field.select("dynamic_annotation_fields.*, annotations.annotated_id as task_id")
            .joins('INNER JOIN annotations ON dynamic_annotation_fields.annotation_id = annotations.id')
            .where('annotations.annotated_type' => 'Task', 'annotations.annotated_id' => tasks_ids)
            .find_in_batches(:batch_size => 2500) do |fields|
              fields.each do |field|
                value = [field.value]
                data = { id: field.task_id, value: value, field_type: field.field_type , fieldset: pm_task[field.task_id][:fieldset]}
                data[:team_task_id] = pm_task[field.task_id][:team_task_id] unless pm_task[field.task_id][:team_task_id].nil?
                if project_medias_tasks[pm_task[field.task_id][:pm]].nil?
                  project_medias_tasks[pm_task[field.task_id][:pm]] = [data]
                else
                  project_medias_tasks[pm_task[field.task_id][:pm]] << data
                end
              end
            end
          end
          # loop project_medias_tasks for bulk update
          es_body = []
          project_medias_tasks.each do |k, v|
            doc_id = Base64.encode64("ProjectMedia/#{k}")
            fields = { 'task_responses' => v }
            es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
          end
          client.bulk body: es_body unless es_body.blank?
          # log last project media id
          Rails.cache.write("check:migrate:migrate_task_responses:#{team.id}:project_media_id", pm_ids.max)
        end
        # log last team id
        Rails.cache.write('check:migrate:migrate_task_responses:team_id', team.id)
      end

      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
