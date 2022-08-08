namespace :check do
  namespace :migrate do
    task index_annotated_by: :environment do
      started = Time.now.to_i
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      last_team_id = Rails.cache.read('check:migrate:index_annotated_by:team_id') || 0
      Team.where('id > ?', last_team_id).find_each do |team|
        team.project_medias.find_in_batches(:batch_size => 2500) do |pms|
          ids = pms.map(&:id)
          Annotation.where(annotation_type: 'task', annotated_type: 'ProjectMedia', annotated_id: ids)
          .find_in_batches(:batch_size => 2500) do |tasks|
            es_body = []
            # cache annotated_by value
            annotated_ids = tasks.map(&:annotated_id)
            ProjectMedia.where(id: annotated_ids).find_each do |pm|
              print '.'
              annotated_by = pm.annotated_by
              doc_id = Base64.encode64("ProjectMedia/#{pm.id}")
              fields = { 'annotated_by' => annotated_by }
              es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
            end
            client.bulk body: es_body unless es_body.blank?
          end
        end
        Rails.cache.write('check:migrate:index_annotated_by:team_id', team.id)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end