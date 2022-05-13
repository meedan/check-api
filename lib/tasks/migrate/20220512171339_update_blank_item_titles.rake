namespace :check do
  namespace :migrate do
    task update_blank_item_titles: :environment do
      started = Time.now.to_i
      n = ProjectMedia.count
      i = 0
      ProjectMedia.order('id ASC').find_each do |pm|
        i += 1
        title = pm.title
        if title.blank? || title == '-' || title == '​'
          pm.title(true)
          puts "[#{Time.now}] [#{i}/#{n}] Updated title"
        else
          puts "[#{Time.now}] [#{i}/#{n}] Title not blank, no need to update"
        end
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
