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
          annotated_by_mapping = Hash.new {|hash, key| hash[key] = [] }
          Annotation.select('annotations.annotated_id as pm_id, a2.*')
          .where(annotation_type: 'task', annotated_type: 'ProjectMedia', annotated_id: ids)
          .joins("INNER JOIN annotations a2 on annotations.id = a2.annotated_id")
          .where("a2.annotation_type LIKE ?", 'task_response_%').find_each do |r|
            print '.'
            annotated_by_mapping[r['pm_id']] << r['annotator_id']
          end
          es_body = []
          annotated_by_mapping.each do |pm_id, uids|
            print '.'
            doc_id = Base64.encode64("ProjectMedia/#{pm_id}")
            fields = { 'annotated_by' => uids }
            es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
          end
          client.bulk body: es_body unless es_body.blank?
        end
        Rails.cache.write('check:migrate:index_annotated_by:team_id', team.id)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end