namespace :check do
  namespace :migrate do
   desc "Delete medias not associated with any project media"
   task delete_orphaned_medias: :environment do
     started = Time.now.to_i
     sql_count = "SELECT COUNT(*) FROM medias m WHERE NOT EXISTS (SELECT 1 FROM project_medias pm WHERE m.id = pm.media_id)"
     count = ActiveRecord::Base.connection.execute(sql_count)[0]['count']

     sql_delete = "DELETE FROM medias m WHERE NOT EXISTS (SELECT 1 FROM project_medias pm WHERE m.id = pm.media_id)"
     ActiveRecord::Base.connection.execute(sql_delete)

     minutes = (Time.now.to_i - started) / 60
     puts "[#{Time.now}] Done in #{minutes} minutes."
     puts "Deleted #{count} orphans medias"
    end
  end
end
