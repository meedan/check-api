# bundle exec rake check:migrate:update_main_feed_feed_team

namespace :check do
  namespace :migrate do
    desc 'Update shared feed main feed\'s feed_team'
    task update_main_feed_feed_team: :environment do
      ActiveRecord::Base.logger = nil

      puts "[#{Time.now}] Starting to update main shared feed feed_team"
      started = Time.now.to_i

      # Find all main feeds
      Feed.find_each do |feed|
        feed.send(:update_feed_team)
        puts "[#{Time.now}] Updated feed_team for feed ID: #{feed.id}, Team ID: #{feed.team_id}."
      end

      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
