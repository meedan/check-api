# bundle exec rake check:migrate:reindex_explainers

namespace :check do
  namespace :migrate do
    desc 'Reindex all explainers'
    task reindex_explainers: :environment do
      cache_key = 'check:migrate:reindex_explainers:last_migrated_id'
      last_migrated_id = Rails.cache.read(cache_key).to_i

      puts "[#{Time.now}] Starting reindex of all explainers"

      Explainer.where('id > ?', last_migrated_id).order('id ASC').find_each(batch_size: 100) do |explainer|
        begin
          Explainer.update_paragraphs_in_alegre(explainer.id, 0, Time.now.to_f)
          Rails.cache.write(cache_key, explainer.id)
          puts "[#{Time.now}] Successfully reindexed explainer with ID #{explainer.id}"
        rescue StandardError => e
          Rails.logger.error "[#{Time.now}] Error reindexing explainer with ID #{explainer.id}: #{e.message}"
        end
      end

      Rails.cache.delete(cache_key)
      puts "[#{Time.now}] Successfully reindexed all explainers"
    end
  end
end
