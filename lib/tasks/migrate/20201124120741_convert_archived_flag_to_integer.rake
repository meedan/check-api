namespace :check do
  namespace :migrate do
    task update_archived_logs: :environment do
      started = Time.now.to_i
      minutes = ((Time.now.to_i - started) / 60).to_i
      Team.find_each do |team|
        # update archived logs with 1/0 insted of true/false
        Version.from_partition(team.id).where("object_changes = ?", '{"archived":[true,false]}').find_in_batches(:batch_size => 2500) do |versions|
          print '.'
          ids = versions.map(&:id)
          Version.from_partition(team.id).where(id: ids).update_all(object_changes: "{\"archived\":[1,0]}")
        end
        # update archived logs with 0/1 insted of false/true
        Version.from_partition(team.id).where("object_changes = ?", '{"archived":[false,true]}').find_in_batches(:batch_size => 2500) do |versions|
          print '.'
          ids = versions.map(&:id)
          Version.from_partition(team.id).where(id: ids).update_all(object_changes: "{\"archived\":[0,1]}")
        end
      end
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
