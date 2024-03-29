namespace :check do
  namespace :migrate do
    task index_report_published_by: :environment do
      started = Time.now.to_i
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      last_team_id = Rails.cache.read('check:migrate:index_report_published_by:team_id') || 0
      Team.where('id > ?', last_team_id).find_each do |team|
        team.project_medias.find_in_batches(:batch_size => 2500) do |pms|
          es_body = []
          ids = pms.map(&:id)
          Dynamic.where(annotated_id: ids, annotated_type: 'ProjectMedia', annotation_type: 'report_design')
          .where('data LIKE ?', '%state: published%')
          .find_in_batches(:batch_size => 2500) do |annotations|
            # cache published_by value
            annotated_ids = annotations.map(&:annotated_id)
            ProjectMedia.where(id: annotated_ids).find_each do |pm|
              print '.'
              pm.published_by
            end
            print '.'
            annotations.each do |d|
              doc_id = Base64.encode64("ProjectMedia/#{d.annotated_id}")
              fields = { 'published_by' => d.annotator_id }
              es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
            end
          end
          client.bulk body: es_body unless es_body.blank?
        end
        Rails.cache.write('check:migrate:index_report_published_by:team_id', team.id)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end