namespace :check do
  namespace :migrate do
    task reindex_relationships: :environment do
      LAST = 0
      RequestStore.store[:skip_notifications] = true
      RequestStore.store[:skip_rules] = true
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil
      started = Time.now.to_i
      errors = 0
     
      total = Relationship.where('id > ?', LAST).count
      i = 0
      Relationship.where('id > ?', LAST).order('id ASC').find_each do |relationship|
        i += 1
        print "Updating relationship #{i}/#{total} (ID #{relationship.id})... "
        relationship.updated_at = Time.now
        begin
          relationship.save!
          puts "Updated ID #{relationship.id}!"
        rescue Exception => e
          puts "Error: #{e.message}"
        end
      end
      
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes. Errors: #{errors}"
      ActiveRecord::Base.logger = old_logger
      RequestStore.store[:skip_notifications] = false
      RequestStore.store[:skip_rules] = false
    end
  end
end
