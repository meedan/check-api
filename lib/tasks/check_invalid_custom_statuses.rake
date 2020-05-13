namespace :check do
  # bundle exec rake check:get_invalid_custom_statuses
  # will return a list with team_id, team_name status and Medias URLs
  desc "Find the current list of custom statuses that no longer exist in their team's settings"
  task get_invalid_custom_statuses: :environment do
    teams = []
    Team.find_each do |t|
      media_statuses = t.get_media_verification_statuses
      unless media_statuses.blank?
        list = Workflow::Workflow.validate_custom_statuses(t.id, media_statuses)[:list]
        unless list.blank?
          urls = list.collect{|l| l[:url]}
          statuses = list.collect{|l| l[:status]}.uniq
          teams << {team_id: t.id, team_name: t.name, status: statuses, urls: urls}
        end
      end
      print '.'
    end
    unless teams.blank?
      filename = "#{Time.now.to_i}_invalid_custom_statuses"
      puts "\n#{teams.count} teams contains custom statuses that no longer exists - all data were saved on #{filename}"
      File.open(filename, "w+") do |f|
        f.puts(teams)
      end
    end
  end
end
