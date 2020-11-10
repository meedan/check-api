namespace :check do
  namespace :migrate do
    # migrate analysis_title & analysis_description fields
    task migrate_keyword_fields: :environment do
      started = Time.now.to_i
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      last_pm_id = Rails.cache.read('check:migrate:migrate_keyword_fields:project_media_id') || 0
      pmps_all = ProjectMedia.where('id > ?', last_pm_id).count
      total = (pmps_all/2500.to_f).ceil
      progressbar = ProgressBar.create(:total => total)
      ProjectMedia.where('id > ?', last_pm_id).find_in_batches(:batch_size => 2500) do |project_medias|
        progressbar.increment
        pm_ids = project_medias.map(&:id)
        es_body = []
        DynamicAnnotation::Field.select("dynamic_annotation_fields.*, annotations.annotated_id as pm_id")
        .where(field_name: ['title', 'content'])
        .joins("INNER JOIN annotations ON dynamic_annotation_fields.annotation_id = annotations.id
          AND annotations.annotation_type = 'verification_status'"
          )
        .where('annotations.annotated_type': 'ProjectMedia', 'annotations.annotated_id': pm_ids)
        .find_in_batches(:batch_size => 2500) do |fields|
          fields.each do |field|
            doc_id = Base64.encode64("ProjectMedia/#{field.pm_id}")
            es_field = field.field_name == 'title' ? 'analysis_title' : 'analysis_description'
            fields = { es_field => field.value }
            es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
          end
        end
        client.bulk body: es_body unless es_body.blank?
        # log last project media id
        Rails.cache.write("check:migrate:migrate_keyword_fields:project_media_id", pm_ids.max)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
    # migrate task_comments field
    task migrate_task_comments: :environment do
      started = Time.now.to_i
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      last_pm_id = Rails.cache.read('check:migrate:migrate_task_comments:project_media_id') || 0
      pmps_all = ProjectMedia.where('id > ?', last_pm_id).count
      total = (pmps_all/2500.to_f).ceil
      progressbar = ProgressBar.create(:total => total)
      ProjectMedia.where('id > ?', last_pm_id).find_in_batches(:batch_size => 2500) do |project_medias|
        progressbar.increment
        pm_ids = project_medias.map(&:id)
        pm_tasks_comments = {}
        # collect tasks with answers [single/multiple] choices
        Comment.where('annotations.annotation_type': 'comment', 'annotations.annotated_type': 'Task')
        .joins("INNER JOIN annotations tasks ON annotations.annotated_id = tasks.id")
        .where('tasks.annotated_type': 'ProjectMedia', 'tasks.annotated_id': pm_ids)
        .find_in_batches(:batch_size => 2500) do |comments|
          task_ids = comments.map(&:annotated_id)
          task_info = {}
          Annotation.where(id: task_ids).find_each do |t|
            task_info[t.id] = { pm: t.annotated_id, team_task_id: t.team_task_id }
          end
          comments.each do |comment|
            data = { id: comment.id, text: comment.text }
            data[:team_task_id] = task_info[comment.annotated_id][:team_task_id] unless task_info[comment.annotated_id][:team_task_id].nil?
            pmid = task_info[comment.annotated_id][:pm]
            if pm_tasks_comments[pmid].nil?
              pm_tasks_comments[pmid] = [data]
            else
              pm_tasks_comments[pmid] << data
            end
          end
        end
        # loop pm_tasks_comments for bulk update
        es_body = []
        pm_tasks_comments.each do |k, v|
          doc_id = Base64.encode64("ProjectMedia/#{k}")
          fields = { 'task_comments' => v }
          es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
        end
        client.bulk body: es_body unless es_body.blank?
        # log last project media id
        Rails.cache.write('check:migrate:migrate_task_comments:project_media_id', pm_ids.max)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
