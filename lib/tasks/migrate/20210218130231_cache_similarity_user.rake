namespace :check do
  namespace :migrate do
    task cache_similarity_user: :environment do
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil
      started = Time.now.to_i
      errors = 0
      conditions = ['r.relationship_type = ?', Relationship.confirmed_type.to_yaml]
      joins = 'INNER JOIN relationships r ON r.target_id = project_medias.id'
      total = ProjectMedia.joins(joins).where(conditions).count
      i = 0
      ProjectMedia.where(conditions).joins(joins).find_in_batches(batch_size: 3000) do |pms|
        i += 1
        puts "#{i * 3000} / #{total}"
        pms.each do |pm|
          begin
            # Just calling the methods is enough to cache the value
            puts "Confirmed by: #{pm.confirmed_as_similar_by_name}"
            puts "Added by: #{pm.added_as_similar_by_name}"
          rescue
            errors += 1
          end
        end
        puts "[#{Time.now}] Done for batch ##{i}"
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes. Errors: #{errors}"
      ActiveRecord::Base.logger = old_logger
    end
  end
end
