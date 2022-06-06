namespace :check do
  namespace :migrate do
    task update_medias_count_cache: :environment do
      started = Time.now.to_i
      n = Project.count
      i = 0
      Project.find_each do |p|
        i += 1
        puts "[#{Time.now}] [#{i}/#{n}] Updating medias_count (#{p.medias_count(true)}) for project ##{p.id}..."
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
