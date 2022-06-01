namespace :check do
  namespace :migrate do
    task cache_is_suggested_and_is_confirmed: :environment do
      started = Time.now.to_i
      rel = Relationship.where('relationship_type = ? OR relationship_type = ?', Relationship.confirmed_type.to_yaml, Relationship.suggested_type.to_yaml).where('id <= ?', Relationship.last.id)
      n = rel.count
      i = 0
      rel.find_each do |r|
        i += 1
        pm = r.target
        puts "[#{Time.now}] [#{i}/#{n}] Updating is_suggested (#{pm.is_suggested(true)}) and is_confirmed (#{pm.is_confirmed(true)}) for item ##{pm.id}..."
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
