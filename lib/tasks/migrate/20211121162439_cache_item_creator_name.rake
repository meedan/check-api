namespace :check do
  namespace :migrate do
    task cache_item_creator_name: :environment do
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil
      client = $repository.client
      index_alias = CheckElasticSearchModel.get_index_alias
      started = Time.now.to_i
      errors = 0
      # Get latest team id
      last_team_id = Rails.cache.read('check:migrate:cache_item_creator_name:team_id') || 0
      Team.where('id > ?', last_team_id).find_each do |team|
        team.project_medias.find_in_batches(batch_size: 3000) do |pms|
          es_body = []
          pms.each do |pm|
            print '.'
            begin
              # Just calling the method is enough to cache the value
              pm.creator_name
            rescue
              errors += 1
            end
            doc_id = Base64.encode64("ProjectMedia/#{pm.id}")
            data = { creator_name: pm.creator_name }
            es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: data } } }
          end
          client.bulk body: es_body unless es_body.blank?
        end
        # log last team id
        puts "[#{Time.now}] Done for team #{team.slug}"
        Rails.cache.write('check:migrate:cache_item_creator_name:team_id', team.id)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes. Errors: #{errors}"
      ActiveRecord::Base.logger = old_logger
    end
  end
end
