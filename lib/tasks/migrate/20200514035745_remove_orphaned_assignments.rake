namespace :check do
  namespace :migrate do
    task remove_orphaned_assignments: :environment do
      last_id = Rails.cache.read('check:migrate:remove_orphaned_assignments')
      raise "No last_id found in cache for check:migrate:remove_orphaned_assignments! Aborting." if last_id.nil?
      sql_count = "SELECT COUNT(*) FROM assignments a WHERE a.assigned_type = 'Annotation' AND NOT EXISTS (SELECT 1 FROM annotations a2 WHERE a2.id = a.assigned_id)"
      sql_delete = "DELETE FROM assignments a WHERE a.assigned_type = 'Annotation' AND NOT EXISTS (SELECT 1 FROM annotations a2 WHERE a2.id = a.assigned_id)"
      count = ActiveRecord::Base.connection.execute(sql_count)[0]['count']
      puts "[#{Time.now}] There are #{Assignment.count} assignments in total, from which #{count} are orphans and will be removed."
      ActiveRecord::Base.connection.execute(sql_delete)
      puts "[#{Time.now}] Now there are #{Assignment.count} assignments in total."
      Rails.cache.delete('check:migrate:remove_orphaned_assignments')
    end
  end
end
