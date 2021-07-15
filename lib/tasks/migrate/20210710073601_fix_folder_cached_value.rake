namespace :check do
  namespace :migrate do
    task fix_folder_cached_value: :environment do
      started = Time.now.to_i
      ProjectMedia.select('project_medias.id, p.title as p_title')
      .joins("INNER JOIN projects p on p.id = project_medias.project_id")
      .find_in_batches(batch_size: 2500) do |pms|
        pms.each do |pm|
          print '.'
          Rails.cache.write("check_cached_field:ProjectMedia:#{pm.id}:folder", pm.p_title)
        end
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
