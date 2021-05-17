namespace :check do
  namespace :migrate do
    task add_last_seen_to_project_media: :environment do
      started = Time.now.to_i
      total = (ProjectMedia.count/2500.to_f).ceil
      progressbar = ProgressBar.create(:title => "Update last_seen", :total => total)
      ProjectMedia.find_in_batches(:batch_size => 2500) do |pms|
        progressbar.increment
        pms.each{ |pm| pm.update_column(:last_seen, pm.last_seen)}
      end
      minutes = (Time.now.to_i - started) / 60
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
