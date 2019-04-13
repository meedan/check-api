namespace :check do
  namespace :migrate do
    task add_smooch_annotations_index: :environment do
      # Read the last annotation id we need to process that was set at migration time.
      last_id = Rails.cache.read('check:migrate:add_smooch_annotations_index:last_id')
      raise "No last_id found in cache for check:migrate:add_smooch_annotations_index! Aborting." if last_id.nil?

      # Loop on each annotation to invoke its ES indexing.
      # Using Sidekiq::Testing.inline! to force running jobs on foreground.
      require 'sidekiq/testing'
      Sidekiq::Testing.inline! do
        rel = Dynamic.where(annotation_type: 'smooch').where('id <= ?', last_id).order(:id)
        n = rel.count
        i = 0
        rel.find_each do |d|
          i += 1
          puts "[#{Time.now}] (#{i}/#{n}) Indexing Smooch annotation #{d.id}"
          d.send(:add_elasticsearch_dynamic)
        end
      end
    end
  end
end
