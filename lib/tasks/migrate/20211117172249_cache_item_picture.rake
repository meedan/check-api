namespace :check do
  namespace :migrate do
    task cache_item_picture: :environment do
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil
      started = Time.now.to_i
      query = ProjectMedia.joins(:media).where('medias.type NOT IN (?)', ['Blank', 'Claim'])
      total = query.count
      errors = 0
      i = 0
      query.find_in_batches(batch_size: 3000) do |pms|
        i += 1
        puts "#{i * 3000} / #{total}"
        pms.each do |pm|
          begin
            # Just calling the method is enough to cache the value
            pm.picture
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
