namespace :check do
  namespace :migrate do
    # bundle exec rails check:migrate:recalculate_project_media_cached_field[field]
    task recalculate_project_media_cached_field: :environment do |_t, args|
      started = Time.now.to_i
      field_name = args.extras.last
      raise "You must set field name as args for rake task Aborting." if field_name.blank?
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      last_team_id = Rails.cache.read('check:migrate:recalculate_project_media_cached_field:team_id') || 0
      Team.where('id > ?', last_team_id).find_each do |team|
        team.project_medias.find_in_batches(:batch_size => 2500) do |pms|
          es_body = []
          pms.each do |pm|
            print '.'
            value = pm.send(field_name, true)
            doc_id = Base64.encode64("ProjectMedia/#{pm.id}")
            fields = { "#{field_name}" => value }
            es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
          end
          client.bulk body: es_body unless es_body.blank?
        end
        Rails.cache.write('check:migrate:recalculate_project_media_cached_field:team_id', team.id)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end